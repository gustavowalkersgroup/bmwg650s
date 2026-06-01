# Lista de Materiais (BOM) — ECU DIY BMW F650GS

## Sensores Adicionais (Knock + Óleo + VSS)

| # | Componente | Especificação | Qtd | Preço Est. (R$) | Onde Comprar |
|---|---|---|---|---|---|
| A1 | Sensor de knock | Bosch 0 261 231 006 (M8, plano) | 1 | 30–50 | Autopeças, Mercado Livre |
| A2 | Sender pressão de óleo | 0–10 bar, 0,5–4,5V, 1/8" NPT | 1 | 35–60 | AliExpress, autopeças |
| A3 | Adaptador rosca óleo | M10×1,0 fêmea → 1/8" NPT macho | 1 | 15–25 | Autopeças, AliExpress |
| A4 | Sensor VSS Hall | 3 fios, Hall effect, compatível 5V | 1 | 20–35 | AliExpress (buscar "hall speed sensor motorcycle") |
| A5 | Ímã neodímio 6mm | Para roda fônica VSS se necessário | 4 | 5 | AliExpress |

**Subtotal adicional: ~R$105–175**

## Sensores Opcionais (Flex + IMU + Combustível Virtual)

| # | Componente | Especificação | Qtd | Preço Est. (R$) | Onde Comprar |
|---|---|---|---|---|---|
| B1 | Sensor flex | GM 13577429 / Continental flex fuel | 1 | 60–120 | Mercado Livre, autopeças |
| B2 | IMU MPU6050 | Acelerômetro+giroscópio, I2C | 1 | 12–20 | AliExpress, FilipeFlop |
| B3 | Relé bomba (corte na queda) | 12V com socket | 1 | 12 | Autopeças |
| B4 | Injetor maior (só E100) | 350–400 cc/min, alta impedância | 1 | 60–90 | opcional, p/ etanol puro |

**Subtotal opcional: ~R$84–242**

> **Combustível virtual**: não precisa de peça nova — usa a injeção já
> existente + a chave de reserva original. Custo R$0.
> Ver `docs/fuel-level-and-imu.md`.

> **Sobre o O2 original (narrowband)**: A F650GS 2001 tem apenas sensor de banda estreita (Bosch LSM11) no escapamento — saída 0,1–0,9V, serve só para malha fechada em cruzeiro (14,7 AFR). Para calibrar a ECU em toda a faixa é **obrigatório** substituir por wideband (já listado abaixo como item 6).

## Componentes Principais

| # | Componente | Especificação | Qtd | Preço Est. (R$) | Onde Comprar |
|---|---|---|---|---|---|
| 1 | Arduino Mega 2560 | Clone ou original | 1 | 60–90 | Mercado Livre, FilipeFlop |
| 2 | Speeduino Shield v0.4.4c | Kit ou montado | 1 | 150–300 | speeduino.com, AliExpress |
| 3 | ESP32-WROOM-32 DevKit | 38 pinos | 1 | 35–50 | FilipeFlop, RoboCore |
| 4 | Sensor MAP MPX4250AP | 0–250 kPa, SOP-8 | 1 | 40–60 | Mouser, DigiKey |
| 5 | Controlador wideband CJ125 | Kit PCB | 1 | 80–150 | AliExpress, DIYAutotune |
| 6 | Sonda lambda LSU 4.9 | Bosch 0 258 017 025 | 1 | 120–200 | Autoparts, Mouser |

## Componentes Eletrônicos

