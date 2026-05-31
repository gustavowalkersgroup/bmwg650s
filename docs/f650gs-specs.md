# BMW F650GS 2001 — Especificações Técnicas

## Motor

| Parâmetro | Valor |
|---|---|
| Fabricante | Rotax (Austria) |
| Cilindrada | 654cc |
| Configuração | Monocilíndrico, 4 tempos |
| Válvulas | 4 válvulas, SOHC |
| Diâmetro × curso | 100mm × 83mm |
| Taxa de compressão | 11,5:1 |
| Potência máx. | 50cv @ 6500 RPM |
| Torque máx. | 60Nm @ 5000 RPM |
| RPM de marcha lenta | 1200–1400 RPM |
| RPM de corte (limiter) | ~7500 RPM |

## Sistema de Combustível

| Parâmetro | Valor |
|---|---|
| Sistema | Injeção eletrônica multiponto (EFI) |
| ECU original | BMW BMS-C (Bosch Motronic MA 2.4) |
| Número de injetores | 1 (injeção sequencial) |
| Tipo do injetor | Bosch EV1 |
| Impedância do injetor | Alta impedância: 12–16 Ω |
| Fluxo do injetor | ~270–300cc/min @ 3 bar |
| Pressão de combustível | 3,0 bar (regulador de pressão) |
| Bomba de combustível | Elétrica, submersível no tanque |

## Sistema de Ignição

| Parâmetro | Valor |
|---|---|
| Tipo | Bobina indutiva, faísca desperdiçada |
| Velas | NGK DCPR8E (gap: 0,7–0,8mm) |
| Avanço em marcha lenta | ~5° APMS (BTDC) |
| Avanço máximo | ~35° APMS @ 5000+ RPM |
| Controle de avanço | Mapa RPM × Carga (MAP) |

## Sensores

### Sensor de Posição do Virabrequim (CPS)
- **Tipo**: Sensor de relutância variável (VR / indutivo)
- **Roda fônica**: 36-1 dentes (35 dentes + 1 ausente) no virabrequim
- **Referência**: Dente ausente = 54° APMS antes do PMS (a verificar com osciloscópio)
- **Resistência**: ~800–1200Ω entre os terminais

### Sensor TPS (Posição do Acelerador)
- **Tipo**: Potenciômetro resistivo
- **Sinal**: 0–5V (0% fechado ≈ 0,3–0,5V / 100% aberto ≈ 4,5–4,7V)
- **Alimentação**: 5V referência da ECU
- **Conector**: 3 pinos (GND, sinal, +5V)

### Sensor de Temperatura do Líquido de Arrefecimento (CLT)
- **Tipo**: NTC termistor
- **Resistência**: ~2500Ω @ 25°C / ~300Ω @ 80°C / ~150Ω @ 100°C
- **Tensão de referência**: 5V pull-up com resistor de 2,49kΩ
- **Localização**: Cabeçote, próximo ao termostato

### Sensor de Temperatura do Ar de Admissão (IAT)
- **Tipo**: NTC termistor (mesma curva do CLT)
- **Localização**: Caixa de ar / airbox
- **Conector**: 2 pinos

### Sensor MAP (Pressão Absoluta do Coletor)
- **Tipo**: Sensor de pressão piezoresistivo
- **Faixa de leitura**: 10–250 kPa (vácuo a pressão atmosférica)
- **Sinal de saída**: 0,2–4,9V analógico
- **Alimentação**: 5V
- **Substituto recomendado**: MPX4250AP (Freescale/NXP) ou BMP280 (I2C)

### Sonda Lambda / O2
- **Tipo original**: Bosch banda estreita (narrowband) — LSM11
- **Saída original**: 0,1–0,9V (rica/pobre)
- **Upgrade recomendado**: Bosch wideband LSU 4.9 com controlador CJ125
  - Saída: AFR 10–20 (ou Lambda 0,65–1,35) via sinal analógico

