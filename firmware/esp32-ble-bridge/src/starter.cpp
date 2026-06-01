#include "starter.h"
#include "config.h"
#include <Arduino.h>

static volatile bool     g_cranking    = false;
static volatile bool     g_cooldown    = false;
static volatile uint32_t g_start_ms    = 0;
static volatile uint32_t g_cooldown_ms = 0;
static volatile bool     g_requested   = false;
static volatile bool     g_stop_req    = false;

void starter_init() {
    pinMode(STARTER_RELAY_PIN, OUTPUT);
    digitalWrite(STARTER_RELAY_PIN, !STARTER_RELAY_LEVEL);
}

// Chamado pelo BLE callback — apenas sinaliza, execução ocorre em starter_update()
void starter_pulse() {
    g_requested = true;
}

// Parada forçada via app ou imobilizador
void starter_stop() {
    g_stop_req = true;
}

static void do_start() {
    g_cranking    = true;
    g_cooldown    = false;
    g_start_ms    = millis();
    digitalWrite(STARTER_RELAY_PIN, STARTER_RELAY_LEVEL);
    Serial.println("[STARTER] Arranque ligado");
}

static void do_stop(const char *reason) {
    if (!g_cranking) return;
    g_cranking    = false;
    g_cooldown    = true;
    g_cooldown_ms = millis();
    digitalWrite(STARTER_RELAY_PIN, !STARTER_RELAY_LEVEL);
    Serial.printf("[STARTER] Parado: %s\n", reason);
}

void starter_update(uint16_t rpm) {
    uint32_t now = millis();

    if (g_stop_req) {
        g_stop_req = false;
        do_stop("manual");
    }

    if (g_requested) {
        g_requested = false;
        if (!g_cranking && !g_cooldown && rpm < STARTER_MIN_RPM_OFF) {
            do_start();
        } else if (rpm >= STARTER_MIN_RPM_OFF) {
            Serial.println("[STARTER] Ignorado: motor já ligado");
        } else if (g_cooldown) {
            Serial.println("[STARTER] Ignorado: em cooldown");
        }
    }

    if (g_cranking) {
        bool timeout = (now - g_start_ms) >= (STARTER_MAX_CRANK_S * 1000UL);
        bool started = rpm >= STARTER_MIN_RPM_OFF;
        if (timeout) do_stop("timeout 5s");
        else if (started) do_stop("motor ligado");
    }

    if (g_cooldown && (now - g_cooldown_ms) >= (STARTER_COOLDOWN_S * 1000UL)) {
        g_cooldown = false;
    }
}

bool starter_is_cranking() { return g_cranking; }
