# Speeduino — Configuração para BMW F650GS

## Firmware

Baixe o firmware Speeduino mais recente em: https://github.com/noisymime/speeduino

Versão recomendada: **202309** ou posterior.

## Hardware

Use o shield **Speeduino v0.4.4c** com Arduino Mega 2560.

## Carregamento do Mapa Base

1. Instale o **TunerStudio MS** (https://tunerstudio.com)
2. Crie novo projeto → selecione firmware Speeduino
3. Conecte via USB (COM port) ou via Bluetooth (módulo HC-05 adicional)
4. Abra `f650gs_base.msq` via **File → Open Tune**
5. Grave na ECU via **File → Burn to ECU**

## Configurações Críticas

| Parâmetro | Valor |
|---|---|
| Trigger Pattern | Missing Tooth |
| Teeth Total | 36 |
| Missing Teeth | 1 |
| Trigger Angle | 54° (verificar com estroboscópio) |
| Firing Order | 1 |
| Injection Type | Sequential |
| Injectors | 1 |
| Spark Mode | Wasted Spark |
| Dwell | 3,5ms |
| Serial Speed | 115200 baud |

## Conexão com ESP32 BLE Bridge

O Speeduino deve ter o baud rate serial em **115200** (padrão).
O ESP32 se conecta ao Serial1 do Arduino Mega (pinos TX1/RX1 = D18/D19).

Certifique-se de que o ESP32 não interfere no upload via USB:
desconecte o ESP32 durante uploads de firmware no Mega.
