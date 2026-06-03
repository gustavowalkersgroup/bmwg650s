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

// ── Sensores de Roda ABS (grampeados em paralelo, p/ controle de tração) ──
// Hall effect 3 fios; sinal lido em paralelo ao módulo ABS original (intacto)
#define WHEEL_FRONT_PIN       35      // GPIO35 (input-only) — pulsos roda dianteira
#define WHEEL_REAR_PIN        32      // GPIO32 — pulsos roda traseira
#define WHEEL_PULSES_PER_REV  48      // dentes do anel ABS (medir/confirmar)
#define WHEEL_CIRCUM_MM       1910    // circunferência pneu traseiro (130/80-17)

// ── Controle de Tração ────────────────────────────────────────────────────
// ESP32 calcula slip e pulsa o pino de TC do Speeduino quando excede o limiar
#define TC_SPEEDUINO_PIN      25      // GPIO25 → entrada de TC do Speeduino
#define TC_SLIP_ECO           10      // limiar de patinagem (%) por modo
#define TC_SLIP_SPEED         20
#define TC_SLIP_OFFROAD       30
#define TC_SLIP_CRUISE        15

// ── Relé do ABS (desligamento p/ OFFROAD) ─────────────────────────────────
// Relé NF (normalmente fechado): LOW = ABS ligado (padrão seguro)
#define ABS_RELAY_PIN         26      // GPIO26 → driver do relé do ABS
#define ABS_RELAY_OFF_LEVEL   HIGH    // nível que ABRE o relé (desliga ABS)
// Estado padrão na partida = ABS LIGADO (nunca persiste off entre ignições)

// ── Botões de Modo de Pilotagem (guidão) ──────────────────────────────────
// Botões com debounce; ciclam ECO → SPEED → OFFROAD → CRUISE
#define MODE_BTN_NEXT_PIN     27      // GPIO27 — próximo modo
#define MODE_BTN_PREV_PIN     14      // GPIO14 — modo anterior
#define MODE_BTN_DEBOUNCE_MS  40

// Modos de pilotagem (índice enviado ao app e usado nas tabelas de parâmetros)
#define MODE_ECO              0
#define MODE_SPEED            1
#define MODE_OFFROAD          2
#define MODE_CRUISE           3
#define MODE_DEFAULT          MODE_SPEED   // modo ao ligar a moto

// ── Ride-by-Wire (FASE FUTURA — desabilitado por padrão) ──────────────────
// Migração para acelerador eletrônico. Requer mola de retorno + watchdog.
#define RBW_ENABLED           0       // 0 = acelerador a cabo (atual); 1 = RbW
#define RBW_THROTTLE_POT_PIN  39      // GPIO39 (input-only) — potenciômetro do punho
#define RBW_SERVO_PIN         33      // GPIO33 — sinal PWM do servo da borboleta
#define RBW_WATCHDOG_MS       50      // se loop travar > 50ms, força borboleta p/ 0%

// ── IMU (MPU6050 via I2C) — inclinação + detecção de queda ────────────────
#define IMU_ENABLED           1       // 1 = IMU instalado; 0 = desabilita leitura
#define IMU_I2C_SDA           21      // GPIO21 — I2C SDA
#define IMU_I2C_SCL           22      // GPIO22 — I2C SCL
#define IMU_ADDR              0x68    // endereço I2C do MPU6050 (0x69 se AD0=HIGH)
#define IMU_UPDATE_MS         20      // 50Hz — responsivo p/ inclinação e queda
#define IMU_CRASH_LEAN_DEG    62      // inclinação (graus) que caracteriza queda
#define IMU_CRASH_HOLD_MS     1500    // tempo acima do limiar p/ confirmar queda
#define IMU_MOUNT_OFFSET_DEG  0       // ajuste se o sensor não ficar perfeitamente nivelado

// Corte de combustível na queda (segurança): ESP32 corta o relé da bomba
#define FUEL_CUT_ON_CRASH     1       // 1 = corta bomba ao detectar queda
#define FUEL_PUMP_KILL_PIN    13      // GPIO13 → relé/MOSFET que interrompe a bomba
#define FUEL_PUMP_KILL_LEVEL  HIGH    // nível que CORTA a bomba

