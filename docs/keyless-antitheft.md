# Keyless + Anti-Furto — BMW F650GS

Como tirar a chave física da moto e deixá-la 100% digital, controlada pelo
celular via BLE, com várias camadas anti-furto.

---

## 1. Princípio: separar as fontes de energia

O segredo de um keyless seguro é **o microcontrolador nunca desligar** e ele
controlar a energia de tudo o mais.

| Barramento | O que alimenta | Quando |
|---|---|---|
| **KL30** (bateria direta) | só o ESP32 (~2 mA em standby) | sempre |
| **KL15** (via relé do ESP32) | Speeduino, bomba, bobina, instrumentos, arranque | só quando autorizado |

```
Bateria +12V
   ├── KL30 ────────────────► ESP32 (sempre ligado, BLE escutando)
   │                              │ controla
   └── KL15 ◄── [Relé NA] ◄───────┘ GPIO19
                  │
                  ├──► Speeduino (ECU)
                  ├──► Bomba de combustível
                  ├──► Bobina de ignição
                  ├──► Relé do arranque
                  └──► Instrumentos
```

Sem o celular autorizado por perto, o relé KL15 fica **aberto** — a moto está
eletricamente morta. Não dá para dar partida nem por *hotwire* simples.

---

## 2. Fluxo de uso (dia a dia)

```
1. Você chega perto da moto com o celular
2. BLE conecta automaticamente → app mostra botão verde "LIGAR"
3. Toca em LIGAR → ESP32 fecha a KL15 → painel acende
4. Toca no botão vermelho de partida → motor pega
5. Anda normalmente
6. Ao chegar: toca no ícone de power (desligar) → motor para, KL15 abre
7. Se esquecer de desligar: após 30s longe (sem BLE, motor parado),
   o ESP32 corta a KL15 sozinho (auto-lock)
```

---

## 3. Como desligar o motor

Desligar = **abrir o relé KL15**, exatamente como a chave fazia ao ir para
"OFF". Isso corta ignição + injeção + bomba de uma vez. Três caminhos:

| Forma | Gatilho | Observação |
|---|---|---|
| **Manual** | ícone de power no app | confirma se o motor estiver ligado |
| **Auto-lock** | 30s sem BLE com motor parado | bloqueia a moto sozinha |
| **Botão físico** | botão oculto no quadro | só emergência (celular sem bateria) |

> Por que **não** usar um botão cortando corrente como desligamento normal?
> Porque obriga acesso físico sempre e vira um ponto óbvio para o ladrão
> achar e neutralizar. O corte lógico (decidido pelo ESP32) é mais seguro;
> o botão fica só como plano B escondido.

---

## 4. Camadas anti-furto (defesa em profundidade)

São **dois relés independentes em série** no caminho de funcionamento:

1. **Relé KL15 (GPIO19)** — sem celular, nem energiza a moto
2. **Relé de corte da bomba (GPIO13)** — o imobilizador também corta a bomba

Para furtar com *hotwire*, o ladrão teria que **achar e jumpear os dois**,
em locais diferentes do chicote, sem saber que existem. Camadas:

| Camada | O que faz | Burlar exige |
|---|---|---|
| KL15 keyless | moto inerte sem celular | achar e jumpear o relé KL15 |
| Imobilizador BLE | corta bomba se o celular sumir rodando | achar e jumpear o relé da bomba |
| Corte por queda (IMU) | corta bomba se a moto tomba | — (segurança, não anti-furto) |
| Auto-lock | rebloqueia sozinha após 30s | estar com o celular |

> Dica: monte os dois relés em pontos distintos e bem escondidos, com fios
> da mesma cor do chicote. Sem o celular, mesmo com a moto aberta, dar
> partida vira um quebra-cabeça.

---

## 5. Botão físico de emergência (backup)

Celular sem bateria? Um botão momentâneo escondido (GPIO15, ativo em LOW)
faz *toggle* da KL15. Esconda em local discreto (debaixo do banco, dentro
da carenagem) — funciona como uma "chave reserva" secreta.

```
GPIO15 ──[botão]── GND     (pull-up interno; press = liga/desliga KL15)
```

> O GPIO15 é pino de strapping no ESP32. Mantido em HIGH pelo pull-up
> interno (boot normal); pressionar durante o boot apenas silencia o log —
> inofensivo em operação.

---

## 6. Parâmetros (em `config.h`)

```c
KL15_RELAY_PIN     19     // GPIO19 → relé KL15 (normalmente aberto)
KL15_RELAY_LEVEL   HIGH   // HIGH = relé fechado = moto energizada
KL15_AUTOLOCK_S    30     // s sem BLE c/ motor parado → bloqueia

BACKUP_BTN_PIN     15     // botão físico oculto (emergência)
BACKUP_BTN_ACTIVE  LOW
```

Comandos BLE (sincronizados com o app):

| Cmd | Hex | Ação |
|---|---|---|
| CMD_IGNITION_ON  | 0x09 | liga KL15 (energiza a moto) |
| CMD_IGNITION_OFF | 0x0A | desliga KL15 (desliga a moto) |

Bit de status no pacote BLE: `flags2 bit4 = IGNITION_ON`.

---

## 7. Hardware adicional

| Item | Especificação | Custo est. (R$) |
|---|---|---|
| Relé KL15 | 12V 30–40A (corrente de toda a moto) + socket | 15–25 |
| Fusível KL15 | inline conforme consumo total | 8 |
| Botão momentâneo | NA, à prova d'água, discreto | 8–15 |
| Conversor DC-DC p/ ESP32 | 12V→5V eficiente p/ standby baixo | 10–20 |

> ⚠️ O relé KL15 conduz a corrente de **toda a moto**. Dimensione com folga
> (30–40A) e use fusível. Considere um relé de estado sólido se quiser zero
> desgaste de contato.

---

## 8. Cuidados importantes

- **Standby da bateria**: o ESP32 em KL30 consome ~1–3 mA. Em semanas parada,
  isso descarrega. Para uso esporádico, adicione um botão geral (corta KL30)
  ou um modo *deep sleep* com *wake* por BLE/toque.
- **Failsafe**: o relé KL15 é **normalmente aberto** — se o ESP32 travar ou a
  KL30 cair, a moto simplesmente não liga (nunca liga sozinha por falha).
- **Watchdog**: habilite o watchdog do ESP32 para reiniciar em caso de
  travamento, sem deixar a KL15 num estado indefinido.
- **Backup sempre**: tenha o botão físico oculto. Celular quebrou/perdeu =
  você ainda precisa ligar a moto.
