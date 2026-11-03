-- Where is the gap widening fastest? Year-on-year change in cars per charger
-- 1. ratios: join cars and chargers, calculate cars per charger for every council and quarter
-- 2. yoy: for each row, peek 4 quarters back (one year) at cars, chargers and the ratio
--    - one window (w) defined once: each council compared with itself, in date order
-- 3. Keep 2026 Q1 only: the year before the June 2026 operator data correction
--    (AFTER the peeking, so last year's data is still there)
-- 4. Rank councils by how much their ratio grew: biggest increase = rank 1
-- 5. Flag councils whose chargers fell by more than 20% over the year (possible data correction)

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
),
yoy AS (
    SELECT
        area_name,
        join_quarter,
        bevs,
        chargers,
        bevs_per_charger,
        LAG(bevs, 4)             OVER w AS bevs_last_year,
        LAG(chargers, 4)         OVER w AS chargers_last_year,
        LAG(bevs_per_charger, 4) OVER w AS ratio_last_year
    FROM ratios
    WINDOW w AS (PARTITION BY area_code ORDER BY join_quarter)
)
SELECT
    RANK() OVER (ORDER BY bevs_per_charger - ratio_last_year DESC) AS gap_rank,
    area_name,
    bevs_last_year,
    bevs,
    chargers_last_year,
    chargers,
    ROUND(ratio_last_year, 1)                    AS ratio_last_year,
    ROUND(bevs_per_charger, 1)                   AS ratio_now,
    ROUND(bevs_per_charger - ratio_last_year, 1) AS yoy_change,
    CASE
        WHEN chargers < chargers_last_year * 0.8 THEN 'Check: chargers fell 20%+'
        ELSE ''
    END AS data_flag
FROM yoy
WHERE join_quarter = '2026 Q1'
ORDER BY gap_rank;

-- The latest quarter’s rankings were distorted by a known correction in operator data, so I ranked on the previous year and flagged councils with sudden charger drops.

    
