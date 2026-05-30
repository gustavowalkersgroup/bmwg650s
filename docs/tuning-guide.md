# Guia de Calibração — BMW F650GS com Speeduino

## Pré-requisitos

- Speeduino configurado e comunicando com TunerStudio
- ESP32 carregado e conectado ao app
- Wideband O2 instalada e calibrada
- Bateria em bom estado (>12,4V)
- Motor mecanicamente em bom estado (compressão verificada)

## Fase 1 — Configuração Inicial no TunerStudio

### 1.1 Configuração do Trigger (Roda Fônica)

```
Engine → Trigger Setup:
  - Trigger Pattern: Missing Tooth
  - Trigger Angle/Offset: 54° (verificar com pistola estroboscópica)
  - Teeth Before Missing: 35
  - Missing Teeth: 1
  - Trigger Edge: Falling (sensor VR indutivo)
  - Trigger Filter: Level 1
  - Re-sync Cranking: Enable
```

> **Verificação**: Com a moto na ignição (não partida), vire o motor manualmente e observe no TunerStudio se o RPM aparece e o sync light acende.

### 1.2 Configuração do Motor

```
Engine → Engine Constants:
  - Number of Cylinders: 1
  - Engine Stroke: 4-stroke
  - Injection Type: Sequential
  - Number of Injectors: 1
  - Injector Staging: None
  - Engine Displacement: 654cc
  - Injector Flow Rate: 270 cc/min (ajustar após medição)
  - Req Fuel: calculado automaticamente
```

### 1.3 Calibração do TPS

```
Sensors → TPS Calibration:
  1. Com acelerador fechado → clique "Get Current ADC" para TPS Closed
  2. Com acelerador totalmente aberto → "Get Current ADC" para TPS Open
  3. Mover acelerador lentamente: verificar que % sobe linearmente
```

Valores típicos:
- Fechado: ~100–150 ADC (0,3–0,5V)
- Aberto: ~880–950 ADC (4,3–4,7V)

### 1.4 Calibração dos Sensores de Temperatura

```
Sensors → Calibration → CLT / IAT:
  - Tipo: GM IAT (curva padrão para NTC Bosch)
  - Ou inserir tabela manual: 3 pontos (gelo 0°C, ambiente 25°C, ebulição 100°C)
  
  Resistências típicas do sensor Bosch:
    0°C = 5800Ω
   25°C = 2500Ω
   50°C = 900Ω
   80°C = 300Ω
  100°C = 180Ω
```

### 1.5 Configuração MAP

```
Sensors → MAP Sensor:
  - Sensor Type: MPX4250
  - Calibration: Linear, 10–250 kPa
  
  Verificação: Com motor desligado = pressão atmosférica local (~95–101 kPa)
  Com motor em marcha lenta = ~30–50 kPa (vácuo de admissão)
```

### 1.6 Configuração da Ignição

```
Ignition Settings:
  - Spark Mode: Wasted Spark (faísca desperdiçada)
  - Fixed Advance: DISABLE (usar mapa)
  - Cranking Advance: 5°
  - Spark Output: Going Low (pull-down)
  - Dwell Time: 3,5ms (típico para bobina indutiva de moto)
```

## Fase 2 — Mapa Base (VE Table e Ignition Table)

### 2.1 Tabela VE (Eficiência Volumétrica) — Mapa Inicial

A tabela VE 16×16 mapeia RPM × MAP (carga). Valores iniciais conservadores para F650GS:

```
RPM:    500  1000 1500 2000 2500 3000 3500 4000 4500 5000 5500 6000 6500 7000 7500 8000
MAP kPa:
 10     20   22   25   28   30   30   30   30   30   30   30   30   30   30   30   30
 20     30   35   38   40   42   42   42   40   40   38   38   35   35   33   30   30
 30     38   42   46   50   54   55   55   54   52   50   48   46   44   40   38   35
 40     45   50   55   60   65   68   70   70   68   65   62   58   55   50   46   42
 50     52   58   64   70   75   78   80   82   80   78   75   70   66   60   55   50
 60     58   65   72   78   82   86   88   90   90   88   84   80   75   70   64   58
 70     63   70   78   84   88   92   95   97   97   95   90   86   80   74   68   62
 80     67   74   82   88   93   97  100  102  102  100   96   90   84   78   72   65
 90     70   78   86   92   97  101  104  106  106  104  100   94   88   82   75   68
100     72   80   88   95  100  104  107  109  109  107  103   97   90   84   77   70
```

> **Nota**: Esses valores são um ponto de partida. A calibração final exige ajuste com wideband O2 para atingir AFR alvo.

### 2.2 Tabela de Avanço de Ignição — Mapa Inicial

