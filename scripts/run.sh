#!/usr/bin/env bash
# Rebuilds the database from scratch and runs both analyses.
set -euo pipefail
cd "$(dirname "$0")/.."

db_temp=$(mktemp ./analytics.db.XXXXXX)
trap 'rm -f "$db_temp"' EXIT
sqlite3 -bail "$db_temp" < schema/schema.sql
sqlite3 -bail "$db_temp" < schema/seed.sql
mv -f "$db_temp" analytics.db

echo "=== RFM segment summary ==="
sqlite3 -header -column analytics.db < queries/rfm_segment_summary.sql
echo
echo "=== RFM detail (first 15 rows) ==="
sqlite3 -header -column analytics.db < queries/rfm_segmentation.sql | sed -n '1,16p'
echo
echo "=== Cohort retention (first 20 rows) ==="
sqlite3 -header -column analytics.db < queries/cohort_retention.sql | sed -n '1,21p'
