# Diagrama de Fiação — ECU DIY para BMW F650GS 2001

## Visão Geral da Fiação

```
                         ┌─────────────────────────────────────────┐
                         │          SPEEDUINO v0.4.4c               │
                         │         (Arduino Mega 2560)              │
  ┌──────────┐           │                                          │
  │ BATERIA  │──KL30────►│ +12V RAW (via fusível 15A)               │
  │ 12V      │──KL15────►│ +12V IGN (via relé de ignição)           │
  └──────────┘           │                                          │
                         │  ENTRADAS ANALÓGICAS:                    │
  ┌──────────┐           │  A0 ◄─── TPS (0–5V)                      │
  │   TPS    │──sinal───►│  A1 ◄─── MAP (MPX4250, 0–5V)            │
  │ (aceler) │──+5V ◄────│  A2 ◄─── CLT (NTC, 5V pull-up 2k49)     │
  └──────────┘           │  A3 ◄─── IAT (NTC, 5V pull-up 2k49)     │
                         │  A4 ◄─── O2 wideband (0–5V AFR)         │
  ┌──────────┐           │  A5 ◄─── Tensão bateria (div. resistivo)  │
  │  MAP     │──sinal───►│                                          │
  │ MPX4250  │──+5V ◄────│  ENTRADAS DIGITAIS/VR:                   │
  └──────────┘           │  D2 ◄─── CPS+ (via VR conditioner)      │
                         │  D3 ◄─── CPS− (via VR conditioner)      │
  ┌──────────┐           │                                          │
  │   CPS    │──VR+─────►│  SAÍDAS:                                 │
  │ (36-1)   │──VR−─────►│  D6 ──► Injetor (low-side, IRFZ44N)     │
  └──────────┘           │  D8 ──► Ignição bobina (low-side)        │
                         │  D7 ──► Relé bomba combustível           │
  ┌──────────┐           │  D4/D5/D11/D12 ──► IAC stepper           │
  │  CLT     │──NTC─────►│                                          │
  └──────────┘           │  UART TX (D18) ──► ESP32 RX              │
                         │  UART RX (D19) ◄── ESP32 TX              │
  ┌──────────┐           └─────────────────────────────────────────┘
  │  IAT     │──NTC─────►
  └──────────┘
                         ┌─────────────────────────────────────────┐
  ┌──────────┐           │            ESP32-WROOM-32                │
  │  O2 WB   │──0-5V────►│                                          │
  │  (CJ125) │           │  RX (GPIO16) ◄── Speeduino TX           │
  └──────────┘           │  TX (GPIO17) ──► Speeduino RX           │
                         │                                          │
                         │  BLE ◄──────────────────────────────────►│ App Celular
                         └─────────────────────────────────────────┘
```

## Detalhamento por Sistema

### Alimentação da ECU

```
Bateria 12V (+)
  │
  ├── Fusível 30A ──► Relé principal (bobina ativada por KL15)
  │                        │
  │                        └──► +12V para injetor, bobina, bomba
  │
  ├── Fusível 15A ──► Pin +12V RAW do Speeduino (sempre ligado)
  │
  └── KL15 (chave) ──► Fusível 5A ──► Bobina relé principal
                                  ──► Fusível 5A ──► +12V IGN Speeduino

Bateria 12V (−) ──► GND motor ──► GND Speeduino (pino GND)
                              ──► GND todos sensores (estrela no bloco)
```

> **Importante**: Use uma estrela de terra no bloco do motor. Todos os GNDs de sensores devem convergir em um único ponto para evitar diferença de potencial que gera leituras falsas.

### Circuito Sensor CPS (Roda Fônica 36-1)

O sensor original da F650GS é do tipo **relutância variável (VR / indutivo)**. Esse tipo gera uma onda senoidal cuja amplitude varia com a rotação. É necessário um **VR conditioner** (já incluso no shield Speeduino v0.4) para converter em sinal digital.

```
Sensor CPS (+) ──► VR+ do shield Speeduino
Sensor CPS (−) ──► VR− do shield Speeduino
               (ou GND se sensor de 2 fios)

O shield usa o IC MAX9926 (ou similar) que:
  - Detecta cruzamento de zero do sinal senoidal
  - Converte para sinal digital 5V compatível com Arduino
  - Pino de saída conectado ao Input Capture Pin (ICP1 = D49 no Mega)
```

### Circuito do Injetor

O injetor Bosch EV1 da F650GS é de **alta impedância (12–16Ω)**, portanto não precisa de circuito peak & hold — pode ser acionado diretamente por transistor MOSFET.

