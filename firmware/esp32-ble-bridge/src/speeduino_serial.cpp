#include "speeduino_serial.h"
#include "config.h"
#include <Arduino.h>

void speeduino_init() {
    SPEEDUINO_SERIAL.begin(SPEEDUINO_BAUD, SERIAL_8N1, SPEEDUINO_RX_PIN, SPEEDUINO_TX_PIN);
}

bool speeduino_request_realtime(SpeeduinoData &data) {
    // Flush buffer antes de enviar
    while (SPEEDUINO_SERIAL.available()) {
        SPEEDUINO_SERIAL.read();
    }

    SPEEDUINO_SERIAL.write(SPEEDUINO_CMD_REALTIME);
    SPEEDUINO_SERIAL.flush();

    // Aguarda resposta com timeout de 100ms
    uint32_t timeout = millis() + 100;
    while (SPEEDUINO_SERIAL.available() < SPEEDUINO_REALTIME_LEN) {
        if (millis() > timeout) {
            return false;
        }
        delay(1);
    }

    uint8_t buf[SPEEDUINO_REALTIME_LEN];
    SPEEDUINO_SERIAL.readBytes(buf, SPEEDUINO_REALTIME_LEN);

    // Parse dos bytes conforme protocolo Speeduino (firmware 202305+)
    data.rpm         = (uint16_t)(buf[0] << 8 | buf[1]);
    data.tps         = buf[2];
    data.vss         = buf[3];
    data.temp_clt    = buf[4];
    data.temp_iat    = buf[5];
    data.map_kpa     = buf[6];
    data.battery10   = buf[7];
    data.o2_primary  = buf[8];
    data.corrections = buf[9];
    data.ve          = buf[10];
    data.adv_deg     = (int8_t)buf[11];
    data.pw1_ms10    = buf[12];
    data.idle_duty   = buf[13];
    data.boost_duty  = buf[14];
    data.spark_duty  = buf[15];
    data.afr_target  = buf[16];
    data.loop_time   = buf[17];
    data.fuel_load   = (uint16_t)(buf[18] << 8 | buf[19]);
    data.ign_load    = (uint16_t)(buf[20] << 8 | buf[21]);
    data.launch_corr = buf[22];
    data.idle_load   = buf[23];
    data.sync_status = buf[24];
    data.clttps_corr = buf[25];
    data.flex_sensor = buf[26];
    data.flex_ign_corr  = (int8_t)buf[27];
    data.flex_fuel_corr = buf[28];
    data.status1     = buf[29];
    data.status2     = buf[30];
    data.status3     = buf[31];
    data.status4     = buf[32];
    data.throttle_in = buf[33];
    data.map_raw     = buf[34];
    data.baro        = buf[35];
    data.tac_output  = buf[36];
    data.knock_ret   = buf[37];

    speeduino_check_alarms(data);
    return true;
}

void speeduino_check_alarms(SpeeduinoData &data) {
    // Temperatura da água acima do limite
    data.alarm_clt  = ((int)data.temp_clt - 40) >= ALARM_CLT_MAX_C;

    // RPM acima do limiter
    data.alarm_rpm  = data.rpm >= ALARM_RPM_LIMITER;

    // Bateria baixa
    data.alarm_batt = data.battery10 < ALARM_BATT_LOW_V;

    // AFR muito pobre (motor em carga — ignora vácuo e corte de injeção)
    data.alarm_lean = (data.map_kpa > 40) && (data.o2_primary > ALARM_AFR_LEAN);

    // AFR muito rico
    data.alarm_rich = (data.map_kpa > 40) && (data.o2_primary < ALARM_AFR_RICH);
}
