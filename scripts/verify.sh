#!/usr/bin/env bash
# Sanity-checks the query output against invariants that must always hold,
# regardless of the underlying data. Exits non-zero on any violation.
set -euo pipefail
cd "$(dirname "$0")/.."

DB=analytics.db
fail=0

check() {
    local desc="$1" query="$2" expect="$3"
    actual=$(sqlite3 "$DB" "$query")
    if [ "$actual" != "$expect" ]; then
        echo "FAIL: $desc (expected '$expect', got '$actual')"
        fail=1
    else
        echo "OK:   $desc"
    fi
}

# Every RFM score must be in [1,5].
check "r_score always 1-5" \
  "SELECT COUNT(*) FROM ($(cat queries/rfm_segmentation.sql | sed 's/;$//')) WHERE r_score NOT BETWEEN 1 AND 5" \
  "0"

check "f_score always 1-5" \
  "SELECT COUNT(*) FROM ($(cat queries/rfm_segmentation.sql | sed 's/;$//')) WHERE f_score NOT BETWEEN 1 AND 5" \
  "0"

# Match the valid-order population used by the queries (exclude orphan and pre-signup orders).
check "RFM row count matches customers-with-orders" \
  "SELECT (SELECT COUNT(*) FROM ($(cat queries/rfm_segmentation.sql | sed 's/;$//'))) - (SELECT COUNT(DISTINCT o.customer_id) FROM orders o JOIN customers c ON c.id = o.customer_id WHERE o.order_date >= c.signup_date)" \
  "0"

# Segment summary customer counts must sum to the same total.
check "segment summary customers sum to customers-with-orders" \
  "SELECT (SELECT COALESCE(SUM(customers), 0) FROM ($(cat queries/rfm_segment_summary.sql | sed 's/;$//'))) - (SELECT COUNT(DISTINCT o.customer_id) FROM orders o JOIN customers c ON c.id = o.customer_id WHERE o.order_date >= c.signup_date)" \
  "0"

# Retention percentages must never exceed 100 or drop below 0.
check "retention_pct always within [0,100]" \
  "SELECT COUNT(*) FROM ($(cat queries/cohort_retention.sql | sed 's/;$//')) WHERE retention_pct < 0 OR retention_pct > 100" \
  "0"

# Period 0 active_customers can never exceed the cohort_size.
check "period-0 active customers never exceed cohort size" \
  "SELECT COUNT(*) FROM ($(cat queries/cohort_retention.sql | sed 's/;$//')) WHERE period_number = 0 AND active_customers > cohort_size" \
  "0"

if [ "$fail" -ne 0 ]; then
    echo
    echo "VERIFICATION FAILED"
    exit 1
fi
echo
echo "ALL CHECKS PASSED"
