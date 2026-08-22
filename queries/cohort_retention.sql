-- Monthly cohort retention: group customers by their signup month, then for
-- each subsequent month measure what % of that cohort placed at least one
-- order. This is the classic "cohort table" growth teams live in.

WITH cohort AS (
    SELECT
        id AS customer_id,
        strftime('%Y-%m', signup_date) AS cohort_month
    FROM customers
),
order_activity AS (
    SELECT DISTINCT
        o.customer_id,
        strftime('%Y-%m', o.order_date) AS order_month
    FROM orders o
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        c.customer_id,
        -- period_number = number of whole months between cohort month and order month
        (CAST(strftime('%Y', a.order_month || '-01') AS INTEGER) * 12 +
         CAST(strftime('%m', a.order_month || '-01') AS INTEGER))
        -
        (CAST(strftime('%Y', c.cohort_month || '-01') AS INTEGER) * 12 +
         CAST(strftime('%m', c.cohort_month || '-01') AS INTEGER)) AS period_number
    FROM cohort c
    JOIN order_activity a ON a.customer_id = c.customer_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohort
    GROUP BY cohort_month
),
retained AS (
    SELECT cohort_month, period_number, COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    WHERE period_number >= 0
    GROUP BY cohort_month, period_number
)
SELECT
    r.cohort_month,
    s.cohort_size,
    r.period_number,
    r.active_customers,
    ROUND(100.0 * r.active_customers / s.cohort_size, 1) AS retention_pct
FROM retained r
JOIN cohort_sizes s ON s.cohort_month = r.cohort_month
ORDER BY r.cohort_month, r.period_number;