### Sonda Lambda Original (Narrowband)
- **Tipo**: Bosch LSM11 — narrowband (banda estreita)
- **Saída**: 0,1–0,9V — sinal binário rico/pobre em torno de λ=1 (14,7 AFR)
- **Limitação**: não indica o AFR real fora da faixa estequiométrica
- **Uso com nova ECU**: mantida para controle de malha fechada no cruzeiro; **não** substitui wideband para calibração inicial
- **Upgrade recomendado**: substituir por Bosch LSU 4.9 + controlador (CJ125 DIY ou Spartan 3)

### Sensor de Knock (Detonação)
- **Tipo**: Sensor piezo de knock — Bosch tipo plano (Flat Type)
- **Referência**: Bosch 0 261 231 006 ou similar M8
- **Localização**: bloco do motor, lado esquerdo, abaixo da cabeça de cilindro
- **Saída**: sinal de vibração ~5–15 kHz (ressonância de detonação)
- **Conexão**: Speeduino pino KNOCK (entrada analógica com filtro passa-banda interno)
- **Função na ECU**: Speeduino detecta detonação e retarda avanço automaticamente (knock retard)

### Sensor de Pressão de Óleo
- **Tipo recomendado**: Sender analógico 0–10 bar, saída 0,5–4,5V, rosca 1/8" NPT
- **Tipo original (BMW)**: chave on/off (apenas alarme de nível baixo) — não dá leitura em bar
- **Localização**: galeria de óleo no bloco (tampa ou conexão T na saída do filtro)
- **Conexão**: sensor analógico → divisor resistivo ÷2 → **ESP32 GPIO34** (ADC)
- **Rosca**: M10×1,0 (comum em motos) ou 1/8" NPT com adaptador

### Sensor VSS (Velocidade)
- **Tipo original**: sensor Hall no pinhão da roda dianteira (cabo velocímetro → transmissor eletromag.)
- **Alternativa**: sensor Hall na roda traseira (se equipada com ABS)
- **Saída**: sinal digital pulsante — pulsos por revolução da roda
- **Conexão**: Speeduino pino VSS (entrada digital)
- **Configuração**: circunferência da roda + pulsos por revolução → TunerStudio

### Sensor IAC (Controle de Marcha Lenta)
- **Tipo**: Válvula de passo (stepper motor), 4 fios
- **Passos**: 0–255 passos
- **Função**: Controla ar de by-pass para manter RPM de marcha lenta estável

## Pinagem do Conector ECU (BMW BMS-C)

> **Nota**: A BMW usa conector Molex Multi-lock de 35 pinos. Verificar com multímetro antes de conectar nova ECU.

| Pino | Função | Tipo |
|---|---|---|
| A1 | +12V permanente (KL30) | Alimentação |
| A2 | +12V chave (KL15) | Alimentação |
| A3 | GND motor | Terra |
| A4 | GND sensor | Terra analógico |
| B1 | CPS+ (sinal) | Entrada analógica VR |
| B2 | CPS− (referência) | Entrada analógica VR |
| B3 | TPS sinal | Entrada analógica 0–5V |
| B4 | TPS +5V ref | Saída 5V |
| B5 | TPS GND | Terra sensor |
| B6 | CLT sinal | Entrada analógica NTC |
| B7 | IAT sinal | Entrada analógica NTC |
| B8 | MAP sinal | Entrada analógica |
| B9 | MAP +5V | Saída 5V |
| C1 | O2 sinal | Entrada analógica 0–1V |
| C2 | O2 aquecedor+ | Saída PWM |
| D1 | Injetor− (gatilho) | Saída low-side |
| D2 | Injetor+ | +12V (relé bomba) |
| D3 | Bobina ignição− | Saída low-side |
| D4 | Bomba combust. relé | Saída digital |
| D5 | IAC pino 1 | Saída stepper |
| D6 | IAC pino 2 | Saída stepper |
| D7 | IAC pino 3 | Saída stepper |
| D8 | IAC pino 4 | Saída stepper |

> **Referência cruzada**: Confirmar pinagem com diagrama elétrico do manual de serviço BMW F650GS 2001 (Part# 01 59 9 798 xxx).
