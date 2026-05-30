#pragma once
#include "speeduino_serial.h"

void ble_init();
void ble_notify_realtime(const SpeeduinoData &data);
bool ble_is_connected();

// Pacote BLE de 20 bytes enviado ao app a cada 50ms
// Layout compacto para caber em um único MTU BLE
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
    uint8_t  alarms;     // [14]    Bitfield: bit0=CLT, bit1=RPM, bit2=BATT, bit3=LEAN, bit4=RICH
    uint8_t  corrections;// [15]    Correções %
    uint8_t  flex_pct;   // [16]    Teor etanol %
    uint8_t  baro;       // [17]    Barometria kPa
    uint8_t  loop_ms;    // [18]    Tempo loop ECU ms
    uint8_t  reserved;   // [19]    Reservado para expansão
};
