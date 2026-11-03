-- First look: private battery electric cars per public charger, by council
-- 1. Work inside the project database
-- 2. Take the cars table (b) and the chargers table (c)
-- 3. Join them: match rows with the same council AND the same quarter
-- 4. Keep only the latest quarter (2026 Q2)
-- 5. Calculate cars per charger, rounded to 1 decimal place
--    (NULLIF avoids dividing by zero if a council has no chargers)
-- 6. Sort so the councils with the most cars per charger come first

USE ev_charging_gap;

SELECT
    b.area_code,
    b.area_name,
    b.join_quarter,
    b.bevs,
    c.chargers,
    ROUND(b.bevs / NULLIF(c.chargers, 0), 1) AS bevs_per_charger
FROM private_bevs AS b
JOIN chargers_all_speeds AS c
    ON  b.area_code    = c.area_code
    AND b.join_quarter = c.join_quarter
WHERE b.join_quarter = '2026 Q2'
ORDER BY bevs_per_charger DESC;

-- A high ratio doesn’t automatically mean underserved: areas with lots of off-street parking need fewer public chargers. 
-- The trend over time is a fairer signal than a single snapshot.

