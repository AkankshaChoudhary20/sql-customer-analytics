# sql-customer-analytics

Two SQL analyses that growth/marketing teams constantly need and usually
end up reinventing badly: **RFM segmentation** and **cohort retention**.
Built on SQLite (portable, zero setup) but the queries are standard
CTE + window-function SQL that ports to Postgres/MySQL with minor tweaks.

## The problem this solves

Given a `customers` + `orders` table, answer two things every e-commerce
or subscription business asks:

1. **Who are our best customers, and who's slipping away?** →
   RFM segmentation scores every customer on Recency, Frequency, and
   Monetary value, then buckets them into segments (Champions, At Risk,
   Lost, etc.) — no ML, just window functions.
2. **Do customers who join in a given month keep coming back?** →
   Cohort retention groups customers by signup month and tracks what % of
   each cohort is still ordering 1, 2, 3... months later.

## Structure

```
schema/schema.sql      customers + orders tables
schema/seed.sql         generated seed data (544 customers, ~4100 orders)
scripts/seed_data.py    deterministic generator for schema/seed.sql
queries/rfm_segmentation.sql     per-customer RFM scores + segment
queries/rfm_segment_summary.sql  revenue roll-up per segment
queries/cohort_retention.sql     monthly cohort retention table
scripts/run.sh          rebuilds the DB and runs both analyses
scripts/verify.sh        asserts invariants that must always hold
```

## Run it

```bash
./scripts/run.sh
```

Rebuilds `analytics.db` from `schema/` and prints the RFM summary, RFM
detail, and cohort retention table.

## Verify it

```bash
./scripts/verify.sh
```

Real assertions against the query output, not just eyeballing the numbers:
RFM scores stay in [1,5], every customer with an order appears exactly
once, segment totals reconcile, retention percentages stay within [0,100],
and no cohort period ever reports more active customers than it has
members. All 6 checks pass against the generated dataset.

## Regenerating the seed data

```bash
python3 scripts/seed_data.py
```

Deterministic (fixed random seed) — produces 12 monthly signup cohorts
from 2024-01 to 2024-12, each customer given a random "loyalty" factor
that drives a decaying-but-noisy probability of ordering in later months,
so the retention curves look like real ones instead of a straight line.

## Sample output

RFM segment summary:

| segment | customers | total_revenue | avg_revenue_per_customer |
|---|---|---|---|
| Champions | 90 | 163649.33 | 1818.33 |
| Needs Attention | 108 | 133115.82 | 1232.55 |
| At Risk | 68 | 113589.50 | 1670.43 |
| Lost | 93 | 59135.97 | 635.87 |

Cohort retention (excerpt, 2024-01 cohort, 50 customers):

| period_number | active_customers | retention_pct |
|---|---|---|
| 0 | 32 | 64.0 |
| 1 | 35 | 70.0 |
| 3 | 18 | 36.0 |
| 7 | 12 | 24.0 |
