-- load_data.sql
-- Loads the CSV files in data/ into the star schema tables.
-- Run schema.sql first so the tables exist and start empty.

-- Dimensions load first because fact_loans has foreign keys that point to them.
COPY dim_date    FROM 'data/dim_date.csv'    (HEADER);
COPY dim_item    FROM 'data/dim_item.csv'    (HEADER);
COPY dim_campus  FROM 'data/dim_campus.csv'  (HEADER);
COPY dim_student FROM 'data/dim_student.csv' (HEADER);

-- Fact table loads last. Empty loan_duration_days values load as NULL (items still out).
COPY fact_loans  FROM 'data/fact_loans.csv'  (HEADER);

-- Check 1: row counts for every table
SELECT 'dim_date'    AS table_name, COUNT(*) AS row_count FROM dim_date
UNION ALL SELECT 'dim_item',    COUNT(*) FROM dim_item
UNION ALL SELECT 'dim_campus',  COUNT(*) FROM dim_campus
UNION ALL SELECT 'dim_student', COUNT(*) FROM dim_student
UNION ALL SELECT 'fact_loans',  COUNT(*) FROM fact_loans;

-- Check 2: surrogate keys line up.
-- If every loan matches a row in all four dimensions, this returns 32 (same as fact_loans).
SELECT COUNT(*) AS loans_matching_all_dimensions
FROM fact_loans f
JOIN dim_date d    ON f.date_key    = d.date_key
JOIN dim_item i    ON f.item_key    = i.item_key
JOIN dim_campus c  ON f.campus_key  = c.campus_key
JOIN dim_student s ON f.student_key = s.student_key;