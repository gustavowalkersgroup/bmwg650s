#pragma once
#include <stdint.h>

// Medidor de combustível virtual: integra o volume injetado para estimar o
// nível restante no tanque (a F650GS não possui boia, só luz de reserva).
struct FuelState {
    float   used_liters   = 0.0f;   // combustível consumido desde o último abastecimento
    float   remaining_l   = 0.0f;   // estimativa do que resta no tanque
    uint8_t level_pct     = 100;    // nível em % do tanque
    float   econ_kmpl     = 0.0f;   // consumo instantâneo (km/l)
    bool    reserve_sw    = false;  // chave de reserva original ativa (luz acesa)
    bool    low_fuel      = false;  // nível abaixo da reserva (virtual OU chave)
};

void fuel_init();

// Atualiza o consumo a partir dos dados da injeção.
//   pw_ms      : largura de pulso do injetor (ms)
//   rpm        : rotação atual
//   speed_kmh  : velocidade (para calcular km/l)
//   dt_ms      : tempo desde a última chamada
void fuel_update(float pw_ms, uint16_t rpm, uint8_t speed_kmh, uint32_t dt_ms);

FuelState fuel_get();

// Reabastecimento: zera o consumo e assume tanque cheio (comando do app)
void fuel_reset_full();

// Define manualmente os litros restantes (calibração via app)
void fuel_set_remaining(float liters);
