# Modos de Pilotagem, ABS e Ride-by-Wire — BMW F650GS

Documento de arquitetura para os recursos avançados do projeto:
controle de tração, desligamento de ABS, modos de pilotagem e
acelerador eletrônico (ride-by-wire).

> **Princípio geral**: tudo que exige timing preciso (ignição, injeção,
> servo RbW) roda em microcontrolador (Speeduino/ESP32). O Raspberry Pi,
> se usado, é **apenas painel/visão** e nunca controla o motor.

---

## 1. ABS — desligamento via relé

### Fato importante
Na F650GS 2001 o **ABS é um módulo independente** (BMW ABS II, FTE/Continental),
totalmente separado da ECU do motor (BMS-C). Trocar a ECU pelo Speeduino
**não dá** controle direto sobre o ABS. O desligamento é feito cortando a
alimentação do módulo ABS com um relé.

### Circuito
```
+12V (KL15, pós-chave)
   │
   ├──► Fusível 10A ──► Relé ABS (NF — normalmente fechado)
   │                        │
   │                   contato ──► +12V do módulo ABS original
   │                        │
   └── bobina do relé ◄── ESP32 GPIO (via transistor/MOSFET driver)

Estado padrão (GPIO LOW): relé NF fechado → ABS LIGADO  ✅ seguro
Modo OFFROAD (GPIO HIGH): relé abre       → ABS DESLIGADO
```

### Regras de segurança
- **Estado padrão = ABS ligado.** Use relé **normalmente fechado** (NF):
  se o ESP32 estiver desligado/travado, o ABS permanece funcionando.
- **Religa sozinho ao dar a partida.** O modo nunca persiste "ABS off"
  entre ignições — sempre volta para ABS ligado ao ligar a moto.
- Fusível dedicado para o circuito do relé.
- A luz de ABS no painel vai acender com ABS desligado — isso é normal.

> ⚠️ Desligar ABS altera o comportamento de frenagem. Use somente fora
> de estrada. Responsabilidade do piloto.

---

## 2. Controle de Tração (TC) usando os sensores do ABS

Os sensores de roda do ABS são Hall effect (3 fios) e já existem nos dois
cubos. O sinal é **grampeado em paralelo** para o ESP32 — alta impedância,
não interfere no módulo ABS original.

```
Sensor roda DIANTEIRA ──┬──► Módulo ABS (intacto)
                        └──► ESP32 GPIO (interrupt)  → conta pulsos

Sensor roda TRASEIRA  ──┬──► Módulo ABS (intacto)
                        └──► ESP32 GPIO (interrupt)  → conta pulsos
```

### Lógica de TC (no ESP32)
```
V_dia  = pulsos_dianteira × constante_roda
V_tra  = pulsos_traseira  × constante_roda
slip   = (V_tra − V_dia) / V_dia      // patinagem da roda motriz

se slip > LIMIAR_DO_MODO:
    ESP32 pulsa o pino de TC do Speeduino → retarda avanço (knock/TC retard)
senão:
    avanço normal
```

O Speeduino tem entrada nativa de traction control; o ESP32 apenas aciona
esse pino quando detecta patinagem além do limiar do modo ativo.

| Modo | Limiar de slip | Comportamento |
|---|---|---|
| ECO | 10% | intervém cedo, prioriza tração |
| SPEED | 20% | deixa girar mais para acelerar |
| OFFROAD | 30% | aceita bastante wheelspin (terra/areia) |
| CRUISE | 15% | conservador para estrada |

> A "constante_roda" (mm por pulso) depende do nº de dentes do anel do ABS
> e da circunferência do pneu. Medir com osciloscópio e calibrar.

---

## 3. Modos de Pilotagem — ECO / SPEED / OFFROAD / CRUISE

### Limitação física (acelerador a cabo)
Enquanto a moto usar **acelerador por cabo**, os modos só podem mudar:
ignição, mapa de combustível, corte de giro, limiar de TC e estado do ABS.
**Não** dá para mudar a "resposta do acelerador" — isso exige ride-by-wire
(seção 4).

