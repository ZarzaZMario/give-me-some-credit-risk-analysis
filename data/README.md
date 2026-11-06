# Datos — Give Me Some Credit

Los CSV **no** están en el repositorio (licencia de la competencia y tamaño). Descárgalos tú y colócalos aquí.

## Origen

Competencia de Kaggle: [Give Me Some Credit](https://www.kaggle.com/c/GiveMeSomeCredit)

## Cómo descargar

1. Inicia sesión en Kaggle.
2. Abre la pestaña **Data** de la competencia.
3. Acepta las reglas (**I Understand and Accept**).
4. Descarga `cs-training.csv` (o el zip completo y extráelo).
5. Coloca el archivo en esta carpeta:
   ```
   data/cs-training.csv
   ```

## Archivos esperados

| Archivo | Descripción | Generado por |
|---|---|---|
| `cs-training.csv` | Dataset de entrenamiento crudo (~150,000 filas) | Descarga manual desde Kaggle |
| `cs-training-limpio.csv` | Dataset después de la limpieza | `notebooks/01_limpieza.ipynb` |

El archivo limpio también se ignora en git; regenerarlo es reproducir el notebook `01_limpieza`.
