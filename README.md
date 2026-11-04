# Is EV charging keeping up? Mapping the UK's charging gap

A friend recently drove from France to Portugal in a battery electric car. The trip was harder than it should have been, mostly because of the hunt for fast chargers along the way. That made me wonder: **where is public charging falling behind the number of electric cars on the road, and is the gap getting worse?**

This project answers that question for every council in the UK, then compares the UK with 18 European countries.

**Dashboard:** *Tableau Public link coming soon*

---

## Key findings

**Across the UK**

- In mid-2026 there were about **10 privately owned battery electric cars for every public charger**, and about **47 for every rapid charger** (50kW and above).
- The gap is widening fastest in a **cluster of East Midlands councils**. Over the year to March 2026, the councils where cars per charger grew most were **Erewash** (18.6 to 34.0), **Amber Valley**, **Lichfield** and **Hinckley and Bosworth**.
- **Hinckley and Bosworth and Erewash appear in the top 10 for both everyday and rapid charging**, so drivers there are losing ground on both.
- North East Derbyshire shows the long-term picture: since 2019 its public chargers grew about **5 times** (5 to 28), while privately owned battery electric cars grew about **26 times** (77 to 2,012).
- At the other end, several **London boroughs have more public chargers than private electric cars** (Tower Hamlets: 0.6 cars per charger), largely slower on-street chargers for residents without driveways.

**The UK compared with Europe (2025)**

- The UK has about **twice the EU average** of battery electric cars per public charging point (13.8 vs 6.5), and **1.9 times the EU average per fast charger** (59.3 vs 31.7).
- On fast charging, the UK ranks **4th worst of 18** European countries.
- **France, Spain and Portugal, the three countries on my friend's route, all have fewer electric cars per fast charger than the UK.**
- The Netherlands is the mirror image of London: one of the highest numbers of charging points relative to its cars, but the worst ratio for fast chargers.

## Why it matters

This analysis works as a **screening tool**: it narrows 361 councils down to a shortlist of places where charging supply is falling behind demand. That's useful for:

- **Charge point operators** choosing where to build next, especially rapid hubs
- **Councils** deciding where to spend charging infrastructure funding
- **Energy network companies** planning where demand on the local grid is growing fastest
- **Retailers and hotels** deciding which car parks to fit with chargers first
- **Car makers, leasing companies and fleet managers** judging whether charging is a barrier in a region

**What it can't tell you yet:** a high ratio isn't automatically a problem. To turn the shortlist into an investment decision, you'd also want charger usage data (are existing chargers busy?), home charging access (areas with driveways need fewer public chargers), traffic flows on major routes, and local grid capacity.

## How I did it

```
Raw government and IEA data
   ↓  Python / pandas (Jupyter): clean, reshape, align dates
Clean tables
   ↓  MySQL: joins, ratios, year-on-year change, rankings, data-quality flags
SQL views
   ↓  Python: export to CSV
Tableau Public dashboard
```

**SQL techniques used:** joins on two keys, `LEFT JOIN`, chained CTEs, `LAG()` with a named `WINDOW`, `RANK()` (including ranking only eligible rows), `CASE` flags, `NULLIF` to avoid dividing by zero, `CROSS JOIN` against a one-row benchmark, and views built on views.

### Key decisions

| Decision | Why |
|---|---|
| **Battery electric cars only** | Plug-in hybrids can fall back on petrol, so they depend less on public charging. |
| **Privately owned cars only** (UK) | Company cars are registered at the company's address, not where they're driven, which would distort local figures. |
| **Individual councils only** | The source files mix the UK, nations, regions, counties and councils. Using one level avoids double counting. |
| **Year-on-year change**, not quarter-on-quarter | Chargers arrive in batches, so quarterly changes are noisy. Comparing with the same quarter a year earlier smooths this out. |
| **Ranked on Q1 2026**, not the latest quarter | Charger counts in the latest quarter dropped sharply in some councils (by more than a third in three months), most likely due to a data correction by one operator. Q1 2026 gives a fairer comparison. |
| **Data-quality flags** | Councils whose charger count fell by 20% or more in a year are flagged rather than hidden. |
| **Minimum of 10 rapid chargers** for the rapid ranking | With only a handful of chargers, adding or removing one swings the ratio wildly. |
| **Rapid chargers from October 2023 only** | DfT changed its definition of "rapid" (from 25kW+ to 50kW+) at that point. |
| **Europe compared from a single source**, including the UK | UK and European data count chargers differently, so the European comparison uses IEA figures for every country and is never mixed with the council analysis. |

