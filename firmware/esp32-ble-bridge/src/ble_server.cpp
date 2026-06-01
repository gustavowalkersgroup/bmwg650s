#include "ble_server.h"
#include "config.h"
#include <NimBLEDevice.h>

static NimBLEServer         *pServer      = nullptr;
static NimBLECharacteristic *pRealtime    = nullptr;
static NimBLECharacteristic *pCommand     = nullptr;
static bool                  connected    = false;

class ServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer *pSvr) override {
        connected = true;
        Serial.println("[BLE] Cliente conectado");
        // Reduz intervalo de conexão para menor latência
        pSvr->updateConnParams(pSvr->getPeerInfo(0).getConnHandle(), 6, 12, 0, 300);
    }

    void onDisconnect(NimBLEServer *pSvr) override {
        connected = false;
        Serial.println("[BLE] Cliente desconectado — reiniciando advertising");
        NimBLEDevice::startAdvertising();
    }
};

// Códigos de comando do app
enum BleCommand : uint8_t {
    CMD_FUEL_REFILL    = 0x01,  // tanque cheio — zera consumo
    CMD_CLEAR_CRASH    = 0x02,  // piloto levantou a moto — limpa flag de queda
    CMD_FUEL_SET_L     = 0x03,  // define litros restantes: byte[1] = litros ×10
};

// Callback para receber comandos do app
class CommandCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pChar) override {
        std::string val = pChar->getValue();
        if (val.empty()) return;

        uint8_t cmd = (uint8_t)val[0];
        Serial.printf("[BLE] Comando recebido: 0x%02X\n", cmd);

        switch (cmd) {
            case CMD_FUEL_REFILL:
                fuel_reset_full();
                break;
            case CMD_CLEAR_CRASH:
                imu_clear_crash();
                break;
            case CMD_FUEL_SET_L:
                if (val.length() >= 2) {
                    fuel_set_remaining((uint8_t)val[1] / 10.0f);
                }
                break;
            default:
                // Expansão futura: repassar comandos ao Speeduino via UART
                break;
        }
    }
};

void ble_init() {
    NimBLEDevice::init(BLE_DEVICE_NAME);
    NimBLEDevice::setMTU(247);  // MTU maior para pacotes mais eficientes
    NimBLEDevice::setPower(ESP_PWR_LVL_P9);  // Potência máxima de TX

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    pServer->advertiseOnDisconnect(false);  // gerenciamos manualmente

    NimBLEService *pService = pServer->createService(BLE_SERVICE_UUID);

    // Característica de dados em tempo real (notify)
    pRealtime = pService->createCharacteristic(
        BLE_REALTIME_UUID,
        NIMBLE_PROPERTY::NOTIFY
    );

    // Característica de comandos (write sem resposta)
    pCommand = pService->createCharacteristic(
        BLE_COMMAND_UUID,
        NIMBLE_PROPERTY::WRITE_NR
    );
    pCommand->setCallbacks(new CommandCallbacks());

    pService->start();

    NimBLEAdvertising *pAdv = NimBLEDevice::getAdvertising();
    pAdv->addServiceUUID(BLE_SERVICE_UUID);
    pAdv->setScanResponse(true);
    pAdv->setMinPreferred(0x06);
    NimBLEDevice::startAdvertising();

    Serial.println("[BLE] Advertising iniciado: " BLE_DEVICE_NAME);
}

void ble_notify_realtime(const SpeeduinoData &data, float oil_press_bar,
                         const ImuData &imu, const FuelState &fuel) {
    if (!connected || !pRealtime) {
        return;
    }

    BleRealtimePacket pkt;
    pkt.rpm         = data.rpm;
    pkt.tps         = (uint8_t)((uint32_t)data.tps * 100 / 255);
    pkt.map_kpa     = data.map_kpa;
    pkt.clt_c       = (int8_t)((int)data.temp_clt - 40);
    pkt.iat_c       = (int8_t)((int)data.temp_iat - 40);
    pkt.afr10       = data.o2_primary;
    pkt.afr_tgt10   = data.afr_target;
    pkt.adv         = data.adv_deg;
    pkt.batt10      = data.battery10;
    pkt.ve          = data.ve;
    pkt.pw_ms10     = data.pw1_ms10;
    pkt.idle_duty   = data.idle_duty;
    pkt.sync        = data.sync_status;
    pkt.corrections = data.corrections;
    pkt.flex_pct    = data.flex_sensor;
    pkt.baro        = data.baro;
    pkt.loop_ms     = data.loop_time;
    pkt.speed_kmh   = data.vss;
    pkt.oil_press10 = (uint8_t)constrain((int)(oil_press_bar * 10.0f), 0, 255);
    pkt.knock_ret   = data.knock_ret;
    pkt.lean_deg    = (int8_t)constrain((int)imu.lean_deg, -90, 90);
    pkt.fuel_pct    = fuel.level_pct;
    pkt.econ_kmpl10 = (uint8_t)constrain((int)(fuel.econ_kmpl * 10.0f), 0, 255);

    pkt.status = 0;
    if (imu.crash)      pkt.status |= (1 << 0);
    if (fuel.low_fuel)  pkt.status |= (1 << 1);
    if (imu.present)    pkt.status |= (1 << 2);

    // Alarme de pressão de óleo: só ativa acima de 1500 RPM (descarta idle)
    bool alarm_oil   = (data.rpm > 1500) && (oil_press_bar < (ALARM_OIL_LOW_BAR10 / 10.0f));
    bool alarm_knock = (data.knock_ret >= ALARM_KNOCK_DEG);

    pkt.alarms = 0;
    if (data.alarm_clt)  pkt.alarms |= (1 << 0);
    if (data.alarm_rpm)  pkt.alarms |= (1 << 1);
    if (data.alarm_batt) pkt.alarms |= (1 << 2);
    if (data.alarm_lean) pkt.alarms |= (1 << 3);
    if (data.alarm_rich) pkt.alarms |= (1 << 4);
    if (alarm_oil)       pkt.alarms |= (1 << 5);
    if (alarm_knock)     pkt.alarms |= (1 << 6);

    pRealtime->setValue((uint8_t *)&pkt, sizeof(pkt));
    pRealtime->notify();
}

bool ble_is_connected() {
    return connected;
}
