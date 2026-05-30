# Configuração Speeduino — BMW F650GS

## Passo a Passo no TunerStudio

### Acesso à ECU
1. Conectar USB (Arduino Mega → PC)
2. TunerStudio: **Communications → Connect**
3. Selecionar porta COM correta, 115200 baud

### Aba: Engine Constants
```
Number of Cylinders:     1
Engine Stroke:           Four-Stroke
Firing Order:            1
Injection Type:          Sequential
Number of Injectors:     1
Injector Staging:        None
Engine Displacement:     654 cc
Injector Open Time:      1.0 ms (ajustar depois)
Injector Flow Rate:      270.0 cc/min (verificar na etiqueta do injetor)
```

### Aba: Trigger Setup
```
Primary Trigger:         Missing Tooth
Trigger Pattern:         Missing Tooth
Teeth Total:             36
Missing Teeth:           1
Trigger Angle:           54 (ajustar com estroboscópio)
Trigger Edge:            Falling
Secondary Trigger:       None
Trigger Filter:          Weak
RPM Counter Clock:       Timer1 (Input Capture)
```

### Aba: Ignition Settings
```
Spark Output:            Wasted Spark
Coil Charging:           Going Low (active LOW)
Coil Charge Time:        3.5 ms
Cranking Advance:        5°
Fixed Advance:           Disabled (usar mapa)
```

### Aba: Fuel Settings
```
Injection Mode:          Sequential
Staged Injection:        Disabled
Injection Angle:         355° (injetar durante admissão)
Cranking Pulsewidth:     12 ms
```

### Aba: Idle Control
```
Idle Control Type:       Closed Loop (com CLT)
PWM Frequency:           160 Hz (para IAC tipo stepper)
Idle Steps:              200 (ajustar)
Warm Idle Target:        1250 RPM
Cold Idle Target (20°C): 1500 RPM
```

### Aba: Sensor Calibration
```
Coolant Temp:            GM CLT (curva NTC padrão)
Intake Temp:             GM IAT
TPS:                     Calibrar manualmente (closed/open)
MAP Sensor:              MPX4250 (10–250 kPa)
O2 Sensor:               Wideband (Linear 0–5V → AFR 10–20)
Battery:                 Divisor resistivo 10k/3k3
```

### Aba: Rev Limiter
```
Hard Cut RPM:            7500 RPM
Soft Cut RPM:            7200 RPM
Soft Cut Method:         Fuel Cut
```

### Aba: Warmup Enrichment
```
Coolant Temp (°C) → Enrichment (%):
  -20°C → 120%
    0°C → 100%
   20°C →  70%
   40°C →  40%
   60°C →  20%
   80°C →   0%
```

## Verificações Pós-Configuração

Antes de ligar o motor, verificar no TunerStudio com ignição ligada (sem partida):

- [ ] **Sensor Status** → todos os sensores mostrando valores plausíveis
- [ ] **MAP**: ~100 kPa (pressão atmosférica local)
- [ ] **CLT**: temperatura ambiente (~20–30°C)
- [ ] **IAT**: temperatura ambiente
- [ ] **TPS**: ~0–2% com acelerador fechado
- [ ] **Battery**: ~12–13V
- [ ] **RPM**: 0 (motor parado)

Ao dar a partida brevemente:
- [ ] **RPM** deve aparecer (indica sincronismo com roda fônica)
- [ ] **Sync** deve mostrar verde

## Backup do Tune

Sempre salvar o tune após cada sessão:
**File → Save Tune As** → `f650gs_YYYYMMDD.msq`
