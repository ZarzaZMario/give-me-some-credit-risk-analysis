-- =============================================================================
-- 03_resumen_looker.sql
-- BigQuery Standard SQL
-- Objetivo: tabla "ancha" lista para conectar a Looker Studio
--           (KPI globales + dimensiones de segmento + banda de riesgo).
-- Una fila = un cliente. Looker agrega tasa de mora, conteos, etc.
-- =============================================================================

SELECT
  -- Identificador sintético (si existe un id real, úsalo)
  GENERATE_UUID() AS cliente_id,

  mora_grave,
  edad,
  ingreso_mensual,
  ingreso_faltante,
  ratio_deuda,
  ratio_deuda_dudoso,
  uso_credito_revolvente,
  uso_revolvente_gt1,
  lineas_credito_abiertas,
  prestamos_hipotecarios,
  dependientes,
  codigo_atraso_especial,

  CAST(
    COALESCE(atrasos_30_59, 0)
    + COALESCE(atrasos_60_89, 0)
    + COALESCE(atrasos_90, 0)
    AS INT64
  ) AS total_atrasos,

  -- Dimensiones listas para filtros / desgloses en Looker
  CASE
    WHEN COALESCE(atrasos_30_59, 0) + COALESCE(atrasos_60_89, 0) + COALESCE(atrasos_90, 0) = 0 THEN '0'
    WHEN COALESCE(atrasos_30_59, 0) + COALESCE(atrasos_60_89, 0) + COALESCE(atrasos_90, 0) = 1 THEN '1'
    WHEN COALESCE(atrasos_30_59, 0) + COALESCE(atrasos_60_89, 0) + COALESCE(atrasos_90, 0) = 2 THEN '2'
    ELSE '3+'
  END AS bucket_atrasos,

  CASE
    WHEN uso_credito_revolvente <= 0.3 THEN '0-0.3'
    WHEN uso_credito_revolvente <= 0.6 THEN '0.3-0.6'
    WHEN uso_credito_revolvente <= 0.9 THEN '0.6-0.9'
    WHEN uso_credito_revolvente <= 1.0 THEN '0.9-1'
    ELSE '>1'
  END AS bucket_uso,

  CASE
    WHEN edad <= 30 THEN '<=30'
    WHEN edad <= 40 THEN '31-40'
    WHEN edad <= 50 THEN '41-50'
    WHEN edad <= 60 THEN '51-60'
    WHEN edad <= 70 THEN '61-70'
    ELSE '70+'
  END AS bucket_edad,

  CASE
    WHEN codigo_atraso_especial = 1 THEN 'Alto'
    WHEN COALESCE(atrasos_30_59, 0) + COALESCE(atrasos_60_89, 0) + COALESCE(atrasos_90, 0) >= 3 THEN 'Alto'
    WHEN (COALESCE(atrasos_30_59, 0) + COALESCE(atrasos_60_89, 0) + COALESCE(atrasos_90, 0) >= 1)
         AND uso_credito_revolvente > 0.9 THEN 'Alto'
    WHEN COALESCE(atrasos_30_59, 0) + COALESCE(atrasos_60_89, 0) + COALESCE(atrasos_90, 0) IN (1, 2) THEN 'Medio'
    WHEN uso_credito_revolvente > 0.6 THEN 'Medio'
    ELSE 'Bajo'
  END AS banda_riesgo

FROM `proyecto.gmsc.clientes_limpio`;