### Tabela de parâmetros por modo (fase cabo)
| Parâmetro | ECO | SPEED | OFFROAD | CRUISE |
|---|---|---|---|---|
| Avanço de ignição | suave | agressivo | progressivo baixo | suave |
| Mapa VE (mistura) | magro cruzeiro | potência | potência baixa | magro |
| Corte de giro | 6500 | 7400 | 6000 | 6800 |
| Limiar TC (slip) | 10% | 20% | 30% | 15% |
| ABS | ON | ON | **OFF (relé)** | ON |
| Resposta acelerador | — (cabo) | — | — | — (CRUISE = mapa) |

> **CRUISE nesta fase = apenas um mapa econômico/suave de estrada.**
> Piloto automático de verdade só com RbW (seção 4).

### Como trocar de modo (4 modos)
O Speeduino nativamente troca só entre **2 tabelas**. Para os 4 modos:
- Botões no guidão → **GPIO do ESP32** (com debounce).
- O ESP32 guarda o "modo atual" e, ao trocar, envia comando serial ao
  Speeduino ajustando os parâmetros do modo (avanço, limiter, tabela VE).
- O ESP32 também aciona o **relé do ABS** ao entrar/sair de OFFROAD.
- O **app** mostra o modo ativo e o status do ABS, e também permite trocar
  de modo pelo celular.

```
Botões guidão ──► ESP32 GPIO ──┬──► comando serial → Speeduino (mapa/limiter)
                               ├──► relé ABS (se OFFROAD)
                               └──► BLE → app (mostra modo + ABS)
```

---

## 4. Ride-by-Wire (RbW) — Fase futura

Migrar para acelerador eletrônico transforma os modos em **curvas de
resposta reais** e habilita **cruise control verdadeiro**. Exige refazer
o sistema de acelerador.

### Arquitetura
```
Punho (potenciômetro 0–5V)        Corpo de borboleta
   │ "intenção do piloto"               │
   ▼                                    │
ESP32 ── PID ──► Servo motor ───────────┘
   │                  │
   │               TPS real (fica no lugar; Speeduino lê normal)
   │
   └── curva do modo aplicada aqui
```

### O que muda em cada modo COM RbW
| Modo | Curva punho→borboleta | Cruise |
|---|---|---|
| ECO | 50% punho = 25% borboleta (suave) | — |
| SPEED | linear/agressiva 1:1 | — |
| OFFROAD | muito progressiva em baixa | — |
| CRUISE | mantém velocidade-alvo (fecha com VSS) | ✅ real |

### Hardware mínimo
| Componente | Especificação | Custo est. (R$) |
|---|---|---|
| Potenciômetro do punho | 5kΩ rotativo, eixo 6mm | 20 |
| Servo motor | MG996R (10kg.cm) ou BLDC com encoder | 35–120 |
| Suporte do servo | impressão 3D / usinagem | 30–80 |
| Mola de retorno | fecha borboleta se servo falhar | 10 |

### Segurança RbW — obrigatório
- **Mola de retorno** no corpo de borboleta: se o servo travar/perder
  energia, a mola fecha a borboleta (marcha lenta). Não é opcional.
- **Watchdog no ESP32**: se perder o sinal do punho ou o loop de controle
  travar, força o servo para 0% imediatamente.
- **Dois sensores de posição** (punho e borboleta) com checagem de
  plausibilidade — se divergirem, entra em modo seguro (limp).
- Sem todos esses itens, **não rodar com RbW**.

---

## 5. Resumo das fases

```
FASE 1 (atual): ECU funcional — Speeduino + ESP32 + App ✅
FASE 2:         Sensores ABS → TC + relé ABS + 4 modos (mapas)
FASE 3:         Ride-by-Wire — punho + servo + curvas reais
FASE 4:         CRUISE ativo (fechado com VSS) + refino de TC
```

## 6. Por que NÃO usar Raspberry Pi no controle
O Pi roda Linux (não determinístico): jitter de 1–10ms inviabiliza
ignição/injeção/servo. Microcontrolador (Speeduino/ESP32) roda "no metal"
com timing previsível ao microssegundo. O Pi só serve como **painel/visão
opcional** (tela TFT grande, GPS, câmera, dashcam, logging) — e se travar,
a moto continua rodando porque o controle está no ESP32/Speeduino.
