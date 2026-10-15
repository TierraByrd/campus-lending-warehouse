# Star Schema Diagram

fact_loans sits in the center. Each line is a foreign key from the fact table to one dimension.

```
                      +----------------+
                      |    dim_date    |
                      |----------------|
                      | date_key (PK)  |
                      | full_date      |
                      | year, month    |
                      | month_name     |
                      | day, semester  |
                      | academic_year  |
                      +-------+--------+
                              |
                              | date_key
                              |
+----------------+    +-------+------------+    +----------------+
|    dim_item    |    |     fact_loans     |    |   dim_campus   |
|----------------|    |--------------------|    |----------------|
| item_key (PK)  +----+ loan_key (PK)      +----+ campus_key (PK)|
| item_category  |    | date_key (FK)      |    | campus_name    |
| item_type      |    | item_key (FK)      |    +----------------+
+----------------+    | campus_key (FK)    |
                      | student_key (FK)   |
                      | loan_duration_days |
                      | is_returned        |
                      | is_overdue         |
                      +-------+------------+
                              |
                              | student_key
                              |
                      +-------+--------+
                      |  dim_student   |
                      |----------------|
                      | student_key(PK)|
                      | major          |
                      | class_standing |
                      +----------------+
```

The measures (loan_duration_days, is_returned, is_overdue) live in fact_loans. Everything descriptive lives in the dimensions. Every query only needs one join per dimension it uses.