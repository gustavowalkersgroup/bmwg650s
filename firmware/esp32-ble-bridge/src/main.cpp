#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "config.h"
#include "speeduino_serial.h"
#include "ble_server.h"
#include "imu_sensor.h"
#include "fuel_tracker.h"
#include "cold_start.h"

static SpeeduinoData   g_data;
static float           g_oil_press_bar = 0.0f;
static ImuData         g_imu;
static FuelState       g_fuel;
static ColdStartState  g_cold;
static SemaphoreHandle_t g_data_mutex;

// Lê pressão de óleo do ADC do ESP32 com média de N amostras
static float read_oil_pressure() {
    uint32_t sum = 0;
    for (int i = 0; i < OIL_PRESS_ADC_SAMPLES; i++) {
        sum += analogRead(OIL_PRESS_ADC_PIN);
        delayMicroseconds(200);
    }
    float adc_v = (sum / OIL_PRESS_ADC_SAMPLES) * (3.3f / 4095.0f);
    // Lineariza: V_min → 0 bar, V_max → OIL_PRESS_BAR_MAX
    float bar = (adc_v - OIL_PRESS_V_MIN) / (OIL_PRESS_V_MAX - OIL_PRESS_V_MIN) * OIL_PRESS_BAR_MAX;
    return constrain(bar, 0.0f, OIL_PRESS_BAR_MAX);
}

// Corta a bomba de combustível ao detectar queda (segurança anti-incêndio)
static void apply_fuel_cut(bool crash) {
#if FUEL_CUT_ON_CRASH
    digitalWrite(FUEL_PUMP_KILL_PIN, crash ? FUEL_PUMP_KILL_LEVEL : !FUEL_PUMP_KILL_LEVEL);
#endif
}

// Task no Core 0: lê dados do Speeduino via UART, pressão de óleo e combustível
void task_serial_read(void *param) {
    TickType_t last_wake = xTaskGetTickCount();
    for (;;) {
        SpeeduinoData local;
        bool ok = speeduino_request_realtime(local);
        float oil = read_oil_pressure();

        if (ok) {
            float pw_ms = local.pw1_ms10 / 10.0f;
            fuel_update(pw_ms, local.rpm, local.vss, SERIAL_POLL_MS);
            FuelState fuel = fuel_get();

            int clt_c = (int)local.temp_clt - 40;
            cold_start_update(clt_c, local.flex_sensor, local.rpm, SERIAL_POLL_MS);
            ColdStartState cold = cold_start_get();

            xSemaphoreTake(g_data_mutex, portMAX_DELAY);
            g_data          = local;
            g_oil_press_bar = oil;
            g_fuel          = fuel;
            g_cold          = cold;
            xSemaphoreGive(g_data_mutex);
        } else {
            Serial.println("[UART] Timeout Speeduino");
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(SERIAL_POLL_MS));
    }
}

// Task no Core 1: IMU (50Hz) + notificação BLE (20Hz)
void task_imu_ble(void *param) {
    TickType_t last_wake = xTaskGetTickCount();
    uint32_t   ble_accum = 0;
    for (;;) {
        // IMU a cada ciclo (IMU_UPDATE_MS)
        imu_update(IMU_UPDATE_MS);
        ImuData imu = imu_get();
        apply_fuel_cut(imu.crash);

        xSemaphoreTake(g_data_mutex, portMAX_DELAY);
        g_imu = imu;
        xSemaphoreGive(g_data_mutex);

        // BLE notify a cada BLE_NOTIFY_MS (subconjunto dos ciclos do IMU)
        ble_accum += IMU_UPDATE_MS;
        if (ble_accum >= BLE_NOTIFY_MS && ble_is_connected()) {
            ble_accum = 0;
            SpeeduinoData local;
            float oil;
            FuelState fuel;
            ColdStartState cold;
            xSemaphoreTake(g_data_mutex, portMAX_DELAY);
            local = g_data;
            oil   = g_oil_press_bar;
            fuel  = g_fuel;
            cold  = g_cold;
            xSemaphoreGive(g_data_mutex);

            ble_notify_realtime(local, oil, imu, fuel, cold);
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(IMU_UPDATE_MS));
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("\n[BOOT] BMW F650GS ECU Bridge v1.1");

    g_data_mutex = xSemaphoreCreateMutex();
    memset(&g_data, 0, sizeof(g_data));

    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);  // 0–3,3V no ADC
    pinMode(OIL_PRESS_ADC_PIN, INPUT);

#if FUEL_CUT_ON_CRASH
    pinMode(FUEL_PUMP_KILL_PIN, OUTPUT);
    digitalWrite(FUEL_PUMP_KILL_PIN, !FUEL_PUMP_KILL_LEVEL);  // bomba liberada
#endif

    speeduino_init();
    fuel_init();
    imu_init();
    cold_start_init();
    ble_init();

    // Core 0: comunicação serial com Speeduino (mesmo core do protocolo WiFi/BT basal)
    xTaskCreatePinnedToCore(task_serial_read, "serial_read", 4096, nullptr, 5, nullptr, 0);

    // Core 1: IMU + notificações BLE (app side)
    xTaskCreatePinnedToCore(task_imu_ble, "imu_ble", 4096, nullptr, 4, nullptr, 1);

    Serial.println("[BOOT] Tasks iniciadas");
}

void loop() {
    // Loop principal livre — tasks gerenciam o trabalho
    delay(5000);
    Serial.printf("[STATUS] RPM=%u CLT=%d AFR=%.1f OIL=%.1fbar FLEX=%d%% "
                  "LEAN=%.0f COMB=%d%% (%.1f km/l)%s%s%s\n",
        g_data.rpm,
        (int)g_data.temp_clt - 40,
        g_data.o2_primary / 10.0f,
        g_oil_press_bar,
        g_data.flex_sensor,
        g_imu.lean_deg,
        g_fuel.level_pct,
        g_fuel.econ_kmpl,
        g_fuel.low_fuel ? " [RESERVA]" : "",
        g_imu.crash ? " [QUEDA!]" : "",
        g_cold.heater_active ? " [AQUECENDO]" :
            (g_cold.too_cold_estart ? " [FRIO P/ ETANOL]" :
            (g_cold.engine_cold ? " [MOTOR FRIO]" : ""))
    );
}
