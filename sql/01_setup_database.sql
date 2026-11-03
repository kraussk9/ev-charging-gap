-- Create a database (a folder for tables) for this project
-- and tell MySQL to use it for everything that follows

CREATE DATABASE IF NOT EXISTS ev_charging_gap;

USE ev_charging_gap;

-- Build the three empty tables that will hold the clean data
-- 1. Make sure we're working inside the project database
-- 2. Create one table per clean CSV, with column names matching the CSV headers
-- 3. Give each column a type (text, whole number or date)
-- 4. Set a primary key: one row per council per quarter, so duplicates are refused

USE ev_charging_gap;

CREATE TABLE IF NOT EXISTS chargers_all_speeds (
    area_code     VARCHAR(9)   NOT NULL,
    area_name     VARCHAR(100),
    join_quarter  VARCHAR(7)   NOT NULL,
    date          DATE,
    chargers      INT,
    PRIMARY KEY (area_code, join_quarter)
);

CREATE TABLE IF NOT EXISTS rapid_chargers (
    area_code       VARCHAR(9)   NOT NULL,
    area_name       VARCHAR(100),
    join_quarter    VARCHAR(7)   NOT NULL,
    date            DATE,
    rapid_chargers  INT,
    PRIMARY KEY (area_code, join_quarter)
);

CREATE TABLE IF NOT EXISTS private_bevs (
    area_code     VARCHAR(9)   NOT NULL,
    area_name     VARCHAR(100),
    join_quarter  VARCHAR(7)   NOT NULL,
    bevs          INT,
    PRIMARY KEY (area_code, join_quarter)
);