| # | Componente | Especificação | Qtd | Preço Est. (R$) |
|---|---|---|---|---|
| 7 | MOSFET IRFZ44N | N-channel, TO-220 | 2 | 5 |
| 8 | Transistor BIP373 | Transistor ignição | 1 | 10 |
| 9 | Diodo TVS P6KE18A | Proteção bobina | 2 | 5 |
| 10 | Diodo 1N4007 | Flyback | 4 | 3 |
| 11 | Resistor 150Ω, 1/4W | Gate MOSFET | 4 | 2 |
| 12 | Resistor 2,49kΩ 1% | Pull-up CLT/IAT | 2 | 2 |
| 13 | Resistor 10kΩ, 1/4W | Div. tensão bateria | 2 | 2 |
| 14 | Resistor 3,3kΩ, 1/4W | Div. tensão bateria | 1 | 1 |
| 15 | Resistor 1kΩ, 1/4W | Level shift UART | 2 | 1 |
| 16 | Capacitor 100nF, cerâmico | Desacoplamento | 10 | 5 |
| 17 | Capacitor 100µF, 25V, eletrolítico | Filtragem | 2 | 4 |
| 18 | Regulador 7805 | 5V, TO-220 | 1 | 5 |
| 19 | Level shifter 5V↔3.3V | 4 canais bidirecional | 1 | 8 |

## Conectores e Cabeamento

| # | Componente | Especificação | Qtd | Preço Est. (R$) |
|---|---|---|---|---|
| 20 | Kit conector AMP Superseal | 2–12 pinos, com terminais | 4 kits | 80–120 |
| 21 | Fio automotivo 0,5mm² | Cores diversas, rolo 10m | 5 | 80 |
| 22 | Fio automotivo 1,5mm² | Para alimentação | 2 | 30 |
| 23 | Manga termorretrátil | 3mm e 6mm | 1 kit | 15 |
| 24 | Fita isolante automotiva | Rolo | 1 | 10 |
| 25 | Terminais pino fêmea/macho | Kit 200 peças | 1 | 25 |

## Proteção e Montagem

| # | Componente | Especificação | Qtd | Preço Est. (R$) |
|---|---|---|---|---|
| 26 | Caixa estanque IP65 | 150×100×70mm, ABS | 1 | 35–50 |
| 27 | Relé automotivo 12V 30A | Com socket | 3 | 25 |
| 28 | Porta-fusível inline 15A | Para proteção dos circuitos | 4 | 20 |
| 29 | Fusível 15A | Lâmina ATO | 10 | 10 |
| 30 | Fusível 30A | Lâmina MAXI | 2 | 8 |
| 31 | Barra de GND (estrela terra) | Barramento de aterramento | 1 | 15 |
| 32 | Espaçadores M3 | Nylon, para montar PCB na caixa | 8 | 5 |
| 33 | Calço de silicone | Vedação passagem de fios | 1 | 10 |

## Ferramentas Necessárias

| Ferramenta | Uso |
|---|---|
| Multímetro | Verificação de tensões e resistências |
| Osciloscópio (ou app + sonda USB) | Verificar sinal CPS, pulso injetor |
| Crimpador AMP Superseal | Para terminais do conector |
| Ferro de solda | Montagem da PCB |
| Notebook com TunerStudio | Calibração e mapeamento |
| Pistola estroboscópica | Verificar avanço de ignição |
| Computador com Android/iOS | Para o app Flutter |

## Custo Total Estimado

| Categoria | Mínimo (R$) | Máximo (R$) |
|---|---|---|
| Sensores adicionais (knock, óleo, VSS) | 105 | 175 |
| Componentes principais | 445 | 800 |
| Eletrônicos | 53 | 53 |
| Conectores e cabeamento | 240 | 280 |
| Proteção e montagem | 128 | 143 |
| **TOTAL** | **971** | **1.451** |

> **Comparativo**: ECU original BMW BMS-C usada: R$800–2.000 (sem garantia, sem possibilidade de mapeamento).

## Alternativas de Custo Menor

### Opção Budget (~R$500):
- Substituir Speeduino shield por montagem manual em protoboard/perfboard
- Usar sensor MAP BMP280 via I2C (R$15 vs R$60 do MPX4250)
- Manter sonda lambda original narrowband (sem wideband — limitação no mapeamento)
- Caixa feita em chapa de alumínio dobrada

### Opção Premium (~R$1.500+):
- Speeduino v0.4 pré-montado e testado (DIYAutotune.com, ~$90 USD)
- Wideband completo com gauge físico (Innovate LC-2, ~$150 USD)
- Conector OEM BMW recuperado do próprio chicote
- Impressão 3D para suporte da ECU no alojamento original
