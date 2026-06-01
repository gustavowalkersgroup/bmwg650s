#pragma once
#include <stdint.h>

void    immobilizer_init();
void    immobilizer_set_enabled(bool en);
bool    immobilizer_is_enabled();
void    immobilizer_on_ble_connect();    // chamado pelo BLE callback
void    immobilizer_on_ble_disconnect(); // chamado pelo BLE callback
void    immobilizer_update(uint16_t rpm, uint32_t dt_ms);
bool    immobilizer_is_countdown();      // contagem regressiva antes do corte
bool    immobilizer_is_killed();         // combustível cortado (aguardando ack)
uint8_t immobilizer_countdown_s();       // segundos restantes no countdown
void    immobilizer_ack();               // desbloqueia após reconexão do celular
