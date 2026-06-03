# BMW F650GS 2001 — ECU DIY com Dashboard Bluetooth

Substituição da ECU original BMW BMS-C por sistema open-source baseado em **Speeduino** (Arduino Mega 2560) + **ESP32** como bridge Bluetooth, com **app Flutter** funcionando como painel digital (inspirado no FuelTech F700).

## Visão Geral

```
Sensores ──► Speeduino (ECU) ──UART──► ESP32 (BLE) ──BLE──► App Flutter
                 │                                              │
             Injetor                                      Dashboard +
             Bobina                                       Editor Mapas
             Bomba
```

## Componentes do Projeto

| Pasta | Descrição |
|---|---|
| `docs/` | Especificações, fiação, BOM, guia de calibração |
| `firmware/speeduino/` | Mapa base (.msq) para TunerStudio |
| `firmware/esp32-ble-bridge/` | Firmware ESP32 — bridge UART/BLE |
| `mobile-app/` | App Flutter — painel + editor de mapas |
| `hardware/` | Lista de materiais, notas de circuito |

### Documentação de recursos avançados

| Documento | Conteúdo |
|---|---|
| [`docs/riding-modes-abs-rbw.md`](docs/riding-modes-abs-rbw.md) | Modos de pilotagem, controle de tração, relé ABS, ride-by-wire |
| [`docs/flex-fuel.md`](docs/flex-fuel.md) | Conversão flex (gasolina/etanol) com Speeduino |
| [`docs/fuel-level-and-imu.md`](docs/fuel-level-and-imu.md) | Medidor de combustível virtual + IMU (inclinação/queda) |
| [`docs/ethanol-cold-start.md`](docs/ethanol-cold-start.md) | Partida a frio com etanol + aquecedor de admissão |
| [`docs/keyless-antitheft.md`](docs/keyless-antitheft.md) | Keyless (sem chave) + anti-furto via relé KL15 e imobilizador BLE |

## Início Rápido

### 1. Hardware
Consulte [`docs/bom.md`](docs/bom.md) para a lista completa de componentes e [`docs/wiring-diagram.md`](docs/wiring-diagram.md) para o diagrama de fiação.

### 2. Firmware Speeduino
- Baixe o Speeduino firmware: https://github.com/noisymime/speeduino
- Compile e carregue no Arduino Mega 2560
- Abra `firmware/speeduino/f650gs_base.msq` no TunerStudio para o mapa base da F650GS

### 3. Firmware ESP32
```bash
cd firmware/esp32-ble-bridge
# Instale PlatformIO: https://platformio.org
pio run --target upload
```

### 4. App Flutter
```bash
cd mobile-app
flutter pub get
flutter run
```

## Especificações do Motor

- **Motor**: Rotax 654cc, monocilíndrico, 4 válvulas SOHC
- **Roda fônica**: 36-1 dentes no virabrequim
- **Injetor**: Bosch EV1, ~270cc/min @ 3bar, alta impedância (12–16Ω)
- **Ignição**: Bobina indutiva, faísca desperdiçada
- **Pressão de combustível**: 3 bar

## Recursos do App (Dashboard)

- Tacômetro 0–8000 RPM
- AFR (relação ar/combustível) com faixas coloridas
- Temperatura de água e ar
- TPS (posição do acelerador)
- Avanço de ignição
- Tensão da bateria
- Pressão de óleo, knock, velocidade
- Teor de etanol (flex), correções
- **Combustível virtual**: nível, autonomia e consumo (km/l) — sem boia
- **IMU**: ângulo de inclinação + detecção de queda (corta a bomba)
- **Partida a frio**: indicador de motor frio + aquecedor para etanol
- **Keyless**: liga/desliga e dá partida pelo celular — sem chave física
- **Anti-furto**: imobilizador por proximidade BLE + relé KL15 + auto-lock
- Editor de mapa VE 16×16
- Log de dados em tempo real

## Aviso de Segurança

> Este projeto envolve modificação no sistema de combustível e ignição de um veículo. Realize todos os testes em bancada antes da instalação. O autor não se responsabiliza por danos causados pelo uso inadequado do sistema.

## Licença

MIT License
