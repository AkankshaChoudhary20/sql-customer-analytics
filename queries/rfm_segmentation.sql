-- RFM (Recency, Frequency, Monetary) customer segmentation.
--
-- "As of" date is the latest order date in the data, so this is
-- reproducible against any snapshot of the dataset.
--
-- Each customer gets a 1-5 score per dimension (5 = best) via NTILE,
-- then those scores map to a human-readable segment.

WITH as_of AS (
    SELECT MAX(order_date) AS as_of_date FROM orders
),
customer_orders AS (
    SELECT
        c.id AS customer_id,
        c.name,
        julianday((SELECT as_of_date FROM as_of)) - julianday(MAX(o.order_date)) AS recency_days,
        COUNT(o.id) AS frequency,
        SUM(o.amount) AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
    GROUP BY c.id, c.name
),
scored AS (
    SELECT
        customer_id,
        name,
        recency_days,
        frequency,
        monetary,
        -- Lower recency_days is better, so invert the bucket order (6 - ntile).
        6 - NTILE(5) OVER (ORDER BY recency_days) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)        AS f_score,
        NTILE(5) OVER (ORDER BY monetary)         AS m_score
    FROM customer_orders
)
SELECT
    customer_id,
    name,
    ROUND(recency_days) AS recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score, f_score, m_score,
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
ORDER BY monetary DESC;
