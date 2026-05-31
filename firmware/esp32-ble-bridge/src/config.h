#pragma once

// ── UART para Speeduino ────────────────────────────────────────────────────
#define SPEEDUINO_SERIAL      Serial2
#define SPEEDUINO_BAUD        115200
#define SPEEDUINO_RX_PIN      16
#define SPEEDUINO_TX_PIN      17

// ── BLE ───────────────────────────────────────────────────────────────────
#define BLE_DEVICE_NAME       "F650GS-ECU"

// UUIDs do serviço e características BLE (gerados aleatoriamente)
#define BLE_SERVICE_UUID      "12345678-1234-1234-1234-123456789abc"
#define BLE_REALTIME_UUID     "12345678-1234-1234-1234-123456789ab1"   // notify: dados em tempo real
#define BLE_COMMAND_UUID      "12345678-1234-1234-1234-123456789ab2"   // write: comandos do app

// ── Temporização ──────────────────────────────────────────────────────────
#define SERIAL_POLL_MS        50      // requisita dados ao Speeduino a cada 50ms (20Hz)
#define BLE_NOTIFY_MS         50      // notifica BLE a cada 50ms

// ── Protocolo Speeduino ───────────────────────────────────────────────────
// Comando 'A' retorna 38 bytes de dados em tempo real
#define SPEEDUINO_CMD_REALTIME  'A'
#define SPEEDUINO_REALTIME_LEN  38

// ── Sensor de Pressão de Óleo (lido pelo ESP32) ───────────────────────────
// Sender analógico 0–10 bar (saída 0,5–4,5V) com divisor ÷2 → 0,25–2,25V no ADC
#define OIL_PRESS_ADC_PIN     34      // GPIO34 (input-only, bom para ADC)
#define OIL_PRESS_ADC_SAMPLES 8       // média de 8 leituras para filtrar ruído
#define OIL_PRESS_V_MIN       0.25f   // tensão no ADC @ 0 bar (0,5V ÷ 2)
#define OIL_PRESS_V_MAX       2.25f   // tensão no ADC @ 10 bar (4,5V ÷ 2)
#define OIL_PRESS_BAR_MAX     10.0f   // fundo de escala do sender (bar)

// ── Limites de Alarme (enviados ao app via flag) ──────────────────────────
#define ALARM_CLT_MAX_C       105     // temperatura máxima do motor
#define ALARM_RPM_LIMITER     7400    // limiter de RPM
#define ALARM_BATT_LOW_V      118     // tensão bateria baixa (×10, então 11,8V)
#define ALARM_AFR_LEAN        160     // AFR muito pobre (×10, então 16,0)
#define ALARM_AFR_RICH        105     // AFR muito rico (×10, então 10,5)
#define ALARM_OIL_LOW_BAR10   8       // pressão de óleo baixa (×10, então 0,8 bar) em RPM > idle
#define ALARM_KNOCK_DEG       2       // retardo knock ativo (graus)
