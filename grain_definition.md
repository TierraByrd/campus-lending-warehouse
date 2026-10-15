# Grain Definition

One row in fact_loans represents one equipment loan event: one item checked out by one student at one campus on one date.

## Why this grain

This is the smallest level of detail the lending desk records, so nothing gets lost. Every report the university wants can be built by grouping these rows. Counting rows gives total loans, and grouping by category, month, semester, or campus slices that total in different ways. Averaging loan_duration_days gives loan length patterns for any of those groups.

If the grain were higher, like one row per item per month, we couldn't go back and look at single loans or questions about individual students. Keeping it at one loan per row means the measures always add up correctly no matter which dimensions a query uses, and no loan gets counted twice.

The date on each row is the checkout date, so all time-based reports are based on when the item went out.