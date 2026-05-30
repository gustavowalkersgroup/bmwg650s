# Condicionamento de Sinal — BMW F650GS ECU DIY

## 1. VR Conditioner (Sensor CPS 36-1)

O sensor de virabrequim da F650GS gera um sinal **senoidal de relutância variável** cuja amplitude vai de ~0,5V em baixo RPM até vários volts em alto RPM. O Arduino não consegue ler diretamente — precisa de condicionamento.

### Circuito Recomendado: MAX9926 (incluso no Speeduino v0.4)

```
Sensor VR+  ──► MAX9926 IN+
Sensor VR−  ──► MAX9926 IN−
             (GND do sensor no bloco do motor)

MAX9926 OUT ──► Arduino Mega ICP1 (D49)
MAX9926 VCC ──► +5V
MAX9926 GND ──► GND
```

O MAX9926 detecta cruzamentos de zero do sinal senoidal e gera um sinal digital limpo de 0/5V. O Speeduino usa Input Capture no Timer1 para medir o período entre pulsos com precisão de 0,5µs.

**Alternativa low-cost**: LM1815 ou circuito com comparador LM393 + histerese.

---

## 2. Level Shifter UART 5V → 3,3V

O Speeduino (Arduino Mega) opera em 5V, o ESP32 em 3,3V. O TX do Mega pode danificar o RX do ESP32.

### Divisor Resistivo Simples (Unidirecional TX Mega → RX ESP32)

```
Mega TX (5V) ──► R1 (1kΩ) ──┬──► ESP32 RX (3,3V)
                              │
                           R2 (2kΩ)
                              │
                             GND

Vtx = 5V × (2kΩ / 3kΩ) = 3,33V ✓
```

O TX do ESP32 (3,3V) é reconhecido como HIGH pelo Mega diretamente (limiar ~2V).

**Alternativa**: Módulo level shifter bidirecional 4 canais (baseado em BSS138) — mais robusto e limpo.

---

## 3. Proteção da Entrada do Injetor e Bobina

### Diodo Flyback (Injetor)

Ao desligar o injetor, a bobina interna gera um pico de tensão reversa (~50–100V) que pode queimar o MOSFET. O diodo flyback absorve esse pico.

```
+12V ──► Injetor (+) ──► Injetor (−) ──► MOSFET Drain
                     │
                  1N4007 (ânodo no Drain, cátodo no +12V)
```

O shield Speeduino v0.4 já inclui esse diodo integrado na PCB.

### Proteção da Bobina de Ignição

A bobina de ignição gera picos de ~300–400V no secundário e ~100V no primário. Usar transistor de ignição dedicado:

```
Speeduino IGN out ──► 150Ω ──► Base do BIP373
                               BIP373 Collector ──► Bobina (−)
                               BIP373 Emitter  ──► GND
                               TVS P6KE18A em paralelo com Coletor-Emissor
```

**Não usar MOSFET convencional para bobina de ignição** sem proteção TVS e snubber.

---

## 4. Filtro RC para Entradas Analógicas

Ruído elétrico em motocicletas é significativo (alternador, ignição). Adicionar filtro RC em cada entrada analógica:

```
Sensor ──► R (470Ω) ──┬──► Pino ADC Arduino
                      │
                    C (100nF a GND)

Fc = 1 / (2π × 470 × 100e-9) ≈ 3,4 kHz

Sinal do motor (DC lento) passa; ruído de RF é filtrado.
```

Importante também: **cabo blindado** para os sensores mais sensíveis (CPS, TPS, MAP). Ligar a blindagem apenas em um lado (no GND da ECU), não nos dois — evita loop de terra.

---

## 5. Proteção da Alimentação da ECU

```
Bateria 12V
    │
 Fusível 30A (MAXI) ──► Relé principal (120A, como Bosch 0 332 209 150)
                              │ (bobina ativada por KL15 via fusível 5A)
                              └──► Barramento +12V dos atuadores (injetor, bomba, bobina)

Bateria 12V ──► Fusível 15A ──► Speeduino +12V RAW
Bateria 12V ──► Fusível 5A  ──► ESP32 via regulador 3,3V
```

Adicionar **capacitor eletrolítico de 1000µF/25V** no barramento +12V da ECU para absorver transientes.

---

## 6. Aterramento (Estrela de Terra)

O aterramento é a parte mais crítica de qualquer sistema ECU.

**Regra**: todos os GNDs de sensores devem convergir em um único ponto de baixa impedância no bloco do motor.

```
GND Speeduino ──┐
GND ESP32    ──┤
GND Sensores ──┤──► Ponto único no bloco (parafuso M6 no bloco do motor)
GND MAP      ──┤
GND Injetor  ──┤
GND Bobina   ──┘
                └──► Cabo 6mm² direto ao negativo da bateria
```

Não usar a carroceria da moto como GND de retorno para sensores — diferença de potencial de terra causa leituras erráticas.

---

## 7. Verificações com Osciloscópio

Antes de ligar o motor pela primeira vez, verificar com osciloscópio:

| Sinal | Esperado |
|---|---|
| CPS (após conditioner) | Onda quadrada 0–5V, período proporcional ao RPM |
| TPS | DC variando suavemente 0,3–4,7V ao virar acelerador |
| MAP | ~0,4V em vácuo total, ~4,5V em pressão atmosférica |
| Saída injetor | Pulso baixo (low-side), largura ~2–8ms conforme RPM |
| Saída ignição | Pulso baixo, dwell ~3,5ms antes do ponto |
| Saída bomba | +12V após ligar chave por 2s, depois pelo MAP |
