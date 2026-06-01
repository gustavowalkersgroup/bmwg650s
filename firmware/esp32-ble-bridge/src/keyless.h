#pragma once
#include <stdint.h>

// Sistema keyless: o ESP32 (alimentado em KL30) controla o relé KL15 que
// energiza toda a moto. Sem celular autorizado = KL15 aberta = moto inerte.

void keyless_init();
void keyless_ignition_on();              // liga KL15 (app autorizado)
void keyless_ignition_off();             // desliga KL15 (desligar a moto)
void keyless_on_ble_connect();           // app conectou
void keyless_on_ble_disconnect();        // app saiu
void keyless_update(uint16_t rpm, uint32_t dt_ms);
bool keyless_is_on();                    // KL15 fechado (moto energizada)
