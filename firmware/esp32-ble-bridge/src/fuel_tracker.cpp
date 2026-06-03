#include "fuel_tracker.h"
#include "config.h"
#include <Arduino.h>
#include <Preferences.h>

static Preferences g_prefs;
static FuelState   g_fuel;
static uint32_t    g_since_save_ms = 0;

// cc por milissegundo de injeção a 100% de abertura
static constexpr float CC_PER_MS = FUEL_INJECTOR_CCMIN / 60000.0f;

static void persist() {
    g_prefs.putFloat("used", g_fuel.used_liters);
}

void fuel_init() {
#if FUEL_VIRTUAL_ENABLED
    pinMode(FUEL_RESERVE_SW_PIN, INPUT_PULLUP);

    g_prefs.begin("fuel", false);
    g_fuel.used_liters = g_prefs.getFloat("used", 0.0f);
    g_fuel.remaining_l = FUEL_TANK_LITERS - g_fuel.used_liters;
    if (g_fuel.remaining_l < 0) g_fuel.remaining_l = 0;
    Serial.printf("[FUEL] Restaurado: usados %.2fL, restam %.2fL\n",
                  g_fuel.used_liters, g_fuel.remaining_l);
#endif
}

void fuel_update(float pw_ms, uint16_t rpm, uint8_t speed_kmh, uint32_t dt_ms) {
#if FUEL_VIRTUAL_ENABLED
    // Eventos de injeção por minuto (4 tempos, sequencial: 1 a cada 2 voltas)
    // injeções/min = RPM / 2  →  injeções no intervalo dt = (RPM/2) * (dt/60000)
    if (rpm > 0 && pw_ms > 0.0f) {
        float inj_events = (rpm / 2.0f) * (dt_ms / 60000.0f);
        float cc = inj_events * pw_ms * CC_PER_MS;   // volume injetado (cc)
        float liters = cc / 1000.0f;
        g_fuel.used_liters += liters;

        // Consumo instantâneo (km/l): distância no intervalo / litros no intervalo
        if (liters > 1e-6f && speed_kmh > 0) {
            float km = speed_kmh * (dt_ms / 3600000.0f);  // km no intervalo
            g_fuel.econ_kmpl = km / liters;
        }
    } else {
        g_fuel.econ_kmpl = 0.0f;  // motor parado / em corte
    }

    g_fuel.remaining_l = FUEL_TANK_LITERS - g_fuel.used_liters;
    if (g_fuel.remaining_l < 0) g_fuel.remaining_l = 0;
    g_fuel.level_pct = (uint8_t)constrain(
        (int)(g_fuel.remaining_l / FUEL_TANK_LITERS * 100.0f), 0, 100);

    // Chave de reserva original (luz de baixo nível) — âncora de calibração
    g_fuel.reserve_sw = (digitalRead(FUEL_RESERVE_SW_PIN) == FUEL_RESERVE_SW_ACTIVE);

    // Quando a chave de reserva acende, o tanque tem ~FUEL_RESERVE_LITERS.
    // Recalibra o virtual se ele divergiu (corrige acúmulo de erro).
    if (g_fuel.reserve_sw && g_fuel.remaining_l > FUEL_RESERVE_LITERS + 0.5f) {
        g_fuel.used_liters = FUEL_TANK_LITERS - FUEL_RESERVE_LITERS;
        g_fuel.remaining_l = FUEL_RESERVE_LITERS;
        persist();
    }

    g_fuel.low_fuel = g_fuel.reserve_sw ||
                      (g_fuel.remaining_l <= FUEL_RESERVE_LITERS);

    // Persistência periódica (evita desgaste da flash)
    g_since_save_ms += dt_ms;
    if (g_since_save_ms >= FUEL_NVS_SAVE_MS) {
        g_since_save_ms = 0;
        persist();
    }
#endif
}

FuelState fuel_get() {
    return g_fuel;
}

void fuel_reset_full() {
    g_fuel.used_liters = 0.0f;
    g_fuel.remaining_l = FUEL_TANK_LITERS;
    g_fuel.level_pct   = 100;
    persist();
    Serial.println("[FUEL] Tanque cheio — consumo zerado");
}

void fuel_set_remaining(float liters) {
    liters = constrain(liters, 0.0f, FUEL_TANK_LITERS);
    g_fuel.used_liters = FUEL_TANK_LITERS - liters;
    g_fuel.remaining_l = liters;
    persist();
}
