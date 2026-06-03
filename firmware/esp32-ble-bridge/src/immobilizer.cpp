#include "immobilizer.h"
#include "config.h"
#include <Arduino.h>

// Estados internos — volatile porque g_state é lido em Core 1 (apply_fuel_cut)
// e escrito em Core 0 (task_serial_read + BLE callbacks)
enum ImmoState : uint8_t { IMMO_IDLE = 0, IMMO_COUNTDOWN, IMMO_KILLED };

static volatile ImmoState g_state         = IMMO_IDLE;
static volatile bool      g_enabled       = false;
static volatile bool      g_ble_connected = false;
static volatile uint32_t  g_countdown_ms  = 0;

void immobilizer_init() {
    g_state         = IMMO_IDLE;
    g_enabled       = false;
    g_ble_connected = false;
}

void immobilizer_set_enabled(bool en) {
    g_enabled = en;
    if (!en && g_state == IMMO_COUNTDOWN) {
        g_state = IMMO_IDLE;
        Serial.println("[IMMO] Desativado — countdown cancelado");
    }
}

bool immobilizer_is_enabled() { return g_enabled; }

void immobilizer_on_ble_connect() {
    g_ble_connected = true;
    if (g_state == IMMO_COUNTDOWN) {
        g_state = IMMO_IDLE;
        Serial.println("[IMMO] Reconectado — countdown cancelado");
    }
    // Estado KILLED não cancela sozinho: exige CMD_IMMOBILIZER_ACK explícito
}

void immobilizer_on_ble_disconnect() {
    g_ble_connected = false;
    // O countdown só começa quando update() detecta RPM > limiar
}

void immobilizer_update(uint16_t rpm, uint32_t dt_ms) {
    if (!g_enabled) return;

    bool running = (rpm >= IMMOBILIZER_MIN_RPM);

    switch (g_state) {
        case IMMO_IDLE:
            if (!g_ble_connected && running) {
                g_state       = IMMO_COUNTDOWN;
                g_countdown_ms = IMMOBILIZER_TIMEOUT_S * 1000UL;
                Serial.printf("[IMMO] BLE perdido (RPM=%u) — corte em %ds\n",
                              rpm, IMMOBILIZER_TIMEOUT_S);
            }
            break;

        case IMMO_COUNTDOWN:
            if (g_ble_connected) {
                g_state = IMMO_IDLE;
                Serial.println("[IMMO] Reconectado — corte cancelado");
            } else if (g_countdown_ms > dt_ms) {
                g_countdown_ms -= dt_ms;
            } else {
                g_countdown_ms = 0;
                g_state        = IMMO_KILLED;
                Serial.println("[IMMO] IMOBILIZADOR ATIVO — combustível cortado");
            }
            break;

        case IMMO_KILLED:
            // Permanece até immobilizer_ack() com BLE conectado
            break;
    }
}

bool immobilizer_is_countdown() { return g_state == IMMO_COUNTDOWN; }
bool immobilizer_is_killed()    { return g_state == IMMO_KILLED;    }

uint8_t immobilizer_countdown_s() {
    if (g_state != IMMO_COUNTDOWN) return 0;
    return (uint8_t)(g_countdown_ms / 1000UL);
}

void immobilizer_ack() {
    if (g_state == IMMO_KILLED && g_ble_connected) {
        g_state = IMMO_IDLE;
        Serial.println("[IMMO] Desbloqueado via app");
    }
}
