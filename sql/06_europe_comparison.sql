-- European comparison, 2025: how does each country compare with the EU average?
-- 1. eu: fetch the EU benchmark ratios for 2025 (a one-row table)
-- 2. Attach that one row to every European country (CROSS JOIN)
-- 3. Divide each country's ratio by the EU's: 1.0 = same as the EU, 2.0 = twice as many cars per charger
-- 4. Rank by cars per fast charger: rank 1 = most cars per fast charger (biggest gap)

USE ev_charging_gap;

WITH eu AS (
    SELECT
        bevs_per_point      AS eu_per_point,
        bevs_per_fast_point AS eu_per_fast_point
    FROM europe_comparison
    WHERE is_eu_benchmark = 1
      AND year = 2025
)
SELECT
    RANK() OVER (ORDER BY e.bevs_per_fast_point DESC)        AS fast_gap_rank,
    e.country,
    ROUND(e.bevs_per_point, 1)                               AS bevs_per_point,
    ROUND(e.bevs_per_point / eu.eu_per_point, 2)             AS times_eu_point,
    ROUND(e.bevs_per_fast_point, 1)                          AS bevs_per_fast_point,
    ROUND(e.bevs_per_fast_point / eu.eu_per_fast_point, 2)   AS times_eu_fast
FROM europe_comparison AS e
CROSS JOIN eu
WHERE e.is_europe = 1
  AND e.year = 2025
ORDER BY fast_gap_rank;