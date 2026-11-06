-- =============================================================================
-- 01_mora_por_segmento.sql
-- BigQuery Standard SQL
-- Objetivo: tasa de mora por segmentos de atrasos, uso revolvente y edad.
-- Tabla esperada: proyecto.gmsc.clientes_limpio
-- =============================================================================

WITH base AS (
  SELECT
    mora_grave,
    -- Si total_atrasos no está materializado, lo armamos aquí
    CAST(
      COALESCE(atrasos_30_59, 0)
      + COALESCE(atrasos_60_89, 0)
      + COALESCE(atrasos_90, 0)
      AS INT64
    ) AS total_atrasos,
    uso_credito_revolvente,
    edad,
    codigo_atraso_especial
  FROM `proyecto.gmsc.clientes_limpio`
),

segmentada AS (
  SELECT
    mora_grave,
    codigo_atraso_especial,
    -- Buckets de atrasos (0, 1, 2, 3+)
    CASE
      WHEN total_atrasos = 0 THEN '0'
      WHEN total_atrasos = 1 THEN '1'
      WHEN total_atrasos = 2 THEN '2'
      ELSE '3+'
    END AS bucket_atrasos,
    -- Buckets de uso revolvente
    CASE
      WHEN uso_credito_revolvente <= 0.3 THEN '0-0.3'
      WHEN uso_credito_revolvente <= 0.6 THEN '0.3-0.6'
      WHEN uso_credito_revolvente <= 0.9 THEN '0.6-0.9'
      WHEN uso_credito_revolvente <= 1.0 THEN '0.9-1'
      ELSE '>1'
    END AS bucket_uso,
    -- Bandas de edad
    CASE
      WHEN edad <= 30 THEN '<=30'
      WHEN edad <= 40 THEN '31-40'
      WHEN edad <= 50 THEN '41-50'
      WHEN edad <= 60 THEN '51-60'
      WHEN edad <= 70 THEN '61-70'
      ELSE '70+'
    END AS bucket_edad
  FROM base
)

-- Vista 1: mora por atrasos
SELECT
  'atrasos' AS dimension,
  bucket_atrasos AS segmento,
  COUNT(*) AS n_clientes,
  SUM(mora_grave) AS n_mora,
  SAFE_DIVIDE(SUM(mora_grave), COUNT(*)) AS tasa_mora
FROM segmentada
GROUP BY 1, 2

UNION ALL

-- Vista 2: mora por uso revolvente
SELECT
  'uso_revolvente' AS dimension,
  bucket_uso AS segmento,
  COUNT(*) AS n_clientes,
  SUM(mora_grave) AS n_mora,
  SAFE_DIVIDE(SUM(mora_grave), COUNT(*)) AS tasa_mora
FROM segmentada
GROUP BY 1, 2

UNION ALL

-- Vista 3: mora por edad
SELECT
  'edad' AS dimension,
  bucket_edad AS segmento,
  COUNT(*) AS n_clientes,
  SUM(mora_grave) AS n_mora,
  SAFE_DIVIDE(SUM(mora_grave), COUNT(*)) AS tasa_mora
FROM segmentada
GROUP BY 1, 2

ORDER BY dimension, segmento;
