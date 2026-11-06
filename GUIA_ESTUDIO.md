# Guía de estudio — Give Me Some Credit

**Para:** Mario Zarza Zárraga  
**Cómo usarla:** lee el concepto → ábrelo en el notebook indicado → responde las preguntas en voz alta (como en entrevista).

---

## Mapa rápido del proyecto

| Paso | Notebook / archivo | Pregunta que responde |
|---|---|---|
| Limpieza | `01_limpieza.ipynb` | ¿Los datos están listos y por qué tomamos cada decisión? |
| EDA | `02_eda.ipynb` | ¿Qué variables se asocian más con la mora? |
| Modelo | `03_modelo.ipynb` | ¿Podemos predecir riesgo y con qué umbral actuamos? |
| SQL | `sql/*.sql` | ¿Cómo segmentamos en BigQuery / Looker? |

---

## 1. Limpieza de datos

**Qué es:** revisar y corregir el dataset antes de analizar o modelar (nulos, errores, códigos raros, outliers).

**Dónde:** `01_limpieza.ipynb`.

**En este proyecto:** borramos edad 0; tratamos 96/98 como códigos; imputamos ingreso y dependientes; capamos outliers; creamos banderas.

### Preguntas de entrevista
1. **¿Por qué no borraste el 20% de filas sin ingreso?**  
   *Modelo de respuesta:* Porque perdería mucha información y el faltante no era aleatorio (edad y mora distintas). Mejor imputar y crear una bandera.
2. **¿Mediana o media para imputar ingreso?**  
   *Modelo:* Mediana. La media se infla con outliers (ingresos de millones).
3. **Dame un ejemplo de “dato sucio que es señal”.**  
   *Modelo:* Los códigos 96/98: no son conteos reales, pero ese grupo tiene ~54% de mora.

---

## 2. Imputación

**Qué es:** rellenar valores faltantes con una regla razonable (mediana, moda, modelo, etc.).

**Dónde:** `01_limpieza` — ingreso (mediana 5,400) y dependientes (0).

### Preguntas
1. **¿Qué riesgo tiene imputar?**  
   *Modelo:* Puedes suavizar patrones reales. Por eso a menudo se agrega una bandera `*_faltante`.
2. **¿Cuándo sí borrarías filas?**  
   *Modelo:* Si el % es tiny y el error es claro (ej. 1 fila con edad 0).
3. **¿Imputar con 0 los dependientes tiene sentido?**  
   *Modelo:* Sí aquí: la mediana era 0 y es una interpretación natural (“sin dependientes / no reportado”).

---

## 3. Banderas (flags)

**Qué es:** columnas 0/1 que marcan un hecho (faltaba el dato, había un código especial, uso > 1).

**Dónde:** `codigo_atraso_especial`, `ingreso_faltante`, `ratio_deuda_dudoso`, `uso_revolvente_gt1`.

### Preguntas
1. **¿Para qué sirven si ya imputaste?**  
   *Modelo:* Para que el modelo sepa que el valor era especial/faltante; el faltante en sí puede ser predictivo.
2. **¿Por qué `ratio_deuda_dudoso`?**  
   *Modelo:* Sin ingreso, el ratio parece deuda absoluta (mediana ~1,159 vs ~0.30). No es comparable.
3. **¿Una bandera con IV bajo puede seguir siendo útil?**  
   *Modelo:* Sí. `codigo_atraso_especial` tiene IV bajo por rareza, pero mora ~54%: regla operativa / feature de cola.

---

## 4. WoE e Information Value (IV)

**Qué es:**  
- **WoE (Weight of Evidence):** en cada bin, qué tan “buena” o “mala” es esa rebanada vs. el promedio.  
- **IV:** resume cuánta información tiene la variable para separar mora vs. no mora.

**Dónde:** `02_eda.ipynb` sección de ranking.

**Regla práctica (Siddiqi):** &lt;0.02 inútil; 0.02–0.1 débil; 0.1–0.3 medio; 0.3–0.5 fuerte; &gt;0.5 muy fuerte.

### Preguntas
1. **¿IV alto garantiza causalidad?**  
   *Modelo:* No. Solo asociación univariada. Puede haber confusores.
2. **¿Por qué bucketear atrasos (0/1/2/3+) para el IV?**  
   *Modelo:* Están muy concentrados en 0; si no, el binning automático colapsa y el IV sale artificialmente en 0.
3. **¿Cuál fue la variable #1 por IV aquí?**  
   *Modelo:* `total_atrasos` (IV ≈ 1.35), luego uso revolvente.

---

## 5. AUC

**Qué es:** área bajo la curva ROC. Mide qué tan bien el score **ordena** a los clientes (¿los de mora quedan arriba?).  
0.5 = azar; 1.0 = perfecto. No depende de un umbral fijo.

**Dónde:** `02_eda` (AUC univariado) y `03_modelo` (AUC del modelo).

### Preguntas
1. **¿AUC 0.87 es bueno en crédito?**  
   *Modelo:* Es sólido para un modelo simple de portafolio; en producción se mira también calibración, estabilidad y negocio.
2. **¿Por qué AUC y no solo accuracy?**  
   *Modelo:* Con 6.7% de mora, predecir siempre “no mora” da ~93% accuracy y es inútil.
3. **¿ROC vs Precision-Recall?**  
   *Modelo:* Con desbalance, la curva PR suele ser más honesta sobre el desempeño en la clase rara.

---

## 6. Recall y precisión

**Qué es:**  
- **Recall (sensibilidad):** de todos los que SÍ cayeron en mora, ¿a cuántos agarramos?  
- **Precisión:** de todos los que marcamos como riesgo, ¿cuántos sí eran mora?

