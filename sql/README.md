# Consultas SQL (BigQuery Standard SQL)

Estas consultas están **escritas para BigQuery** sobre una tabla hipotética:

```text
proyecto.gmsc.clientes_limpio
```

con el esquema del CSV limpio (`mora_grave`, `total_atrasos` o las columnas de atraso, `uso_credito_revolvente`, `edad`, banderas, etc.).

**No se ejecutaron aquí contra BigQuery.** Sirven como capa analítica / fuente de un dashboard en Looker Studio (próximo paso del portafolio).

Para usarlas:
1. Carga `cs-training-limpio.csv` a BigQuery (o crea `total_atrasos` en la consulta).
2. Sustituye `proyecto.gmsc.clientes_limpio` por tu proyecto.dataset.tabla.
3. Ejecuta en la consola de BigQuery o conéctalas a Looker Studio.
