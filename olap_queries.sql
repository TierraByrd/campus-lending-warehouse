-- olap_queries.sql
-- OLAP-style analytical queries over the equipment lending star schema.
-- Each query starts from fact_loans and joins only the dimensions it needs.

.echo on

-- Query 1: Total loans by month and item category
-- OLAP behavior: aggregation (COUNT) sliced two ways at once, by time and by category.
-- Year is included so September 2025 and September 2026 stay separate.
SELECT d.year, d.month, d.month_name, i.item_category, COUNT(*) AS total_loans
FROM fact_loans f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_item i ON f.item_key = i.item_key
GROUP BY d.year, d.month, d.month_name, i.item_category
ORDER BY d.year, d.month, total_loans DESC, i.item_category;

-- Query 2: Average loan duration by campus
-- OLAP behavior: aggregation (AVG) grouped by the campus dimension.
-- AVG skips NULL durations, so loans still out don't pull the average down.
SELECT c.campus_name,
       COUNT(f.loan_duration_days) AS returned_loans,
       ROUND(AVG(f.loan_duration_days), 1) AS avg_duration_days
FROM fact_loans f
JOIN dim_campus c ON f.campus_key = c.campus_key
GROUP BY c.campus_name
ORDER BY avg_duration_days DESC;

-- Query 3: Top 3 item categories by annual usage
-- OLAP behavior: aggregation per year, then ranking inside each year.
-- RANK() restarts for each year, and QUALIFY keeps only the top 3 (ties share a rank).
SELECT d.year, i.item_category, COUNT(*) AS total_loans,
       RANK() OVER (PARTITION BY d.year ORDER BY COUNT(*) DESC) AS category_rank
FROM fact_loans f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_item i ON f.item_key = i.item_key
GROUP BY d.year, i.item_category
QUALIFY category_rank <= 3
ORDER BY d.year, category_rank, i.item_category;

-- Query 4: Loans by semester and campus
-- OLAP behavior: two-dimension slice (time x location).
-- Sorted by year, then Spring, Summer, Fall, so semesters show in calendar order, not alphabetical.
SELECT d.semester, c.campus_name, COUNT(*) AS total_loans
FROM fact_loans f
JOIN dim_date d   ON f.date_key   = d.date_key
JOIN dim_campus c ON f.campus_key = c.campus_key
GROUP BY d.semester, c.campus_name
ORDER BY MIN(d.year),
         CASE WHEN d.semester LIKE 'Spring%' THEN 1
              WHEN d.semester LIKE 'Summer%' THEN 2
              ELSE 3 END,
         c.campus_name;

-- Query 5: Overdue vs. returned loans
-- OLAP behavior: aggregation over the two flag measures in the fact table.
-- No dimension joins needed since the flags live on the fact row.
SELECT CASE
         WHEN is_returned = 1 AND is_overdue = 0 THEN 'Returned on time'
         WHEN is_returned = 1 AND is_overdue = 1 THEN 'Returned late'
         WHEN is_returned = 0 AND is_overdue = 1 THEN 'Still out, overdue'
         ELSE 'Still out, not due yet'
       END AS loan_status,
       COUNT(*) AS total_loans
FROM fact_loans
GROUP BY loan_status
ORDER BY total_loans DESC;

-- Query 6: Drill-down into laptop loans for Fall 2026
-- OLAP behavior: slice to one semester and one category, then drill down
-- from category (Laptop) to the specific item type and campus.
SELECT i.item_type, c.campus_name, COUNT(*) AS total_loans,
       ROUND(AVG(f.loan_duration_days), 1) AS avg_duration_days
FROM fact_loans f
JOIN dim_date d   ON f.date_key   = d.date_key
JOIN dim_item i   ON f.item_key   = i.item_key
JOIN dim_campus c ON f.campus_key = c.campus_key
WHERE d.semester = 'Fall 2026'
  AND i.item_category = 'Laptop'
GROUP BY i.item_type, c.campus_name
ORDER BY total_loans DESC, i.item_type, c.campus_name;

-- Query 7: Roll-up from semester to academic year to grand total
-- OLAP behavior: roll-up. ROLLUP adds a subtotal row for each academic year
-- and one grand total row at the bottom.
SELECT COALESCE(d.academic_year, 'All years')  AS year_label,
       COALESCE(d.semester, 'All semesters')    AS semester_label,
       COUNT(*) AS total_loans
FROM fact_loans f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY ROLLUP (d.academic_year, d.semester)
ORDER BY GROUPING(d.academic_year), d.academic_year,
         GROUPING(d.semester), MIN(d.full_date);