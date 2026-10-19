-- Monthly cohort retention: group customers by their signup month, then for
-- each subsequent month measure what % of that cohort placed at least one
-- order. Zero-activity months are included through the latest signup/order month.
-- This is the classic "cohort table" growth teams live in.

WITH RECURSIVE cohort AS (
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
    JOIN customers c ON c.id = o.customer_id
    WHERE o.order_date >= c.signup_date
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
),
observation_end AS (
    SELECT MAX(month) AS last_month FROM (
        SELECT cohort_month AS month FROM cohort
        UNION ALL
        SELECT order_month FROM order_activity
    )
),
cohort_periods(cohort_month, period_number, period_month) AS (
    SELECT cohort_month, 0, cohort_month || '-01' FROM cohort_sizes
    UNION ALL
    SELECT cohort_month, period_number + 1, date(period_month, '+1 month')
    FROM cohort_periods
    WHERE strftime('%Y-%m', period_month) < (SELECT last_month FROM observation_end)
)
SELECT
    p.cohort_month,
    s.cohort_size,
    p.period_number,
    COALESCE(r.active_customers, 0) AS active_customers,
    ROUND(100.0 * COALESCE(r.active_customers, 0) / s.cohort_size, 1) AS retention_pct
FROM cohort_periods p
JOIN cohort_sizes s ON s.cohort_month = p.cohort_month
LEFT JOIN retained r ON r.cohort_month = p.cohort_month AND r.period_number = p.period_number
ORDER BY p.cohort_month, p.period_number;

