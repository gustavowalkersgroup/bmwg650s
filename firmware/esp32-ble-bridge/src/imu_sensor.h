#pragma once
#include <stdint.h>

// Dados do IMU (MPU6050) — inclinação lateral e detecção de queda
struct ImuData {
    bool    present     = false;  // IMU respondeu no barramento I2C
    float   lean_deg    = 0.0f;   // ângulo de inclinação lateral (roll), graus
    float   accel_g     = 1.0f;   // magnitude da aceleração (g) — impacto
    bool    crash       = false;  // queda confirmada
};

// Inicializa o I2C e o MPU6050. Retorna true se o sensor respondeu.
bool imu_init();

// Atualiza a leitura (chamar periodicamente, ~50Hz). dt_ms = tempo desde a
// última chamada, usado no filtro complementar.
void imu_update(uint32_t dt_ms);

// Último estado calculado
ImuData imu_get();

// Zera o flag de queda (ex: comando do app após o piloto levantar a moto)
void imu_clear_crash();