```
RPM:    500  1000 1500 2000 2500 3000 3500 4000 4500 5000 5500 6000 6500 7000 7500 8000
MAP kPa:
 10       5    8   10   12   15   18   20   22   24   25   25   24   23   22   20   18
 20       5   10   12   14   18   22   25   27   28   29   29   28   26   24   22   20
 30       5   10   13   16   20   24   27   30   31   32   32   31   29   27   24   22
 40       5   10   13   16   20   25   28   31   33   34   33   32   30   28   25   22
 50       5    8   12   15   18   22   26   28   30   31   31   30   28   26   23   20
 60       5    7   10   13   16   19   22   24   26   27   27   26   25   23   20   18
 70       5    6    8   10   13   15   18   20   21   22   22   21   20   18   16   14
 80       5    5    7    9   11   13   15   17   18   19   19   18   17   15   13   12
 90       5    5    6    8    9   11   13   14   15   16   16   15   14   12   11   10
100       5    5    5    7    8    9   11   12   13   13   13   12   11   10    9    8
```

> **Atenção**: Valores conservadores para evitar detonação. A F650GS tem taxa de compressão 11,5:1 — sensível a avanço excessivo com gasolina comum. Use gasolina aditivada (Podium ou V-Power) no início.

## Fase 3 — Configuração de Marcha Lenta

```
Idle Settings:
  - Idle Control: Closed Loop (com sensor CLT)
  - Target RPM at 20°C: 1500 RPM
  - Target RPM at 80°C: 1250 RPM
  - IAC Type: Stepper Motor (se IAC original)
  - Stepper Home: 200 passos
  - Stepper Idle Step: ajustar até RPM target
```

## Fase 4 — Primeira Partida

### Checklist antes de ligar:

- [ ] Verificar que não há vazamento de combustível na bancada
- [ ] Confirmar pressão de combustível (manômetro no rail): ~3 bar
- [ ] Confirmar que a bomba prime ao ligar a chave (deve funcionar 2s)
- [ ] Confirmar comunicação TunerStudio → ECU (indicador online)
- [ ] RPM mostrando leitura coerente ao girar motor na mão (sem partida)
- [ ] MAP mostrando ~100 kPa com motor parado
- [ ] CLT mostrando temperatura ambiente
- [ ] AFR wideband em standby (não aquecida)

### Procedimento de partida:

1. Ligar a chave — aguardar prime da bomba
2. Acionar o motor de partida brevemente (2–3s)
3. Se não partir: verificar spark test (LED no Speeduino deve piscar com a ignição)
4. Se partir: manter RPM manualmente com o acelerador até aquecer (~1 min)
5. Observar AFR: deve ficar entre 12–15 nos primeiros minutos
6. Observar CLT: deve subir gradualmente
7. Se AFR > 16 (muito pobre): aumentar req_fuel ou VE geral
8. Se AFR < 11 (muito rico): diminuir req_fuel ou VE geral

## Fase 5 — Ajuste Fino em Estrada (Road Tuning)

### Método AutoTune (TunerStudio + MLV):

1. Habilitar VE Analyze Live no TunerStudio
2. Sair em estrada em rodovias (tráfego leve)
3. Percorrer toda a faixa de RPM e carga (acelerar, cruzeiro, desacelerar)
4. O AutoTune ajusta automaticamente a tabela VE para target AFR = 14,7 (estequiométrico)
5. Para WOT (aceleração total): target AFR = 12,5–13,0 (rico por segurança)

### AFR Alvo por Condição:

| Condição | AFR Alvo | Lambda |
|---|---|---|
| Partida fria | 10–12 | 0,68–0,82 |
| Aquecimento | 12–13 | 0,82–0,89 |
| Marcha lenta quente | 14,5–15,0 | 0,99–1,02 |
| Cruzeiro parcial | 14,5–15,5 | 0,99–1,06 |
| Aceleração moderada | 13,0–14,0 | 0,89–0,96 |
| WOT (pleno) | 12,5–13,2 | 0,85–0,90 |
| Desaceleração | corte de injeção | — |

## Fase 6 — Diagnóstico de Problemas Comuns

| Sintoma | Causa Provável | Solução |
|---|---|---|
| Não sincroniza (no RPM) | Offset do trigger errado | Ajustar trigger angle |
| Partida difícil | Req_fuel muito errado | Ajustar +/- 20% e testar |
| Falha em alta RPM | Filtro do trigger muito agressivo | Reduzir filtro level |
| Marcha lenta instável | IAC mal calibrado / vácuo na admissão | Calibrar IAC steps |
| AFR oscila muito | Sonda O2 ruim ou cabo de interferência | Verificar cabo blindado |
| Detonação (batida) | Avanço excessivo | Recuar avanço em 2–5° |
| Temperatura não sobe | Curva CLT errada | Recalibrar NTC |
