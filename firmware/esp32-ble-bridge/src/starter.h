#pragma once
#include <stdint.h>

void    starter_init();
void    starter_pulse();             // solicita partida (via BLE cmd)
void    starter_stop();              // para o arranque manualmente
void    starter_update(uint16_t rpm);// monitoramento contínuo; chamar a cada 50ms
bool    starter_is_cranking();
