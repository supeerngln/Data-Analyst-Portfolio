-- Check and study the database
SELECT *
FROM housing_v2;

-- Create a duplicate of the table to make sure that the original database is safe
CREATE TABLE housing_dupe LIKE housing_v2;

-- Insert values from housing_v2 to housing_dupe
INSERT housing_dupe SELECT * FROM housing_v2;

-- Check the new table. The cleaning will happen here
SELECT *
FROM housing_dupe;

-- Add row id to identify duplicates
ALTER TABLE housing_dupe
ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;

-- Check duplicates
SELECT *
FROM housing_dupe
WHERE row_id NOT IN
	(SELECT MIN(row_id)
	 FROM (SELECT * FROM housing_dupe) AS subquery
     GROUP BY Description, Location, `Floor Area`, `Land Area`
	);
    
-- Remove duplicates
DELETE FROM housing_dupe
WHERE row_id NOT IN (
    SELECT min_id
    FROM (
        SELECT MIN(row_id) AS min_id
        FROM housing_dupe
        GROUP BY Description, Location, Price, `Floor Area`, `Land Area`
    ) AS unique_rows
);

-- Check table
SELECT *
FROM housing_dupe;
-- 74 rows were removed.

-- Check the nulls of prices, they may be hiding on the description
SELECT *
FROM housing_dupe
WHERE Price= 0 OR Price IS NULL;

-- No price were indicated in the description, hence, the price with 0 or null values will be deleted
DELETE FROM housing_dupe
WHERE Price = 0 OR Price IS NULL;
-- There are prices that are indicated as an empty string

-- Another check to ensure that even empty strings are removed in the prices
SELECT *
FROM housing_dupe
WHERE Price = 0 OR Price IS NULL OR Price = '';
-- Nulls in the price were cleared and removed

-- Check the table again
SELECT *
FROM housing_dupe;

-- Check nulls in the Location 
SELECT *
FROM housing_dupe
WHERE Location IS NULL OR Location = '';
-- 3 of the locations that were null were in Cupang, Muntinlupa (location of Likha Residences) based on their Description

-- Set values for the null values
UPDATE housing_dupe
SET Location = 'Cupang, Muntinlupa'
WHERE Location IS NULL OR Location = '' AND Description LIKE '%Likha Residences%';

-- Check if the 3 nulls in the Location were gone
-- Check nulls in the Location 
SELECT *
FROM housing_dupe
WHERE Location IS NULL OR Location = '';
-- O row was returned

-- Check the table again
SELECT * 
FROM housing_dupe;

-- Check for the nulls where bedrooms, bathrooms, and floor_are are 0. 
SELECT * 
FROM housing_dupe 
WHERE Bedrooms = 0 AND Bathrooms = 0 AND `Floor Area` = 0;
-- This means that it is just a lot and the house will only be built

-- Remove the nulls where bedrooms, bathrooms, and floor_are are 0.
DELETE FROM housing_dupe
WHERE Bedrooms = 0 AND Bathrooms = 0 AND `Floor Area` = 0;
-- 1 row returned

-- Check for the nulls where bedrooms, bathrooms, and floor_are are 0. 
SELECT * 
FROM housing_dupe 
WHERE Bedrooms = 0 AND Bathrooms = 0 AND `Floor Area` = 0;
-- 0 row returned

-- Check the table again
SELECT * 
FROM housing_dupe;

-- Check if the Price were not fake
SELECT *
FROM housing_dupe
ORDER BY Price DESC;

SELECT *
FROM housing_dupe
ORDER BY Price ASC;
-- The price was in string form, so it sees 9 as even if the highest price is more than 10 million

-- Convert Price to BIGINT
ALTER TABLE housing_dupe
MODIFY COLUMN PRICE BIGINT;

-- Check Price again
SELECT *
FROM housing_dupe
ORDER BY Price DESC;

SELECT *
FROM housing_dupe
ORDER BY Price ASC;