### Checks

- Council totals add up exactly to the published UK totals for chargers (e.g. 94,595 in July 2026) and rapid chargers (20,255).
- Council car totals plus cars with an unknown location add up exactly to the UK total (960,009 in June 2026).
- The IEA's UK charging point figure for the end of 2025 (about 116,000) matches DfT's own figure for January 2026.
- Row counts were checked after every load into MySQL, and a primary key on council and quarter guards against duplicates.

## Limitations

- **Private cars only:** company cars make up more than half of UK battery electric cars, so the UK ratios understate total demand and shouldn't be compared directly with headline figures that include all cars.
- **Where cars are registered isn't where they charge.** Rapid chargers on motorways serve through-traffic, so a council's rapid ratio reflects local availability, not route coverage.
- **Home charging isn't measured**, so a high ratio may simply reflect lots of driveways.
- **Council boundaries changed in April 2023** (Cumbria, North Yorkshire and Somerset). Newer councils have no charger history before then.
- **Very small values** shown as `[low]` in the vehicle data were treated as missing (about 15 cells).
- **About 0.6% of cars** couldn't be placed in a council because of incomplete postcodes.
- **IEA figures are rounded** to two significant figures, and the IEA's "fast" (over 22kW) is a different threshold from DfT's "rapid" (50kW+).

## Data sources

| Data | Source | Licence |
|---|---|---|
| Public chargers by council, quarterly (EVCI9001, historic charging devices) | [Department for Transport](https://www.gov.uk/government/statistical-data-sets/electric-vehicle-charging-infrastructure-statistics-data-tables-evci) | [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) |
| Licensed plug-in vehicles by council, quarterly (VEH0142) | [Department for Transport](https://www.gov.uk/government/statistical-data-sets/vehicle-licensing-statistics-data-tables) | [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) |
| Electric car stock and public charging points by country, yearly | [IEA Global EV Outlook 2026, "EV data by country"](https://www.iea.org/data-and-statistics/data-product/global-ev-outlook-2026) | [IEA Terms of Use](https://www.iea.org/terms/terms-of-use-for-non-cc-material) |

**IEA attribution:** Source: IEA (2026), Global EV Outlook 2026 database, https://www.iea.org/data-and-statistics. All rights reserved. As modified by Keagan Krauss.

**IEA data is not included in this repository** because its terms don't allow redistribution. To reproduce the European comparison, download "EV data by country" from the link above and save it as `data/raw/EV data by country 2026.xlsx`.

## Repository structure

```
data/
  raw/        original DfT data (CSV)
  clean/      cleaned tables, one row per council per quarter
  tableau/    SQL view exports used by the dashboard
notebooks/
  01_clean_chargers.ipynb       clean the charger data
  02_clean_vehicles.ipynb       clean the vehicle data
  03_load_to_mysql.ipynb        load clean tables into MySQL
  04_clean_iea.ipynb            clean the IEA data (European comparison)
  05_export_for_tableau.ipynb   export SQL views to CSV
sql/
  01_setup_database.sql         database and table definitions
  02_first_join.sql             cars per charger, latest quarter
  03_lag_one_council.sql        change over time for one council
  04_yoy_ranking.sql            year-on-year ranking, all chargers
  05_rapid_yoy_ranking.sql      year-on-year ranking, rapid chargers
  06_europe_comparison.sql      European countries vs the EU average
  07_views_for_tableau.sql      views that feed the dashboard
```

## How to run it

1. Clone the repository and, for the European comparison, download the IEA file as described above.
2. Run notebooks 01 and 02 to create the clean tables (already included in `data/clean`).
3. Run `sql/01_setup_database.sql` in MySQL to create the database and tables.
4. Run notebook 03 to load the data (it asks for your MySQL password; nothing is saved).
5. Run the SQL scripts in order, then notebook 05 to export the views for Tableau.

Built with Python (pandas, SQLAlchemy), MySQL 8 and Tableau Public.
