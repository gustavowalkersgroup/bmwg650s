#include "cold_start.h"
#include "config.h"
#include <Arduino.h>

static ColdStartState g_cs;
static uint32_t       g_heater_ms = 0;   // tempo acumulado de aquecedor ligado

// Temperatura mínima confortável de partida em função do teor de etanol.
// Interpola entre E0 (gasolina) e E100 (etanol puro).
static int min_start_temp(uint8_t flex_pct) {
    if (flex_pct > 100) flex_pct = 100;
    int range = COLDSTART_E100_MIN_C - COLDSTART_E0_MIN_C;
    return COLDSTART_E0_MIN_C + (range * flex_pct) / 100;
}

static void set_heater(bool on) {
#if COLDSTART_HEATER_ENABLED
    digitalWrite(COLDSTART_HEATER_PIN, on ? COLDSTART_HEATER_LEVEL : !COLDSTART_HEATER_LEVEL);
#endif
    g_cs.heater_active = on;
}

void cold_start_init() {
#if COLDSTART_ENABLED && COLDSTART_HEATER_ENABLED
    pinMode(COLDSTART_HEATER_PIN, OUTPUT);
    set_heater(false);
#endif
}

void cold_start_update(int clt_c, uint8_t flex_pct, uint16_t rpm, uint32_t dt_ms) {
#if COLDSTART_ENABLED
    bool running = (rpm >= COLDSTART_RUN_RPM);
    int  needed  = min_start_temp(flex_pct);

    g_cs.min_start_c = (uint8_t)constrain(needed, 0, 255);
    g_cs.engine_cold = (clt_c < COLDSTART_WARMUP_C);
    g_cs.too_cold_estart = (!running) && (clt_c < needed);

    if (running) {
        // Motor pegou — desliga aquecedor. Enriquecimento de aquecimento (WUE)
        // fica por conta do Speeduino, escalado pelo teor de etanol no flex.
        set_heater(false);
        g_heater_ms = 0;
        g_cs.heater_left_s = 0;
        g_cs.ready_to_start = true;   // já rodando
        return;
    }

    // Motor parado: decide preaquecimento
    if (g_cs.too_cold_estart) {
#if COLDSTART_HEATER_ENABLED
        if (g_heater_ms < (uint32_t)COLDSTART_HEATER_MAX_S * 1000) {
            set_heater(true);
            g_heater_ms += dt_ms;
            uint32_t left = ((uint32_t)COLDSTART_HEATER_MAX_S * 1000 - g_heater_ms) / 1000;
            g_cs.heater_left_s  = (uint8_t)min<uint32_t>(left, 255);
            g_cs.ready_to_start = false;   // ainda aguardando
        } else {
            // Preaquecimento concluído — libera a partida mesmo se frio
            set_heater(false);
            g_cs.heater_left_s  = 0;
            g_cs.ready_to_start = true;
        }
#else
        // Sem aquecedor: apenas avisa que está frio para o etanol
        g_cs.ready_to_start = false;
#endif
    } else {
        // Temperatura adequada para o combustível atual
        set_heater(false);
        g_heater_ms = 0;
        g_cs.heater_left_s  = 0;
        g_cs.ready_to_start = true;
    }
#endif
}

ColdStartState cold_start_get() {
    return g_cs;
}
