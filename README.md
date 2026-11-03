# EV charging gap project: brief

**Question:** Where is EV charging supply falling behind EV demand? Compare battery electric cars with public chargers, area by area, across the UK (phase 1), then compare the UK with European countries (phase 2). Rank the places where the gap is widening fastest.

**Why:** Fills the SQL + Tableau gap in the portfolio (e.g. Nuitée Data Analyst role lists hands-on SQL as the one hard requirement). Framed as a supply vs. demand business question, not a statistics report. Hook: a friend's France-to-Portugal road trip in a battery electric car, and how hard charging was.

**Stack:** Python/pandas (Jupyter, Anaconda) for cleaning, MySQL Workbench for core analysis, Tableau Public for the dashboard, README with question, findings, and limitations. Repo: github.com/kraussk9/ev-charging-gap (Windows, PowerShell, local folder Desktop\Ironhack\ev-charging-gap).

**How Keags wants help:** walk through every code cell step by step, one step per message; explain each line in plain English; pseudocode comments (#) at the top of every code cell; she types code herself (no copy-paste from chat). Use the relative path `../data/raw/...` from notebooks.

## Status (2 Nov 2026)
UK cleaning complete. Three clean CSVs in data/clean. Next: load into MySQL Workbench and write the join.

## Repo structure
- data/raw: evci9001_1a.csv, evci9001_1b.csv, veh0142.csv (exported from Google Sheets, so numbers have thousands commas)
- data/clean: chargers_all_speeds.csv, rapid_chargers.csv, private_bevs.csv
- notebooks: 01_clean_chargers.ipynb, 02_clean_vehicles.ipynb (both with pseudocode)

## Clean tables
- **chargers_all_speeds.csv** (tab 1a): area_code, area_name, join_quarter, date, chargers. 385 councils × 28 quarters = 10,780 rows (Oct-19 to Jul-26).
- **rapid_chargers.csv** (tab 1b): same layout, value column rapid_chargers. Filtered to Oct 2023 onwards (consistent 50kW+ definition): 385 × 12 = 4,620 rows.
- **private_bevs.csv** (VEH0142): area_code, area_name, join_quarter, bevs. Cars / Battery electric / Private. 361 councils × 67 quarters = 24,187 rows (2009 Q4 to 2026 Q2).
- Join key: area_code + join_quarter. All 361 vehicle council codes exist in the charger table (checked).

## Decisions (Keags)
- **Body type: Cars only.** Vans are mostly commercial.
- **Fuel: Battery electric only.** Plug-in hybrids (and range-extended) can fall back on petrol, so they're weaker evidence of need for public charging.
- **Keepership: Private only.** Company vehicles are counted at the company's registered address, not where they're driven; private is the honest measure of local demand and matches the road-trip hook.
- **Geography: lowest tier councils only** (code prefixes E06, E07, E08, E09, S12, W06, N09), to avoid double counting.
- **Main measure: all-speed chargers (1a). Road-trip lens: rapid chargers (1b), Oct 2023 onwards only.**

## Cleaning steps used (for README)
- read_csv with skiprows (2 for chargers, 4 for vehicles), thousands=",", na_values=["[x]", "[low]"]; low_memory=False for VEH0142.
- Filtered to lowest-tier councils by code prefix.
- Melted wide → long.
- Charger labels: removed footnote markers ([Note 14], [Note 4]), rapid labels split at whitespace, "July" → "Jul", parsed with format "%b-%y".
- **Date alignment:** chargers are counted on the 1st of the quarter, vehicles at the end of the previous quarter. Charger date minus one day → quarter → "YYYY Qn" as join_quarter (Jul-26 → 2026 Q2, Oct-19 → 2019 Q3).
- Vehicle names had leading indent spaces; stripped.

## Sanity checks passed (good README material)
- All-speed chargers: council totals = UK row (15,116 Oct-19; 94,595 Jul-26).
- Rapid chargers: council totals = UK row (2,495 Oct-19; 20,255 Jul-26).
- Private BEV cars, 2026 Q2: councils 954,495 + unknown location 5,514 = UK 960,009 (about 0.6% unplaced).
- 28 unique charger dates; 12 after rapid filter; 361 shared council codes.

## UK data sources
- **Supply: EVCI9001** (historic "charging devices" series), data tables page: https://www.gov.uk/government/statistical-data-sets/electric-vehicle-charging-infrastructure-statistics-data-tables-evci (under "Historic tables"). Tabs 1a all speeds, 1b rapid, by local authority, quarterly Oct-19 to Jul-26. Used instead of the new EV charger tables (EVCI0102 etc.), which are single snapshots. EVCI0101 is region/country only.
- **Demand: VEH0142**, vehicle licensing data tables page: https://www.gov.uk/government/statistical-data-sets/vehicle-licensing-statistics-data-tables (under "Plug-in vehicles"). Old VEH02 link redirects. Quarters run newest to oldest.

## Known catches (limitations section)
- **Abolished councils:** the charger file keeps 24 councils abolished April 2023 (Cumbria, North Yorkshire, Somerset and their districts) alongside the new ones (which show [x] before 2023). The vehicle file back-dates today's 361 councils to 2009. So the new councils (e.g. Cumberland) have vehicles but no chargers before 2023; handle in SQL (e.g. analyse from 2023 Q2 for those, or flag them).
- `[low]` (very small values, displayed by DfT) treated as missing: about 15 cells in the analysed slice.
- Rapid definition changed Oct 2023: 25kW+ before, 50kW+ after (tab 1b). All-speeds (1a) is consistent.
- "Charging devices" series replaced by "EV chargers" from Jan 2026 as the headline measure; not directly comparable. ~1,270 chargers removed June 2026 after being misreported as public.
- Sudden local drops can be decommissioning lag (EVCI9001 note 3); York double-counted until 2024 (note 13).
- Private-only BEV demand undercounts total BEVs, so ratios will look better than DfT's headline (1 public charger per 17 BEVs, April 2026, EVCI0401, UK level only). Don't compare directly.
- Vehicles are counted by keeper's postcode, not where they're driven or charged; about 0.6% of private BEVs have unknown location.

## EU data (phase 2, yearly, country level)
- Demand: Eurostat `road_eqs_carpda`, passenger cars by motor energy (filter to battery electric), CSV from Eurostat data browser.
- Supply: Eurostat experimental statistics on recharging stations (built from EAFO data): https://ec.europa.eu/eurostat/web/experimental-statistics/recharging-stations
- Design: roll UK up to one national, year-end figure to compare fairly. Include France, Spain, Portugal to close the road-trip story. Check "EV" definitions match.

## Steps
1. ✅ Download EVCI9001 + VEH0142.
2. ✅ Clean and reshape into three tidy CSVs (pandas).
3. Load into MySQL Workbench (three tables).
4. SQL core: join on area_code + join_quarter, BEVs per charger, LAG() for quarter-on-quarter change, RANK() for fastest-widening gaps. Handle abolished/new councils.
5. Tableau Public dashboard: map + ranking.
6. Phase 2: Eurostat country comparison.
7. README: question, findings, limitations.
