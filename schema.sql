-- schema.sql
-- Star schema for the Equipment Lending Analytics Warehouse.
-- fact_loans sits in the center. Each dimension describes one part of a loan:
-- when (dim_date), what (dim_item), where (dim_campus), and who (dim_student).

-- Drop in reverse order so the fact table goes before the dimensions it points to.
DROP TABLE IF EXISTS fact_loans;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_item;
DROP TABLE IF EXISTS dim_campus;
DROP TABLE IF EXISTS dim_student;

-- When the loan happened (checkout date)
CREATE TABLE dim_date (
    date_key      INTEGER PRIMARY KEY,   -- surrogate key in YYYYMMDD form, e.g. 20260115
    full_date     DATE NOT NULL,         -- real date type, not text
    year          INTEGER NOT NULL,
    month         INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name    VARCHAR NOT NULL,
    day           INTEGER NOT NULL CHECK (day BETWEEN 1 AND 31),
    semester      VARCHAR NOT NULL,      -- e.g. Spring 2026, Fall 2026
    academic_year VARCHAR NOT NULL       -- e.g. 2025-2026
);

-- What was loaned
CREATE TABLE dim_item (
    item_key      INTEGER PRIMARY KEY,
    item_category VARCHAR NOT NULL,      -- e.g. Laptop, Camera, Projector
    item_type     VARCHAR NOT NULL       -- e.g. MacBook Air, DSLR Camera
);

-- Where the loan happened
CREATE TABLE dim_campus (
    campus_key    INTEGER PRIMARY KEY,
    campus_name   VARCHAR NOT NULL UNIQUE
);

-- Who borrowed it (optional extra dimension)
CREATE TABLE dim_student (
    student_key    INTEGER PRIMARY KEY,
    major          VARCHAR NOT NULL,
    class_standing VARCHAR NOT NULL CHECK (class_standing IN ('Freshman', 'Sophomore', 'Junior', 'Senior'))
);

-- One row = one equipment loan event (see grain_definition.md)
CREATE TABLE fact_loans (
    loan_key           INTEGER PRIMARY KEY,                       -- surrogate key for each loan
    date_key           INTEGER NOT NULL REFERENCES dim_date(date_key),
    item_key           INTEGER NOT NULL REFERENCES dim_item(item_key),
    campus_key         INTEGER NOT NULL REFERENCES dim_campus(campus_key),
    student_key        INTEGER NOT NULL REFERENCES dim_student(student_key),
    loan_duration_days INTEGER CHECK (loan_duration_days >= 0),   -- NULL if the item is still out
    is_returned        INTEGER NOT NULL CHECK (is_returned IN (0, 1)),
    is_overdue         INTEGER NOT NULL CHECK (is_overdue IN (0, 1))
);