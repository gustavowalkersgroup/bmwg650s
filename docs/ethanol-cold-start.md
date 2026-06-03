# Partida a Frio com Etanol — BMW F650GS

Etanol não vaporiza bem a frio — esse é o maior desafio de rodar E100 puro.
Este documento explica a física, as soluções e como o projeto trata isso
com **indicador de motor frio** + **aquecedor de admissão** controlado pelo
ESP32.

---

## 1. Por que o etanol não pega a frio

| Propriedade | Gasolina | Etanol | Efeito |
|---|---|---|---|
| Pressão de vapor (kPa @ 38°C) | 45–90 | **~16** | etanol não evapora fácil |
| Calor latente de vaporização | ~350 kJ/kg | **~900 kJ/kg** | rouba muito calor do cilindro |
| Temp. mínima de partida | ~−20°C | **~13–15°C** | abaixo disso, E100 falha |

Abaixo de ~13°C, o etanol líquido injetado **não vira vapor** no cilindro
frio: molha a vela, não inflama e afoga o motor. Por isso carros flex
brasileiros têm "partida a frio".

---

## 2. Soluções possíveis

| Solução | Como | Viável na F650GS? |
|---|---|---|
| **Tanquinho de gasolina** | injeta gasolina só na partida | ❌ sem espaço na moto |
| **Aquecedor de admissão (PTC)** | resistência aquece o ar/combustível | ✅ **melhor opção** |
| **Aquecedor no flange do injetor** | aquece o combustível antes do bico | ✅ alternativa |
| **Só enriquecimento** | mais combustível na partida | ⚠️ só até ~13°C |
| **Bujão de aquecimento (glow)** | aquece a câmara | ⚠️ complexo |

**Escolhido: aquecedor de admissão PTC** (~R$40), controlado pelo ESP32 com
indicação "aguarde" no painel — igual à luz de preaquecimento do diesel.

---

## 3. Como o projeto trata a partida a frio

### Duas camadas de proteção

**Camada 1 — Enriquecimento (Speeduino):**
O Speeduino já aumenta o combustível na partida e no aquecimento
(*priming pulse*, *cranking enrichment*, *afterstart*, *warmup*). Com o
sensor flex, essas correções são **escaladas pelo teor de etanol**
automaticamente — quanto mais etanol, mais enriquecimento a frio.

**Camada 2 — Aquecedor de admissão (ESP32):**
O ESP32 calcula a temperatura mínima confortável de partida em função do
teor de etanol e, se estiver frio demais, **liga o aquecedor PTC** antes da
partida, mostrando uma contagem regressiva no app.

### Temperatura mínima por etanol
Interpolação linear entre os extremos (configurável em `config.h`):
```
E0   (gasolina) → 2°C
E100 (etanol)   → 18°C
E50             → 10°C
```

### Sequência de partida a frio (E100, dia frio)
```
1. Liga a chave
2. ESP32 lê CLT (ex: 8°C) e flex (ex: 100%)
3. 8°C < 18°C → "FRIO PARA ETANOL" + liga aquecedor PTC
4. App mostra "AQUECENDO ADMISSÃO — aguarde 30s"
5. Contagem chega a 0 → "PRONTO" (✓ verde)
6. Dá a partida → motor pega
7. Motor rodando → aquecedor desliga, Speeduino assume o warmup
```

---

## 4. Indicadores no app

### Banner no painel (topo)
| Situação | Cor | Texto |
|---|---|---|
| Aquecendo | laranja | "AQUECENDO ADMISSÃO — aguarde Xs" |
| Frio p/ etanol | laranja escuro | "FRIO PARA ETANOL (X%) — ideal acima de Y°C" |
| Motor frio | azul-cinza | "MOTOR FRIO (X°C) — aguardando aquecimento" |
| Pronto | ✓ verde | (banner some quando aquece) |

### Aba Config → "Partida a Frio"
Mostra estado, temperatura do motor, mínima recomendada para o etanol atual
e status do aquecedor.

---

## 5. Hardware do aquecedor

| Item | Especificação | Custo est. (R$) |
|---|---|---|
| Aquecedor PTC | elemento 12V 100–150W, 40–60°C | 30–50 |
| Relé 12V 20A | aciona o PTC (alta corrente) | 12 |
| Suporte/flange | adapta o PTC ao coletor de admissão | 20–40 |

### Ligação
```
+12V (KL15) ──► Fusível 15A ──► Relé PTC (contato)
                                    │
                               Aquecedor PTC ──► GND

ESP32 GPIO4 ──► bobina do relé (via transistor/MOSFET)
  HIGH = aquecedor ligado (COLDSTART_HEATER_LEVEL)
```

> ⚠️ O PTC puxa corrente alta (até ~12A). **Nunca** ligue direto no GPIO —
> use sempre relé + fusível dedicado.

### Parâmetros (em `config.h`)
```c
COLDSTART_ENABLED        1
COLDSTART_WARMUP_C       60     // abaixo disso, "motor frio"
COLDSTART_E0_MIN_C       2      // mín. gasolina pura
COLDSTART_E100_MIN_C     18     // mín. etanol puro
COLDSTART_HEATER_ENABLED 1
COLDSTART_HEATER_PIN     4      // GPIO4 → relé do PTC
COLDSTART_HEATER_MAX_S   30     // preaquecimento máx. (s)
```

---

## 6. E se eu não instalar o aquecedor?

Funciona em **modo só indicador**: o app avisa "FRIO PARA ETANOL" mas não
preaquece. Nesse caso, as alternativas práticas em dia frio são:

- **Abastecer com um pouco de gasolina** quando souber que vai dar partida
  no frio (a mistura E70–E80 já parte bem mais fácil)
- **Confiar no enriquecimento** do Speeduino (funciona até ~13°C)
- Para desabilitar o aquecedor: `COLDSTART_HEATER_ENABLED 0`

> Como a F650GS roda E27 (gasolina comum brasileira) sem problema de partida
> a frio, o aquecedor só é realmente necessário se você for **abastecer com
> E100 puro** com frequência em região fria.

---

## 7. Resumo

- **Indicador de motor frio**: ✅ implementado (banner + aba Config)
- **Mínimo por etanol**: calculado automaticamente do teor flex
- **Aquecedor PTC**: ✅ controlado pelo ESP32 (opcional, ~R$40)
- **Enriquecimento**: ✅ Speeduino escala pelo teor de etanol
- **Sem aquecedor**: funciona como só-aviso; misturar gasolina resolve no frio