-- Check for suspiciously low prices (e.g., under 500,000 Pesos for a house)
SELECT *
FROM housing_dupe 
WHERE Price < 500000 
ORDER BY Price ASC;
-- 0 row returned
-- The prices are in the common and normal range

-- Alter Latitude and Longitude into true geographic coordinates
ALTER TABLE housing_dupe
MODIFY COLUMN Latitude DECIMAL(10,8),
MODIFY COLUMN Longitude DECIMAL(11,8);

-- 64 rows where empty strings, now that we converted it into decimals, we can check what happened to them
SELECT *
FROM housing_dupe
WHERE Latitude IS NULL OR Latitude = 0;

-- This extracts the numbers using a pattern (14.xxxx and 121.xxxx)
UPDATE housing_dupe
SET 
    Latitude = CAST(REGEXP_SUBSTR(Location, '14\\.[0-9]+') AS DECIMAL(10,8)),
    Longitude = CAST(REGEXP_SUBSTR(Location, '12[0-1]\\.[0-9]+') AS DECIMAL(11,8))
WHERE Latitude = 0 AND Location REGEXP '14\\.[0-9]+';
-- 1 row was returned

-- Set to null the remaining latitude and longitude that are equal to 0
UPDATE housing_dupe
SET Latitude = NULL, Longitude = NULL
WHERE Latitude = 0 OR Longitude = 0;
-- It is better to have a clean null values than a half-truth coordinate

-- Check location
SELECT location
FROM housing_dupe;

-- Add table after location
ALTER TABLE housing_dupe
ADD COLUMN brgy_clean VARCHAR(255) AFTER location,
ADD COLUMN city_clean VARCHAR(255) AFTER brgy_clean;

-- Split Barangays and City
UPDATE housing_dupe
SET
	-- 1. Get the city (last part of the string)
    city_clean = TRIM(SUBSTRING_INDEX(location, ',', -1)),
    -- 2. Get the barangay (part before the city)
    brgy_clean = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(location, ',', -2), ',', 1))
    WHERE location LIKE '%,%';
    
-- Check table
SELECT *
FROM housing_dupe;

-- Check cities
SELECT DISTINCT city_clean
FROM housing_dupe
ORDER BY city_clean;

-- The city_clean has 'Philippines Morong' but we need to extract them and make the Philippines the city and the barangay, morong
UPDATE housing_dupe
SET city_clean = TRIM(SUBSTRING_INDEX(city_clean, 'Philippines', ''))
WHERE city_clean LIKE '%Philippines%';

-- Check cities
SELECT DISTINCT city_clean
FROM housing_dupe
ORDER BY city_clean;

-- A split failed, hence, we need to fix it manually
UPDATE housing_dupe
SET city_clean = 'Morong',
    brgy_clean = 'Bloomfield Terraces'
WHERE row_id = 518;

-- Fix typos in Las Piñas and Parañaque
UPDATE housing_dupe
SET Description = REPLACE(Description, 'ParaÃ±aque', 'Parañaque'),
    Location = REPLACE(Location, 'ParaÃ±aque', 'Parañaque'),
    city_clean = REPLACE(city_clean, 'ParaÃ±aque', 'Parañaque');

UPDATE housing_dupe
SET Description = REPLACE(Description, 'PiÃ±as', 'Piñas'),
    Location = REPLACE(Location, 'PiÃ±as', 'Piñas'),
    city_clean = REPLACE(city_clean, 'PiÃ±as', 'Piñas');
    
-- Check Floor Area that are equal to 0
SELECT *
FROM housing_dupe
WHERE `Floor Area` = 0;

DELETE FROM housing_dupe
WHERE `Floor Area` = 0;
-- Needed to delete as it is impossible to calculate the property's worth per sqm

-- Check Land Area that are equal to 0
SELECT *
FROM housing_dupe
WHERE `Land Area` = 0;
