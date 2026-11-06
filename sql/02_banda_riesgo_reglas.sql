-- =============================================================================
-- 02_banda_riesgo_reglas.sql
-- BigQuery Standard SQL
-- Objetivo: asignar una banda de riesgo por REGLAS (sin ML), útil como baseline
--           o para un tablero operativo simple.
-- Lógica (simple y explicable):
--   Alto  : codigo_atraso_especial = 1
--           OR total_atrasos >= 3
--           OR (total_atrasos >= 1 AND uso_credito_revolvente > 0.9)
--   Medio : total_atrasos IN (1, 2) OR uso_credito_revolvente > 0.6
--   Bajo  : resto
-- =============================================================================

WITH base AS (
  SELECT
    mora_grave,
    uso_credito_revolvente,
    codigo_atraso_especial,
    CAST(
      COALESCE(atrasos_30_59, 0)
      + COALESCE(atrasos_60_89, 0)
      + COALESCE(atrasos_90, 0)
      AS INT64
    ) AS total_atrasos
  FROM `proyecto.gmsc.clientes_limpio`
),

con_banda AS (
  SELECT
    *,
    CASE
      WHEN codigo_atraso_especial = 1 THEN 'Alto'
      WHEN total_atrasos >= 3 THEN 'Alto'
      WHEN total_atrasos >= 1 AND uso_credito_revolvente > 0.9 THEN 'Alto'
      WHEN total_atrasos IN (1, 2) THEN 'Medio'
      WHEN uso_credito_revolvente > 0.6 THEN 'Medio'
      ELSE 'Bajo'
    END AS banda_riesgo
  FROM base
)

SELECT
  banda_riesgo,
  COUNT(*) AS n_clientes,
  SUM(mora_grave) AS n_mora,
  SAFE_DIVIDE(SUM(mora_grave), COUNT(*)) AS tasa_mora,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) AS pct_cartera
FROM con_banda
GROUP BY banda_riesgo
ORDER BY
  CASE banda_riesgo
    WHEN 'Alto' THEN 1
    WHEN 'Medio' THEN 2
    ELSE 3
  END;
