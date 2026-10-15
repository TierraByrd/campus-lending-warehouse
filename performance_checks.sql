-- performance_checks.sql
-- Evidence for performance_reflection.md. EXPLAIN shows DuckDB's query plan without running the query.

.echo on

-- Check 1: Columnar reading (column pruning)
-- The query only needs item_key from fact_loans. Look at the SEQ_SCAN on fact_loans:
-- its projections should list only item_key, not all 8 columns.
EXPLAIN
SELECT i.item_category, COUNT(*) AS total_loans
FROM fact_loans f
JOIN dim_item i ON f.item_key = i.item_key
GROUP BY i.item_category;

-- Check 2: Filtering reduces the data scanned
-- The semester filter should show up inside the dim_date scan, so other semesters
-- are dropped before the join happens.
EXPLAIN
SELECT c.campus_name, COUNT(*) AS total_loans
FROM fact_loans f
JOIN dim_date d   ON f.date_key   = d.date_key
JOIN dim_campus c ON f.campus_key = c.campus_key
WHERE d.semester = 'Fall 2026'
GROUP BY c.campus_name;

-- Check 3: Pre-aggregation with a summary table
-- DuckDB does not support materialized views, so CREATE TABLE AS SELECT stands in for one.
-- The heavy join + group by runs once, and dashboards read the small result.
CREATE OR REPLACE TABLE summary_loans_by_month AS
SELECT d.year, d.month, d.month_name, i.item_category,
       COUNT(*) AS total_loans,
       ROUND(AVG(f.loan_duration_days), 1) AS avg_duration_days
FROM fact_loans f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_item i ON f.item_key = i.item_key
GROUP BY d.year, d.month, d.month_name, i.item_category;

-- A dashboard question answered from the summary table with no joins
SELECT month_name, item_category, total_loans
FROM summary_loans_by_month
WHERE year = 2026 AND month = 9
ORDER BY total_loans DESC, item_category;

-- Size comparison: rows in the summary table vs. rows in the fact table
SELECT (SELECT COUNT(*) FROM summary_loans_by_month) AS summary_rows,
       (SELECT COUNT(*) FROM fact_loans)             AS fact_rows;