// ── Nível de Combustível (medidor virtual por integração de injeção) ──────
// A F650GS não tem boia — só luz de reserva. Como controlamos a injeção,
// integramos o volume injetado para estimar o que resta no tanque.
#define FUEL_VIRTUAL_ENABLED  1
#define FUEL_INJECTOR_CCMIN   270.0f  // vazão do injetor a 100% (cc/min @ 3 bar)
#define FUEL_TANK_LITERS      17.3f   // capacidade total do tanque F650GS
#define FUEL_RESERVE_LITERS   4.0f    // volume em que a luz de reserva acende
#define FUEL_NVS_SAVE_MS      60000   // salva nível na flash a cada 60s (anti-wear)

// Interruptor de reserva original (luz de baixo nível) lido pelo ESP32
#define FUEL_RESERVE_SW_PIN   23      // GPIO23 — chave de reserva (ativa em LOW)
#define FUEL_RESERVE_SW_ACTIVE LOW    // nível quando está na reserva

// ── Sistema Keyless (sem chave física) ───────────────────────────────────
// O ESP32 fica alimentado em KL30 (bateria direta, ~2mA standby).
// O relé KL15 (normalmente aberto) é fechado pelo ESP32 quando o celular
// está próximo — energiza ECU, bomba, bobina e instrumentos.
// Sem o celular autorizado = KL15 aberta = moto inerte.
#define KL15_RELAY_PIN        19    // GPIO19 → relé KL15 (normalmente aberto)
#define KL15_RELAY_LEVEL      HIGH  // HIGH = relé fechado = KL15 ligado
#define KL15_AUTOLOCK_S       30    // s sem BLE com motor desligado → bloqueia

// Botão físico oculto (emergência: celular sem bateria)
// Esconder em local discreto no quadro — mantém um botão de backup
#define BACKUP_BTN_PIN        15    // GPIO15 — pull-up interno; ativo em LOW
#define BACKUP_BTN_ACTIVE     LOW

// ── Partida via Touch (motor de arranque) ─────────────────────────────────
// Relé no GPIO18 aciona o motor de arranque; segurança: RPM==0, sem crash, sem immo
#define STARTER_RELAY_PIN        18    // GPIO18 → bobina do relé do arranque
#define STARTER_RELAY_LEVEL      HIGH  // nível que ACIONA o relé
#define STARTER_MAX_CRANK_S      5     // máximo contínuo de arranque (s)
#define STARTER_MIN_RPM_OFF      200   // RPM mínimo p/ considerar motor já ligado
#define STARTER_COOLDOWN_S       3     // intervalo mínimo entre tentativas (s)

// ── Imobilizador por Proximidade BLE ─────────────────────────────────────
// Se o celular sumir com o motor rodando: aguarda IMMOBILIZER_TIMEOUT_S e corta.
// Reconectar durante o countdown cancela. Após corte, exige CMD_IMMOBILIZER_ACK.
#define IMMOBILIZER_TIMEOUT_S    10    // segundos sem BLE antes do corte
#define IMMOBILIZER_MIN_RPM      500   // RPM mínimo p/ armar o countdown

// ── Partida a Frio com Etanol ─────────────────────────────────────────────
// Etanol não vaporiza bem a frio. O ESP32 indica "motor frio" e (opcional)
// controla um aquecedor de admissão PTC antes da partida — estilo "aguarde".
#define COLDSTART_ENABLED     1
#define COLDSTART_WARMUP_C    60      // CLT abaixo disso = motor ainda frio (indicador)
#define COLDSTART_E0_MIN_C    2       // temp mínima confortável com gasolina pura (°C)
#define COLDSTART_E100_MIN_C  18      // temp mínima confortável com etanol puro (°C)
#define COLDSTART_RUN_RPM     400     // acima disso o motor é considerado "rodando"

// Aquecedor de admissão (resistência PTC) — preaquece antes da partida fria
#define COLDSTART_HEATER_ENABLED 1
#define COLDSTART_HEATER_PIN  4       // GPIO4 → relé do aquecedor PTC
#define COLDSTART_HEATER_LEVEL HIGH   // nível que LIGA o aquecedor
#define COLDSTART_HEATER_MAX_S 30     // tempo máximo de preaquecimento (s)


