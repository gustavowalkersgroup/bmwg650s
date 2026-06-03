#pragma once
#include <stdint.h>

// Lógica de partida a frio com etanol. O etanol vaporiza mal a frio, então:
//  - indica "motor frio" (ainda não atingiu temperatura de trabalho)
//  - calcula a temperatura mínima confortável conforme o teor de etanol
//  - (opcional) controla um aquecedor de admissão PTC antes da partida
struct ColdStartState {
    bool    engine_cold     = false;  // CLT abaixo da temp de trabalho
    bool    too_cold_estart = false;  // frio demais p/ o etanol atual (preaquecer)
    bool    heater_active   = false;  // aquecedor PTC ligado
    bool    ready_to_start  = false;  // temp ok OU preaquecimento concluído
    uint8_t min_start_c     = 0;      // temp mínima recomendada (°C) p/ etanol atual
    uint8_t heater_left_s   = 0;      // segundos restantes de preaquecimento
};

void cold_start_init();

// Atualiza a lógica. clt_c = temp do motor; flex_pct = teor de etanol;
// rpm = rotação; dt_ms = intervalo desde a última chamada.
void cold_start_update(int clt_c, uint8_t flex_pct, uint16_t rpm, uint32_t dt_ms);

ColdStartState cold_start_get();
