#pragma once
#include "speeduino_serial.h"
#include "imu_sensor.h"
#include "fuel_tracker.h"
#include "cold_start.h"

void ble_init();
void ble_notify_realtime(const SpeeduinoData &data, float oil_press_bar,
                         const ImuData &imu, const FuelState &fuel,
                         const ColdStartState &cold);
bool ble_is_connected();

// Pacote BLE de 28 bytes enviado ao app a cada 50ms
struct __attribute__((packed)) BleRealtimePacket {
    uint16_t rpm;        // [0-1]   RPM real
    uint8_t  tps;        // [2]     TPS 0–100%
    uint8_t  map_kpa;    // [3]     MAP kPa
    int8_t   clt_c;      // [4]     Temp água °C (val = raw - 40)
    int8_t   iat_c;      // [5]     Temp ar °C
    uint8_t  afr10;      // [6]     AFR ×10 (147 = 14,7)
    uint8_t  afr_tgt10;  // [7]     AFR alvo ×10
    int8_t   adv;        // [8]     Avanço ignição graus BTDC
    uint8_t  batt10;     // [9]     Tensão bateria ×10
    uint8_t  ve;         // [10]    VE atual %
    uint8_t  pw_ms10;    // [11]    Largura pulso ×0,1ms
    uint8_t  idle_duty;  // [12]    IAC duty %
    uint8_t  sync;       // [13]    0=sincronizado, 1=sem sync
    // alarms bitfield: bit0=CLT, bit1=RPM, bit2=BATT, bit3=LEAN, bit4=RICH, bit5=OIL, bit6=KNOCK
    uint8_t  alarms;     // [14]
    uint8_t  corrections;// [15]    Correções %
    uint8_t  flex_pct;   // [16]    Teor etanol %
    uint8_t  baro;       // [17]    Barometria kPa
    uint8_t  loop_ms;    // [18]    Tempo loop ECU ms
    uint8_t  speed_kmh;  // [19]    Velocidade km/h (VSS via Speeduino)
    uint8_t  oil_press10;// [20]    Pressão de óleo ×10 bar (lida pelo ESP32)
    uint8_t  knock_ret;  // [21]    Retardo knock graus (via Speeduino)
    int8_t   lean_deg;   // [22]    Inclinação lateral (graus, IMU)
    // status bitfield: bit0=CRASH, bit1=LOW_FUEL, bit2=IMU_OK,
    //   bit3=ENGINE_COLD, bit4=TOO_COLD_ETHANOL, bit5=HEATER_ON, bit6=READY_START
    uint8_t  status;     // [23]
    uint8_t  fuel_pct;   // [24]    Nível de combustível virtual (%)
    uint8_t  econ_kmpl10;// [25]    Consumo instantâneo km/l ×10
    uint8_t  cold_min_c; // [26]    Temp mínima recomendada p/ partida (°C)
    uint8_t  heater_s;   // [27]    Segundos restantes de preaquecimento
};
