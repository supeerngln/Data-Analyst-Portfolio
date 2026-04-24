# Philippine Housing Market: SQL Data Cleaning and Normalization

## Objective
The goal of the project was to transform a raw, unstructured dataset of Philippine real estate listings into a high-integrity, analysis-ready database. By applying a rigorous cleaning pipeline, I resolved issues such as redundant records, inconsistent address formats, and corrupted data types that would otherwise lead to faulty business insights.

## Dataset
The project utilized a web-scraped dataset of house listings across the Philippines.
1. **`Housing_v2`**: The raw source table containing unstructured strings and "dirty" geographic data.
2. **`housing_dupe`**: The finalized production table featuring normalized columns and optimized data types saved as 'clean_ph_housing_table.csv'.

## Cleaning Challenges and Solutions
* **Deduplication:** Created a unique `row_id` system to identify and remove 74 redundant records, ensuring market supply was not over-reported.
* **Schema Reliability:** Converted  `Price` from strings to `BIGINT` to fix alphabetical sorting bugs and modified coordinates to `DECIMAL` for geographic precision.
* **Geographic Hierarchy:** Extracted `city_clean` and `brgy_clean` from `Location` using complex string parsing.
* **Logical Auditing:** Identified the properties with `Land Area = 0 ` but valid `Floor Area = 0` were Condominiums or CCT Titles, while those with 0 Floor Area were incomplete data and purged for accuracy.

## SQL Skills Applied
* **Complex String Manipulation:** Using `SUBSTRING_INDEX`, `TRIM`, and `REPLACE`.
* **Regex Extraction:** Implementing `REGEXP_SUBSTR` to parse latitude and longitude from text patterns.
* **Schema Engineering:** Using `ALTER TABLE`, `MODIFY COLUMN`, and `CAST`.
* **Data Imputation:** Rescuing missing data by cross-referencing keywords in property `Description`.

### Featured Query: Address Normalization
This SQL snippet shows the logic used to transform a single messy address string into an organized, filterable columns for City and Barangay.
```
sql
UPDATE housing_dupe
SET
    -- 1. Extract the City (the last part of the string)
    city_clean = TRIM(SUBSTRING_INDEX(location, ',', -1)),
    -- 2. Extract the Barangay (the part immediately before the city)
    brgy_clean = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(location, ',', -2), ',', 1))
WHERE location LIKE '%,%';
```
### Key Results
* **Inventory Integrity:** Removed 74 duplicates and 5 incomplete records.
* **Geographic Accuracy:** Standardized names for 48 cities, fixing character encoding errors (e.g. Parañaque and Las Piñas).
* **Analysis Ready:** It is already optimized for price-per-sqm calculations and geographical heat-mapping.

### Business Recommendations

