-- DATA PROFILING
-- Check table
SELECT *
FROM churn_usage;

-- Check if there are no user_id duplicates.
SELECT COUNT(*)
FROM churn_usage;

SELECT COUNT(DISTINCT user_id)
FROM churn_usage;

-- Update signup_date from text to date
ALTER TABLE churn_usage
MODIFY COLUMN signup_date DATE; 

-- Check table
SELECT *
FROM churn_usage;

-- Check the oldest and latest date
SELECT MIN(signup_date), MAX(signup_date)
FROM churn_usage;
-- From here, we can tell that we have 2 years worth of data with no duplicates

-- Check if there are tenure_months equal to 0
SELECT *
FROM churn_usage
WHERE tenure_months = 0;

-- Check plan types
SELECT DISTINCT plan_type
FROM churn_usage;
-- We have Premium, Basic, and Standard

-- Identify if there are last_login_days_ago that are greater than their signup_date
SELECT user_id, signup_date, last_login_days_ago, DATEDIFF('2024-12-31', signup_date) total_days_since_signup
FROM churn_usage
WHERE last_login_days_ago > DATEDIFF('2024-12-31', signup_date);
-- 109 rows were returned (impossible login timelines)

-- We will exclude the 109 rows to proceed with data analyzation using CTE
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT *
FROM clean_data;
-- We are left with 2691 rows

-- DIAGNOSTIC PHASE
-- Calculate the ratio where churn = yes
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT 
COUNT(*) AS total_customers,
SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churn_count,
ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS churn_rate
FROM clean_data;
-- total_customers = 2691
-- churn_count = 1528
-- churn_rate = 56.78

-- Monthly Recovering Revenue Loss vs. Retention
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT churn, SUM(monthly_fee) AS sales
FROM clean_data
GROUP BY churn;
-- churn = yes: 662672
-- churn = no: 502737 
-- The yes are more than the no, hence, they are losing more money

-- Identify churn_rate and total revenue per plan_type
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT churn, SUM(monthly_fee) AS sales, plan_type
FROM clean_data
GROUP BY churn, plan_type;
-- churn = no: Basic (75819), Premium (267717), and Standard (159201)
-- churn = yes: Basic (101888), Premium (362082), and Standard (198702)

-- Show the lost_mrr, total_mrr, and revenue_churn by plan_type
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT plan_type,
SUM(CASE WHEN churn  = 'Yes' THEN monthly_fee ELSE 0 END) AS lost_mrr,
SUM(monthly_fee) AS total_mrr,
ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_fee ELSE 0 END) * 100.0 / SUM(monthly_fee) , 2) AS revenue_churn
FROM clean_data
GROUP BY plan_type;

-- Identify and Compare Average Weekly Usage
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT ROUND(AVG(avg_weekly_usage_hours),2) AS yes_churn_usage
FROM clean_data
WHERE churn = 'Yes';
-- 12.30

WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT ROUND(AVG(avg_weekly_usage_hours), 2) AS no_churn_usage
FROM clean_data
WHERE churn = 'No';
-- 13.71

-- Identify the possible cause why they are leaving
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT churn,
ROUND(AVG(support_tickets), 2) AS avg_tickets,
ROUND(AVG(payment_failures), 2) AS avg_payment_failures,
MAX(support_tickets) AS max_tickets
FROM clean_data
GROUP BY churn;
-- No: avg_tickets(3.45), avg_payment_failures(2.07), and max_tickets(8)
-- Yes: avg_tickets(4.26), avg_payment_failures(2.80), and max_tickets(8)

-- Identify the timeline of the churn and active lifespan
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT churn,
ROUND(AVG(tenure_months), 2) AS avg_tenure,
MIN(tenure_months) AS min_tenure,
MAX(tenure_months) AS max_tenure
FROM clean_data
GROUP BY churn;
-- No: avg_tenure (18.54), min_tenure(1), max_tenure(36)
-- Yes: avg_tenure (18.56), min_tenure(1), max_tenure(36)

-- Risk Identification
WITH clean_data AS (
	SELECT * 
    FROM churn_usage
    WHERE last_login_days_ago <= DATEDIFF('2024-12-31', signup_date)
)
SELECT
	CASE
		WHEN support_tickets >= 5 OR payment_failures >= 3 THEN 'High Risk'
        WHEN support_tickets BETWEEN 3 AND 4 THEN 'Medium Risk'
        ELSE 'Stable'
	END AS risk_category,
    COUNT(*) AS user_count,
    ROUND(AVG(monthly_fee), 2) AS avg_revenue_at_stake
FROM clean_data
WHERE churn = 'No'
GROUP BY 1;
-- High Risk: user_count(717), avg_revenue_at_stake(431.78)
-- Medium Risk: user_count(161), avg_revenue_at_stake(433.16)
-- Stable: user_count(285), avg_revenue_at_stake(433.04)