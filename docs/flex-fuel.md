# Flex Fuel — BMW F650GS com Speeduino

A F650GS vira bicombustível (gasolina ↔ etanol em qualquer proporção)
usando o suporte **nativo de flex fuel do Speeduino**. O sensor lê o teor
de etanol e o firmware interpola automaticamente os mapas de combustível
e ignição entre os dois extremos.

---

## 1. Como o flex funciona no Speeduino

O sensor de flex (tipo GM/Continental) fica na linha de combustível e
gera um sinal digital cuja **frequência indica o % de etanol** e o
**duty cycle indica a temperatura** do combustível.

```
52 Hz  = E0   (0% etanol / gasolina pura)
150 Hz = E100 (100% etanol)
```

O Speeduino lê essa frequência em um pino digital e aplica:
- **Correção de combustível** (mais etanol = mais vazão necessária)
- **Correção de ignição** (etanol aceita mais avanço — maior octanagem)
- Ajuste de **enriquecimento na partida a frio** por teor de etanol

Tudo isso já está no firmware — basta **ativar e calibrar** no TunerStudio.

---

## 2. Hardware necessário

| Item | Especificação | Custo est. (R$) |
|---|---|---|
| Sensor flex | GM 13577429 / Continental "flex fuel sensor" | 60–120 |
| Conector do sensor | 3 vias (sinal, +12V, GND) | 15 |
| Mangueira / adaptadores | entrada e saída 8mm na linha de combustível | 20–40 |
| Resistor pull-up | 1kΩ no sinal (alguns sensores exigem) | 1 |

> O sensor é instalado **em série** na linha de combustível, depois da
> bomba e antes do bico injetor. O combustível passa por dentro dele.

---

## 3. Ligação elétrica

```
Sensor Flex (3 vias)
  Pino A (+12V)   ──► +12V pós-chave (KL15)
  Pino B (GND)    ──► GND (estrela de terra)
  Pino C (sinal)  ──┬──► Speeduino pino FLEX (entrada digital, ex: D2/JS10)
                    │
                  1kΩ pull-up ──► +5V   (se o sensor for open-collector)
```

> No shield Speeduino v0.4, a entrada de flex costuma ser o pino **JS10
> (Flex)** ou um pino digital livre configurável. Confirme no layout do
> seu shield.

---

## 4. Configuração no TunerStudio

1. **Ativar o sensor**
   `Settings → Fuel Settings → Flex Fuel → Flex Fuel = ON`

2. **Calibrar a leitura de frequência**
   - Low (Hz) = **50**, corresponde a **0% etanol**
   - High (Hz) = **150**, corresponde a **100% etanol**

3. **Tabela de correção de combustível** (Fuel Adjustment vs Ethanol %)
   | Etanol % | Correção combustível |
   |---|---|
   | 0% (E0) | 100% (base gasolina) |
   | 30% (E30) | +10% |
   | 50% (E50) | +18% |
   | 85% (E85) | +30% |
   | 100% (E100) | +35% |

4. **Tabela de avanço de ignição extra** (Ignition Adjustment vs Ethanol %)
   | Etanol % | Avanço extra |
   |---|---|
   | 0% | 0° |
   | 50% | +3° |
   | 85% | +5° |
   | 100% | +6° a +8° (validar com knock sensor!) |

5. **Enriquecimento de partida a frio** — aumentar com mais etanol,
   principalmente abaixo de 15°C (etanol custa a vaporizar).

> ⚠️ **Sempre valide o avanço com o sensor de knock conectado.** Os valores
> acima são ponto de partida; cada motor responde diferente. Suba o avanço
> aos poucos monitorando detonação.

---

## 5. Limites do hardware da F650GS

| Item | E27 (gasolina BR) | E100 |
|---|---|---|
| Injetor stock 270cc/min | ✅ ok | ⚠️ no limite em WOT |
| Bomba de combustível | ✅ ok | ✅ ok |
| Mangueiras/borrachas | verificar | trocar por compatível com etanol |
| Avanço de ignição | mapa base | +5–8° possível |

**Recomendação:** se for rodar **E100 puro com frequência**, troque o
injetor por um de **350–400 cc/min** (~R$60) para ter margem em alta carga.
Para E27/E85 ocasional, o injetor original atende.

> **Importante para o medidor de combustível virtual:** ao trocar o
> injetor, atualize `FUEL_INJECTOR_CCMIN` no `config.h` do ESP32, senão
> o cálculo de consumo fica errado.

---

## 6. Ganhos do flex

- **Custo por km menor** quando o etanol compensa (< 70% do preço da gasolina)
- **Mais resistência à detonação** com etanol → mais avanço → mais torque
- **Liberdade de abastecimento** — qualquer mistura, em qualquer posto
- Motor roda mais frio com etanol (bom para o calor brasileiro)