**Trade-off:** bajar el umbral ↑ recall y ↓ precisión (más falsos positivos).

**Dónde:** `03_modelo` — métricas y tabla de umbrales.

### Preguntas
1. **Si el banco odia dejar pasar defaulters, ¿qué priorizas?**  
   *Modelo:* Recall (umbral más bajo), aceptando más rechazos de buenos clientes.
2. **¿Qué es un falso negativo aquí?**  
   *Modelo:* Cliente que iba a caer en mora y el modelo lo dejó pasar.
3. **Números de este proyecto (HGB, umbral 0.5):**  
   *Modelo:* Recall ≈ 78.6%, precisión ≈ 21.4%, AUC ≈ 0.868.

---

## 7. Regresión logística

**Qué es:** modelo lineal que estima la probabilidad de mora. Fácil de explicar (coeficientes / odds ratios).

**Dónde:** `03_modelo` — Pipeline con `StandardScaler` + `LogisticRegression(class_weight='balanced')`.

### Preguntas
1. **¿Por qué escalar?**  
   *Modelo:* Ingreso está en miles y uso en 0–1; sin escalar, los coeficientes no son comparables y el solver sufre.
2. **¿Qué hace `class_weight='balanced'`?**  
   *Modelo:* Da más peso a la clase minoritaria para que el modelo no ignore la mora.
3. **¿Logística vs árboles?**  
   *Modelo:* Logística = interpretable y estable; árboles = capturan no-linealidades e interacciones, algo menos transparentes.

---

## 8. Odds ratio

**Qué es:** `exp(coeficiente)`. En features estandarizadas: cuánto se multiplican las odds de mora cuando la feature sube 1 desvío estándar (manteniendo el resto fijo, en el mundo lineal del modelo).

**Dónde:** tabla de coeficientes en `03_modelo`.

### Preguntas
1. **Odds ratio = 1.2 significa…**  
   *Modelo:* Las odds de mora suben ~20% por cada +1 SD de esa feature (bajo el modelo).
2. **¿Odds ratio &lt; 1?**  
   *Modelo:* Variable protectora (ej. más edad suele bajar el riesgo).
3. **¿Se interpretan igual en HGB?**  
   *Modelo:* No. HGB no tiene un solo coeficiente; usamos importancia por permutación.

---

## 9. Gradient boosting (HistGradientBoosting)

**Qué es:** conjunto de árboles pequeños que se van corrigiendo entre sí. Muy usado en tabular data.

**Dónde:** `03_modelo` — `HistGradientBoostingClassifier` con sample weights balanceados.

### Preguntas
1. **¿Por qué HGB y no un solo árbol?**  
   *Modelo:* Un solo árbol overfittea fácil; el boosting combina muchos árboles débiles y generaliza mejor.
2. **¿Necesita escalado?**  
   *Modelo:* No necesariamente; los árboles parten por umbrales, no por distancia.
3. **Resultado aquí:**  
   *Modelo:* AUC test ≈ 0.868, un poco arriba de la logística (~0.859).

---

## 10. Umbral de decisión

**Qué es:** corte sobre la probabilidad para decir “riesgo alto / rechazar / revisar”.  
0.5 no es sagrado: se elige según costos de negocio.

**Dónde:** `03_modelo` sección de umbrales (ejemplo 5×FN + 1×FP).

### Preguntas
1. **¿Por qué 0.5 no siempre?**  
   *Modelo:* Porque FN y FP no cuestan igual. El umbral traduce el score a una acción.
2. **En el ejemplo 5×FN+1×FP, ¿qué umbral salió?**  
   *Modelo:* 0.70 → recall ≈ 59.5%, precisión ≈ 33.4%, ~11.9% rechazado/revisado.
3. **¿Ese costo es real?**  
   *Modelo:* No: es un supuesto ilustrativo. Riesgo/finanzas debe poner los pesos reales.

---

## 11. Importancia por permutación

**Qué es:** barajas una feature y miras cuánto cae el AUC. Si cae mucho, era importante para *ese* modelo.

**Dónde:** `03_modelo` + comparación con IV del EDA.

### Preguntas
1. **¿IV y permutación deben coincidir?**  
   *Modelo:* En dirección, sí suele; no exactamente, porque IV es univariado y la permutación mira el modelo ya entrenado.
2. **Top features aquí (HGB):**  
   *Modelo:* `total_atrasos`, `uso_credito_revolvente`, luego `edad`.
3. **¿Importancia alta = causalidad?**  
   *Modelo:* No. Solo contribución predictiva en el modelo.

---

## 12. Multicolinealidad (bonus rápido)

**Qué es:** features muy correlacionadas entre sí (las 3 columnas de atraso). En logística inflan coeficientes.

**Qué hicimos:** usar `total_atrasos` en lugar de las tres crudas.

### Pregunta
- **¿Los árboles sufren igual?**  
  *Modelo:* Menos: pueden elegir una de las correlacionadas. Aun así, resumir en `total_atrasos` simplifica la historia.

---

## Mini ensayo de entrevista (5 minutos)

1. Cuenta el problema en 30 segundos (mora a 2 años, ~6.7% positivos).  
2. Una decisión de limpieza + por qué (96/98 o ingreso faltante).  
3. Qué variable manda (atrasos / uso) y con qué evidencia (IV o permutación).  
4. Por qué no usas accuracy sola.  
5. Cómo elegirías el umbral con el negocio.

Cuando termines, abre `03_modelo.ipynb` y explica en voz alta la tabla de umbrales como si estuvieras con un hiring manager.