```
+12V (relé principal)
  │
  ├──► Resistor flyback/proteção TVS ──┐
  │                                    │
  └──► Injetor (+) ──────► Injetor (−) ──► MOSFET IRFZ44N (Drain)
                                                │
                                           MOSFET (Gate) ◄── 150Ω ◄── Speeduino D6
                                                │
                                           MOSFET (Source) ──► GND
```

> **Nota**: O shield Speeduino v0.4 já inclui os MOSFETs e resistores de gate para os canais de injetor. Conecte apenas o fio do injetor ao terminal INJ1 do shield.

### Circuito da Bobina de Ignição

```
+12V (relé principal)
  │
  └──► Bobina (+)
             │
        Bobina (−) ──► MOSFET/Transistor IGN (Drain)
                              │
                         IGN Gate ◄── 150Ω ◄── Speeduino D8
                              │
                           GND (Source)
```

> **Atenção**: A bobina gera picos de tensão de 300V+. Use transistor de ignição adequado (BIP373, IGBT, ou equivalente) — **não** use MOSFET convencional sem proteção. O shield Speeduino usa o IFR540 com diodo TVS.

### Sensor MAP — MPX4250AP

```
MPX4250AP (encapsulamento TO-232AA, 6 pinos):
  Pin 1 (VOUT) ──► Speeduino A1 (MAP input)
  Pin 2 (GND)  ──► GND
  Pin 3 (VCC)  ──► +5V
  Pin 4 (N/C)
  Pin 5 (N/C)
  Pin 6 (N/C)

Conexão à galeria de admissão via mangueira de vácuo 4mm.
```

### Wideband O2 — Sonda LSU 4.9 + Controlador CJ125

```
Sonda LSU 4.9 (6 fios):
  Pino 1 (APE) ──► CJ125 pino IP
  Pino 2 (VM)  ──► CJ125 pino VM
  Pino 3 (IPN) ──► CJ125 pino IPN
  Pino 4 (Htrin) ──► CJ125 saída aquecedor
  Pino 5 (Vs)  ──► CJ125 pino VS
  Pino 6 (UN)  ──► CJ125 pino UN

CJ125 saída analógica (0–5V = AFR 10–20) ──► Speeduino A4
CJ125 VCC ──► +12V
CJ125 GND ──► GND
```

### Divisor Resistivo para Tensão da Bateria

```
Bateria 12V (+) ──► R1 (10kΩ) ──┬──► Speeduino A5
                                 │
                              R2 (3,3kΩ)
                                 │
                                GND

Fator: Vout = Vbat × (3,3 / 13,3) → calibrar no TunerStudio
Range: 0–5V representa 0–20,15V da bateria
```

### Conexão ESP32 ↔ Speeduino

```
Speeduino TX (D18/Serial1 TX) ──► Resistor 1kΩ ──► ESP32 GPIO16 (RX)
ESP32 GPIO17 (TX) ──────────────────────────────► Speeduino RX (D19)

GND Speeduino ──► GND ESP32

Nota: Speeduino opera em 5V, ESP32 em 3.3V.
O resistor 1kΩ + divisor ou level shifter 5V→3.3V é necessário no TX do Speeduino.
Alternativa: usar divisor resistivo (1kΩ + 2kΩ) para reduzir 5V para 3.3V.
```

## Conector Externo — Sugestão de Harness

Use conector **AMP Superseal 1.5mm** — resistente a água, vibração e temperatura. Disponível em kits de 2 a 12 pinos.

| Conector | Pinos | Funções |
|---|---|---|
| Powertrain A | 6 pinos | +12V RAW, +12V IGN, GND×2, Injetor, Bobina |
| Sensores B | 8 pinos | CPS+/−, TPS sinal/+5V/GND, CLT, IAT, MAP |
| Lambda C | 4 pinos | O2 sinal, O2 aquecedor, GND×2 |
| Atuadores D | 4 pinos | IAC 1/2/3/4 |

## Checklist de Instalação

- [ ] Verificar resistência do injetor (espera-se 12–16Ω)
- [ ] Verificar tipo de sensor CPS (VR indutivo ou Hall effect)
- [ ] Confirmar número de dentes da roda fônica (deve ser 36-1)
- [ ] Confirmar posição do dente ausente com osciloscópio
- [ ] Testar continuidade de todos os fios antes de ligar
- [ ] Verificar isolamento entre trilhas de alta tensão (ignição) e sensores
- [ ] Confirmar GND comum no bloco do motor (estrela de terra)
- [ ] Testar relé da bomba de combustível separadamente
- [ ] Verificar tensão de saída do MAP (deve ser ~4,5V no ar livre)
- [ ] Verificar TPS: ~0,4V fechado, ~4,6V aberto
