#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "config.h"
#include "speeduino_serial.h"
#include "ble_server.h"

static SpeeduinoData g_data;
static float         g_oil_press_bar = 0.0f;
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

// Task no Core 0: lê dados do Speeduino via UART e pressão de óleo a cada 50ms
void task_serial_read(void *param) {
    TickType_t last_wake = xTaskGetTickCount();
    for (;;) {
        SpeeduinoData local;
        bool ok = speeduino_request_realtime(local);
        float oil = read_oil_pressure();

        if (ok) {
            xSemaphoreTake(g_data_mutex, portMAX_DELAY);
            g_data         = local;
            g_oil_press_bar = oil;
            xSemaphoreGive(g_data_mutex);
        } else {
            Serial.println("[UART] Timeout Speeduino");
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(SERIAL_POLL_MS));
    }
}

// Task no Core 1: notifica o app BLE a cada 50ms com os dados mais recentes
void task_ble_notify(void *param) {
    TickType_t last_wake = xTaskGetTickCount();
    for (;;) {
        if (ble_is_connected()) {
            SpeeduinoData local;
            float oil;
            xSemaphoreTake(g_data_mutex, portMAX_DELAY);
            local = g_data;
            oil   = g_oil_press_bar;
            xSemaphoreGive(g_data_mutex);

            ble_notify_realtime(local, oil);
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(BLE_NOTIFY_MS));
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("\n[BOOT] BMW F650GS ECU Bridge v1.0");

    g_data_mutex = xSemaphoreCreateMutex();
    memset(&g_data, 0, sizeof(g_data));

    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);  // 0–3,3V no ADC
    pinMode(OIL_PRESS_ADC_PIN, INPUT);

    speeduino_init();
    ble_init();

    // Core 0: comunicação serial com Speeduino (mesmo core do protocolo WiFi/BT basal)
    xTaskCreatePinnedToCore(task_serial_read, "serial_read", 4096, nullptr, 5, nullptr, 0);

    // Core 1: notificações BLE (app side)
    xTaskCreatePinnedToCore(task_ble_notify, "ble_notify",  4096, nullptr, 4, nullptr, 1);

    Serial.println("[BOOT] Tasks iniciadas");
}

void loop() {
    // Loop principal livre — tasks gerenciam o trabalho
    delay(5000);
    Serial.printf("[STATUS] RPM=%u CLT=%d°C AFR=%.1f OIL=%.1fbar KNOCK=%d° BLE=%s\n",
        g_data.rpm,
        (int)g_data.temp_clt - 40,
        g_data.o2_primary / 10.0f,
        g_oil_press_bar,
        g_data.knock_ret,
        ble_is_connected() ? "OK" : "aguardando"
    );
}
