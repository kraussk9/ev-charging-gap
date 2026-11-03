-- How has the cars-per-charger ratio changed over time? (one council first)
-- 1. Build a temporary table (a CTE called ratios) with the join and the ratio for every quarter
-- 2. From that, show each quarter's ratio next to the previous quarter's ratio (LAG)
--    - PARTITION BY area_code: each council is compared only with itself
--    - ORDER BY join_quarter: "previous" means the quarter before, in date order
-- 3. Calculate the change from one quarter to the next
-- 4. Look at North East Derbyshire only, in date order

USE ev_charging_gap;

WITH ratios AS (
    SELECT
        b.area_code,
        b.area_name,
        b.join_quarter,
        b.bevs,
        c.chargers,
        b.bevs / NULLIF(c.chargers, 0) AS bevs_per_charger
    FROM private_bevs AS b
    JOIN chargers_all_speeds AS c
        ON  b.area_code    = c.area_code
        AND b.join_quarter = c.join_quarter
)
SELECT
    area_name,
    join_quarter,
    bevs,
    chargers,
    ROUND(bevs_per_charger, 1) AS bevs_per_charger,
    ROUND(LAG(bevs_per_charger) OVER (PARTITION BY area_code ORDER BY join_quarter), 1) AS previous_quarter,
    ROUND(bevs_per_charger - LAG(bevs_per_charger) OVER (PARTITION BY area_code ORDER BY join_quarter), 1) AS change_from_previous
FROM ratios
WHERE area_name = 'North East Derbyshire'
ORDER BY join_quarter;

-- Decided on year-on-year - Chargers are added in lumps, so quarter-to-quarter changes are noisy. Comparing with the same quarter a year earlier smooths that out.”