#!/usr/bin/env bash
# Rebuilds the database from scratch and runs both analyses.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -f analytics.db
sqlite3 analytics.db < schema/schema.sql
sqlite3 analytics.db < schema/seed.sql

echo "=== RFM segment summary ==="
sqlite3 -header -column analytics.db < queries/rfm_segment_summary.sql
echo
echo "=== RFM detail (first 15 rows) ==="
sqlite3 -header -column analytics.db < queries/rfm_segmentation.sql | head -16
echo
echo "=== Cohort retention (first 20 rows) ==="
sqlite3 -header -column analytics.db < queries/cohort_retention.sql | head -21
