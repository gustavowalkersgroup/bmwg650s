# Nível de Combustível Virtual + IMU — BMW F650GS

A F650GS **não tem boia de combustível** — só uma chave que acende a luz
de reserva. Este documento descreve como contornar isso com um **medidor
virtual** (calculado pela injeção) e o uso do **IMU** (inclinação + queda).

---

## 1. O problema: sem boia, só luz de reserva

A F650GS tem apenas um **interruptor de baixo nível** no tanque (acende a
luz quando entra na reserva, ~4L restantes). Não há sensor de nível
contínuo, então o painel original não mostra quanto resta.

### Três formas de resolver

| Abordagem | Prós | Contras |
|---|---|---|
| **A. Medidor virtual (injeção)** | sem peça nova; preciso; dá autonomia e km/l | precisa zerar ao abastecer |
| B. Instalar boia resistiva | leitura física direta | difícil no tanque da GS; furar tanque |
| C. Só usar a chave de reserva | simples | binário (cheio/reserva), sem nível |

**Escolhido: A + C combinados.** O virtual dá o nível contínuo; a chave de
reserva original serve de **âncora de calibração** para corrigir erro
acumulado.

---

## 2. Medidor virtual — como funciona

Como a ECU controla a injeção, sabemos **exatamente** quanto combustível
foi injetado. Basta integrar ao longo do tempo:

```
Volume por injeção (cc) = largura_pulso(ms) × (vazão_injetor / 60000)

Injeções por minuto (4 tempos, sequencial) = RPM / 2

Volume no intervalo dt = (RPM/2) × (dt/60000) × pw_ms × (cc_min/60000... )
```

O ESP32 acumula o volume consumido (`fuel_tracker.cpp`), subtrai da
capacidade do tanque e converte em **% de nível** + **autonomia** + **km/l**.

### Parâmetros (em `config.h`)
```c
FUEL_INJECTOR_CCMIN  270.0   // vazão do injetor (cc/min @ 3 bar)
FUEL_TANK_LITERS     17.3    // capacidade do tanque F650GS
FUEL_RESERVE_LITERS  4.0     // nível em que a reserva acende
```

> Se trocar o injetor (ex: para E100), **atualize `FUEL_INJECTOR_CCMIN`** —
> o cálculo depende diretamente da vazão.

### Persistência
O nível consumido é salvo na **flash (NVS)** a cada 60s, então sobrevive a
desligar a moto. Ao religar, continua de onde parou.

### Autocalibração pela reserva
Quando a **chave de reserva original** acende, o firmware sabe que restam
~4L. Se o virtual divergiu (acumulou erro), ele se **recalibra
automaticamente** para 4L naquele momento. Erro nunca se acumula sem limite.

### Reabastecimento
Ao encher o tanque, você toca **"Tanque cheio"** no app → comando BLE
`0x01` → o ESP32 zera o consumo e assume tanque cheio. Também dá para
informar litros parciais (comando `0x03`).

---

## 3. Ligação da chave de reserva

```
Chave de reserva original (no tanque)
  Um terminal ──► GND
  Outro terminal ──► ESP32 GPIO23 (INPUT_PULLUP)

Reserva ativa = pino em LOW (FUEL_RESERVE_SW_ACTIVE)
```

A chave continua acendendo a **luz original** no painel normalmente; só
grampeamos o sinal em paralelo para o ESP32 também enxergar.

---

## 4. IMU (MPU6050) — inclinação e detecção de queda

Um sensor de R$15 (MPU6050, I2C) adiciona dois recursos valiosos:

### 4.1 Ângulo de inclinação (lean angle)
- Filtro complementar funde acelerômetro + giroscópio → ângulo lateral
- Mostrado no dashboard (campo **INCL**)
- Base para **cornering traction control** futuro (reduz limiar de
  patinagem em curva, igual às motos de fábrica)

### 4.2 Detecção de queda → corte da bomba
- Se a inclinação passar de **62°** por mais de **1,5s**, é queda
- O ESP32 **corta o relé da bomba de combustível** (GPIO13) →
  segurança anti-incêndio, igual ao sensor de tombamento de fábrica
- O app mostra alarme **"QUEDA DETECTADA — BOMBA CORTADA"**
- Após levantar a moto, o piloto toca **"Limpar"** no app (comando BLE
  `0x02`) e a bomba é religada

### Ligação do IMU
```
MPU6050        ESP32
  VCC   ──────► 3V3
  GND   ──────► GND
  SDA   ──────► GPIO21 (I2C SDA)
  SCL   ──────► GPIO22 (I2C SCL)
  AD0   ──────► GND (endereço 0x68)
```

> **Montagem:** fixe o sensor rígido ao chassi, com os eixos alinhados.
> Use `IMU_MOUNT_OFFSET_DEG` no `config.h` para compensar se ele não ficar
> perfeitamente nivelado. Filtre vibração via DLPF (já configurado a ~44Hz).

---

## 5. Dados novos no app

A linha 3 do dashboard passa a mostrar:

| Campo | Significado |
|---|---|
| **COMB** | nível de combustível virtual (%) — laranja na reserva |
| **AUTON** | autonomia estimada (km) = litros × km/l atual |
| **CONS** | consumo instantâneo (km/l) |
| **INCL** | ângulo de inclinação (graus) — laranja acima de 45° |

E os comandos BLE do app:

| Comando | Código | Ação |
|---|---|---|
| Tanque cheio | `0x01` | zera consumo (após abastecer) |
| Limpar queda | `0x02` | religa bomba após queda |
| Definir litros | `0x03` + byte | calibração manual (litros ×10) |

---

## 6. Pinos usados (resumo)

| Função | GPIO ESP32 |
|---|---|
| IMU I2C SDA | 21 |
| IMU I2C SCL | 22 |
| Chave de reserva | 23 |
| Corte da bomba (queda) | 13 |

> Esses pinos foram escolhidos para não conflitar com os já usados
> (óleo ADC 34, UART 16/17, sensores de roda 35/32, relé ABS 26, etc).
> Confira o mapa completo de pinos no `config.h`.
