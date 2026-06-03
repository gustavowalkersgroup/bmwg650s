#include "imu_sensor.h"
#include "config.h"
#include <Arduino.h>
#include <Wire.h>
#include <math.h>

// Registradores do MPU6050
static constexpr uint8_t REG_PWR_MGMT_1   = 0x6B;
static constexpr uint8_t REG_SMPLRT_DIV    = 0x19;
static constexpr uint8_t REG_CONFIG        = 0x1A;
static constexpr uint8_t REG_GYRO_CONFIG   = 0x1B;
static constexpr uint8_t REG_ACCEL_CONFIG  = 0x1C;
static constexpr uint8_t REG_ACCEL_XOUT_H  = 0x3B;
static constexpr uint8_t REG_WHO_AM_I      = 0x75;

// Fundo de escala escolhido: accel ±4g, gyro ±500°/s
static constexpr float ACCEL_LSB = 8192.0f;   // LSB/g  @ ±4g
static constexpr float GYRO_LSB  = 65.5f;     // LSB/(°/s) @ ±500°/s

static ImuData  g_imu;
static float    g_lean_filt = 0.0f;   // ângulo filtrado (complementar)
static uint32_t g_over_ms   = 0;      // tempo acumulado acima do limiar de queda

static void wr(uint8_t reg, uint8_t val) {
    Wire.beginTransmission(IMU_ADDR);
    Wire.write(reg);
    Wire.write(val);
    Wire.endTransmission();
}

static bool rd(uint8_t reg, uint8_t *buf, uint8_t n) {
    Wire.beginTransmission(IMU_ADDR);
    Wire.write(reg);
    if (Wire.endTransmission(false) != 0) return false;
    uint8_t got = Wire.requestFrom((int)IMU_ADDR, (int)n, (int)true);
    if (got != n) return false;
    for (uint8_t i = 0; i < n; i++) buf[i] = Wire.read();
    return true;
}

bool imu_init() {
#if IMU_ENABLED
    Wire.begin(IMU_I2C_SDA, IMU_I2C_SCL, 400000);

    uint8_t who = 0;
    if (!rd(REG_WHO_AM_I, &who, 1) || (who != 0x68 && who != 0x70 && who != 0x71)) {
        // 0x68 = MPU6050, 0x70/0x71 = variantes MPU6500/9250
        g_imu.present = false;
        Serial.println("[IMU] Nao encontrado no barramento I2C");
        return false;
    }

    wr(REG_PWR_MGMT_1,  0x00);  // acorda o sensor
    delay(10);
    wr(REG_SMPLRT_DIV,  0x04);  // 200Hz de amostragem interna
    wr(REG_CONFIG,      0x03);  // DLPF ~44Hz — filtra vibração do motor
    wr(REG_GYRO_CONFIG, 0x08);  // ±500°/s
    wr(REG_ACCEL_CONFIG,0x08);  // ±4g

    g_imu.present = true;
    Serial.println("[IMU] MPU6050 inicializado (±4g, ±500dps)");
    return true;
#else
    g_imu.present = false;
    return false;
#endif
}

void imu_update(uint32_t dt_ms) {
#if IMU_ENABLED
    if (!g_imu.present) return;

    uint8_t b[14];
    if (!rd(REG_ACCEL_XOUT_H, b, 14)) return;

    int16_t ax = (int16_t)((b[0]  << 8) | b[1]);
    int16_t ay = (int16_t)((b[2]  << 8) | b[3]);
    int16_t az = (int16_t)((b[4]  << 8) | b[5]);
    // b[6..7] = temperatura (ignorado)
    int16_t gx = (int16_t)((b[8]  << 8) | b[9]);   // gyro eixo X (roll rate)

    float fax = ax / ACCEL_LSB;
    float fay = ay / ACCEL_LSB;
    float faz = az / ACCEL_LSB;
    float fgx = gx / GYRO_LSB;     // °/s

    // Ângulo de inclinação lateral pela gravidade (eixo Y vs Z)
    float lean_acc = atan2f(fay, faz) * 57.2957795f;  // rad → graus

    // Filtro complementar: integra o giroscópio e corrige com o acelerômetro
    float dt = dt_ms / 1000.0f;
    g_lean_filt = 0.98f * (g_lean_filt + fgx * dt) + 0.02f * lean_acc;

    float lean = g_lean_filt - IMU_MOUNT_OFFSET_DEG;
    g_imu.lean_deg = lean;
    g_imu.accel_g  = sqrtf(fax*fax + fay*fay + faz*faz);

    // Detecção de queda: inclinação sustentada acima do limiar
    if (fabsf(lean) >= IMU_CRASH_LEAN_DEG) {
        g_over_ms += dt_ms;
        if (g_over_ms >= IMU_CRASH_HOLD_MS) {
            g_imu.crash = true;
        }
    } else {
        g_over_ms = 0;
    }
#endif
}

ImuData imu_get() {
    return g_imu;
}

void imu_clear_crash() {
    g_imu.crash = false;
    g_over_ms   = 0;
}
