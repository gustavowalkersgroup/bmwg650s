#pragma once
#include <stdint.h>

// Estrutura de dados em tempo real lida do Speeduino (comando 'A', 38 bytes)
struct SpeeduinoData {
    uint16_t rpm;           // [0-1]  RPM
    uint8_t  tps;           // [2]    TPS 0–255 (0–100%)
    uint8_t  vss;           // [3]    Velocidade (pulsos VSS)
    uint8_t  temp_clt;      // [4]    Temperatura água +40 (°C = val - 40)
    uint8_t  temp_iat;      // [5]    Temperatura ar +40
    uint8_t  map_kpa;       // [6]    MAP em kPa
    uint8_t  battery10;     // [7]    Tensão bateria ×10 (ex: 138 = 13,8V)
    uint8_t  o2_primary;    // [8]    O2 primário: AFR ×10 (ex: 147 = 14,7)
    uint8_t  corrections;   // [9]    Correções combinadas (%)
    uint8_t  ve;            // [10]   VE atual (%)
    int8_t   adv_deg;       // [11]   Avanço de ignição (graus BTDC)
    uint8_t  pw1_ms10;      // [12]   Largura de pulso injetor ×0,1ms
    uint8_t  idle_duty;     // [13]   Duty cycle IAC (%)
    uint8_t  boost_duty;    // [14]   Duty cycle boost solenóide (%)
    uint8_t  spark_duty;    // [15]   Duty cycle dwell (%)
    uint8_t  afr_target;    // [16]   AFR alvo ×10
    uint8_t  loop_time;     // [17]   Tempo de loop da ECU (ms)
    uint16_t fuel_load;     // [18-19] Carga combustível
    uint16_t ign_load;      // [20-21] Carga ignição
    uint8_t  launch_corr;   // [22]   Correção launch
    uint8_t  idle_load;     // [23]   Carga IAC
    uint8_t  sync_status;   // [24]   Status de sincronismo (0=sync, 1=lost)
    uint8_t  clttps_corr;   // [25]   Correção CLT×TPS
    uint8_t  flex_sensor;   // [26]   Sensor flex (%)
    int8_t   flex_ign_corr; // [27]   Correção ignição flex
    uint8_t  flex_fuel_corr;// [28]   Correção combustível flex
    uint8_t  status1;       // [29]   Status byte 1
    uint8_t  status2;       // [30]   Status byte 2
    uint8_t  status3;       // [31]   Status byte 3
    uint8_t  status4;       // [32]   Status byte 4
    uint8_t  throttle_in;   // [33]   TPS raw ADC low byte
    uint8_t  map_raw;       // [34]   MAP raw ADC low byte
    uint8_t  baro;          // [35]   Pressão barométrica (kPa)
    uint8_t  tac_output;    // [36]   Saída tacômetro
    uint8_t  knock_ret;     // [37]   Retardo knock (graus)

    // Flags de alarme calculados localmente
    bool alarm_clt;
    bool alarm_rpm;
    bool alarm_batt;
    bool alarm_lean;
    bool alarm_rich;
};

void speeduino_init();
bool speeduino_request_realtime(SpeeduinoData &data);
void speeduino_check_alarms(SpeeduinoData &data);
