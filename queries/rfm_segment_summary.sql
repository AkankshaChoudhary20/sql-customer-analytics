-- Roll-up view: how many customers and how much revenue each RFM segment represents.
-- Useful as the headline number for a marketing/growth team.

WITH as_of AS (
    SELECT MAX(o.order_date) AS as_of_date
    FROM orders o
    JOIN customers c ON c.id = o.customer_id
    WHERE o.order_date >= c.signup_date
),
customer_orders AS (
    SELECT
        c.id AS customer_id,
        julianday((SELECT as_of_date FROM as_of)) - julianday(MAX(o.order_date)) AS recency_days,
        COUNT(o.id) AS frequency,
        SUM(o.amount) AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.id AND o.order_date >= c.signup_date
    GROUP BY c.id
),
scored AS (
    SELECT
        customer_id,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency_days) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)        AS f_score,
        NTILE(5) OVER (ORDER BY monetary)         AS m_score
    FROM customer_orders
),
segmented AS (
    SELECT
        customer_id,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3                  THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
            WHEN r_score = 3                                    THEN 'Needs Attention'
            WHEN r_score <= 2 AND f_score >= 4                  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2  THEN 'Lost'
            ELSE 'Others'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer
FROM segmented
GROUP BY segment
ORDER BY total_revenue DESC;

