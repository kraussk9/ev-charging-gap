-- View 1: one row per council per quarter, for trend lines in Tableau
-- 1. Join cars to all-speed chargers (same council, same quarter)
-- 2. LEFT JOIN rapid chargers: keep every quarter, even before rapid data starts (2023 Q3);
--    those quarters just get NULL for rapid
-- 3. quarter_end: a real date for Tableau's time axis (charger date minus one day)
-- 4. Ratios left unrounded; Tableau will handle the formatting

USE ev_charging_gap;

CREATE OR REPLACE VIEW v_council_timeseries AS
SELECT
    b.area_code,
    b.area_name,
    b.join_quarter,
    DATE_SUB(c.date, INTERVAL 1 DAY)      AS quarter_end,
    b.bevs,
    c.chargers,
    r.rapid_chargers,
    b.bevs / NULLIF(c.chargers, 0)        AS bevs_per_charger,
    b.bevs / NULLIF(r.rapid_chargers, 0)  AS bevs_per_rapid_charger
FROM private_bevs AS b
JOIN chargers_all_speeds AS c
    ON  b.area_code    = c.area_code
    AND b.join_quarter = c.join_quarter
LEFT JOIN rapid_chargers AS r
    ON  b.area_code    = r.area_code
    AND b.join_quarter = r.join_quarter;
    
    -- Check: expect 10108 rows (361 councils × 28 quarters),
-- and 4332 with rapid data (361 × 12 quarters from 2023 Q3)

SELECT COUNT(*), COUNT(rapid_chargers) FROM v_council_timeseries;

-- View 2: one row per council, both rankings, for the map and bar charts in Tableau
-- 1. yoy: read the time series view, peek back 4 quarters (one year) for chargers and ratios
-- 2. Keep 2026 Q1 only (the year before the June 2026 correction), AFTER the peeking
-- 3. gap_rank: all-speed ranking, 1 = ratio grew the most
-- 4. rapid_gap_rank: rapid ranking for councils with 10+ rapid chargers last year only;
--    others get NULL (rank by a value that's NULL for them, then blank their rank)
-- 5. Flags as 1/0 (easy to filter and colour in Tableau):
--    charger drops of 20%+, rapid drops of 20%+, and councils with fewer than 10 rapid chargers

CREATE OR REPLACE VIEW v_council_summary AS
WITH yoy AS (
    SELECT
        area_code,
        area_name,
        join_quarter,
        bevs,
        chargers,
        rapid_chargers,
        bevs_per_charger,
        bevs_per_rapid_charger,
        LAG(chargers, 4)               OVER w AS chargers_last_year,
        LAG(rapid_chargers, 4)         OVER w AS rapid_last_year,
        LAG(bevs_per_charger, 4)       OVER w AS ratio_last_year,
        LAG(bevs_per_rapid_charger, 4) OVER w AS rapid_ratio_last_year
    FROM v_council_timeseries
    WINDOW w AS (PARTITION BY area_code ORDER BY join_quarter)
)
SELECT
    area_code,
    area_name,
    join_quarter,
    bevs,
    chargers,
    rapid_chargers,
    bevs_per_charger,
    bevs_per_rapid_charger,
    bevs_per_charger - ratio_last_year                    AS yoy_change,
    bevs_per_rapid_charger - rapid_ratio_last_year        AS rapid_yoy_change,
    RANK() OVER (ORDER BY bevs_per_charger - ratio_last_year DESC) AS gap_rank,
    CASE
        WHEN rapid_last_year >= 10 THEN
            RANK() OVER (ORDER BY CASE WHEN rapid_last_year >= 10
                                       THEN bevs_per_rapid_charger - rapid_ratio_last_year
                                  END DESC)
    END                                                   AS rapid_gap_rank,
    CASE WHEN chargers < chargers_last_year * 0.8 THEN 1 ELSE 0 END   AS charger_drop_flag,
    CASE WHEN rapid_chargers < rapid_last_year * 0.8 THEN 1 ELSE 0 END AS rapid_drop_flag,
    CASE WHEN rapid_last_year < 10 THEN 1 ELSE 0 END                  AS few_rapid_chargers
FROM yoy
WHERE join_quarter = '2026 Q1';

-- Check: expect 361 councils, 330 with a rapid rank, 3 charger drops, 6 rapid drops, 31 with few rapid chargers

SELECT
    COUNT(*),
    COUNT(rapid_gap_rank),
    SUM(charger_drop_flag),
    SUM(rapid_drop_flag),
    SUM(few_rapid_chargers)
FROM v_council_summary;

SELECT area_name, gap_rank, rapid_gap_rank
FROM v_council_summary
ORDER BY gap_rank
LIMIT 5;

-- View 3: European comparison 2025, for the Europe panel in Tableau (IEA data: local only)
-- 1. eu: the EU benchmark for 2025 (one row)
-- 2. Attach it to every European country (CROSS JOIN) and divide: 1.0 = same as the EU
-- 3. Rank by cars per fast charger: 1 = biggest gap
-- 4. Flag the three countries on the road-trip route (France, Spain, Portugal)

CREATE OR REPLACE VIEW v_europe_2025 AS
WITH eu AS (
    SELECT
        bevs_per_point      AS eu_per_point,
        bevs_per_fast_point AS eu_per_fast_point
    FROM europe_comparison
    WHERE is_eu_benchmark = 1
      AND year = 2025
)
SELECT
    RANK() OVER (ORDER BY e.bevs_per_fast_point DESC)   AS fast_gap_rank,
    e.country,
    e.bevs_per_point,
    e.bevs_per_point / eu.eu_per_point                   AS times_eu_point,
    e.bevs_per_fast_point,
    e.bevs_per_fast_point / eu.eu_per_fast_point         AS times_eu_fast,
    CASE WHEN e.country IN ('France', 'Spain', 'Portugal') THEN 1 ELSE 0 END AS on_road_trip_route
FROM europe_comparison AS e
CROSS JOIN eu
WHERE e.is_europe = 1
  AND e.year = 2025;
  
  -- Check: expect 18 countries, 3 on the road-trip route, and the UK at rank 4

SELECT COUNT(*), SUM(on_road_trip_route) FROM v_europe_2025;

SELECT fast_gap_rank, country FROM v_europe_2025 WHERE country = 'United Kingdom';