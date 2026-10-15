# Campus Lending Warehouse

A small star schema in DuckDB for analyzing long-term equipment lending patterns at Concordia University St. Paul: which equipment gets borrowed most, how borrowing changes by month, semester, and academic year, how campuses compare, and how long loans last.

## Dimensional model and grain

One row in fact_loans represents one equipment loan event: one item checked out by one student at one campus on one date. See grain_definition.md for the reasoning.

- **fact_loans**: loan_key, date_key, item_key, campus_key, student_key, plus the measures loan_duration_days, is_returned, and is_overdue. loan_duration_days is NULL for items still checked out.
- **dim_date**: date_key (YYYYMMDD), full_date (DATE type), year, month, month_name, day, semester, academic_year
- **dim_item**: item_key, item_category, item_type
- **dim_campus**: campus_key, campus_name
- **dim_student**: student_key, major, class_standing

The diagram is in star_schema.md.

## Files

| File | What it does |
|---|---|
| grain_definition.md | Defines and explains the fact table grain |
| schema.sql | Creates the fact and dimension tables with keys and CHECK constraints |
| data/ | Sample CSVs: 26 dates, 8 items, 3 campuses, 6 students, 32 loans |
| load_data.sql | Loads the CSVs and checks row counts and key matches |
| olap_queries.sql | 7 OLAP queries with comments |
| performance_checks.sql | EXPLAIN plans and a summary table used as evidence for the reflection |
| performance_reflection.md | Connects the project to warehouse performance concepts |
| star_schema.md | ASCII star schema diagram |
| results/ | Saved output from every script plus screenshots of the queries running |

## How to run

Requires the DuckDB CLI. Run these from the project folder, in order:

```
duckdb lending_warehouse.duckdb -c ".read schema.sql"
duckdb lending_warehouse.duckdb -c ".read load_data.sql"
duckdb lending_warehouse.duckdb -c ".read olap_queries.sql"
duckdb lending_warehouse.duckdb -c ".read performance_checks.sql"
```

schema.sql drops and recreates the tables, so the whole sequence can be rerun from scratch. The lending_warehouse.duckdb file is rebuilt by these scripts, so it isn't stored in the repo.

To save output the way the results folder was made, add a redirect, for example:

```
duckdb lending_warehouse.duckdb -c ".read olap_queries.sql" > results/olap_query_output.txt
```

## OLAP queries

1. **Total loans by month and item category.** Aggregation sliced by time and category. Laptops lead in most months, peaking at 4 in September 2026.
2. **Average loan duration by campus.** St. Paul has the longest average at 5.6 days. Loans still out are left out of the average.
3. **Top 3 item categories by year.** Uses RANK() and QUALIFY. Laptops are #1 both years. 2025 has a three-way tie for 3rd, which RANK keeps on purpose.
4. **Loans by semester and campus.** Two-dimension slice sorted in calendar order. St. Paul has 5 loans every fall and spring semester.
5. **Overdue vs. returned.** 23 returned on time, 5 returned late, 3 still out and not due, 1 still out and overdue.
6. **Laptop drill-down for Fall 2026.** Slices to one semester and category, then drills down to item type and campus.
7. **Roll-up by academic year.** GROUP BY ROLLUP adds a subtotal for each academic year (22 and 10) and a grand total of 32.

Full output is in results/olap_query_output.txt, with screenshots in results/.

## Verification

- results/load_check_output.txt shows every table's row count and that all 32 loans match a row in all four dimensions, so the surrogate keys line up.
- results/performance_checks_output.txt shows the EXPLAIN plans used in the reflection, including fact_loans reading only the columns each query needs and the semester filter applied inside the dim_date scan.
- results/git_log.txt shows the commit history. The work was committed in stages, one step per commit.

## AI assistance

AI assistance was utilized during this project to help brainstorm and clarify the technical concepts required for the assignment. Specifically, the AI helped refine the wording of the grain definition statement and provided guidance on how star schemas reduce join complexity for the performance reflection. It was also used to troubleshoot minor SQL syntax adjustments for DuckDB, though all final scripts and models were implemented independently.