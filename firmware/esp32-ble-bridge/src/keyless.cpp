#include "keyless.h"
#include "config.h"
#include <Arduino.h>

static volatile bool     g_kl15_on       = false;
static volatile bool     g_ble_connected = false;
static volatile uint32_t g_idle_ms       = 0;   // tempo sem BLE c/ motor desligado
static bool              g_btn_prev      = false;

static void set_kl15(bool on) {
    g_kl15_on = on;
    digitalWrite(KL15_RELAY_PIN, on ? KL15_RELAY_LEVEL : !KL15_RELAY_LEVEL);
    Serial.printf("[KEYLESS] KL15 %s\n", on ? "LIGADA" : "DESLIGADA");
}

void keyless_init() {
    pinMode(KL15_RELAY_PIN, OUTPUT);
    digitalWrite(KL15_RELAY_PIN, !KL15_RELAY_LEVEL);  // começa desligada (segura)
    pinMode(BACKUP_BTN_PIN, INPUT_PULLUP);
    g_kl15_on = false;
}

void keyless_ignition_on()  { set_kl15(true);  g_idle_ms = 0; }
void keyless_ignition_off() { set_kl15(false); }

void keyless_on_ble_connect()    { g_ble_connected = true;  g_idle_ms = 0; }
void keyless_on_ble_disconnect() { g_ble_connected = false; }

void keyless_update(uint16_t rpm, uint32_t dt_ms) {
    // Botão físico oculto (emergência): toggle no flanco de pressão
    bool btn = (digitalRead(BACKUP_BTN_PIN) == BACKUP_BTN_ACTIVE);
    if (btn && !g_btn_prev) {
        set_kl15(!g_kl15_on);
        Serial.println("[KEYLESS] Botão físico de emergência");
    }
    g_btn_prev = btn;

    bool engine_running = (rpm >= STARTER_MIN_RPM_OFF);

    // Auto-lock: motor desligado + sem celular por KL15_AUTOLOCK_S → corta KL15.
    // Com motor rodando, quem cuida da ausência do celular é o imobilizador.
    if (g_kl15_on && !g_ble_connected && !engine_running) {
        g_idle_ms += dt_ms;
        if (g_idle_ms >= (KL15_AUTOLOCK_S * 1000UL)) {
            set_kl15(false);
            Serial.println("[KEYLESS] Auto-lock — moto bloqueada");
        }
    } else {
        g_idle_ms = 0;
    }
}

bool keyless_is_on() { return g_kl15_on; }
