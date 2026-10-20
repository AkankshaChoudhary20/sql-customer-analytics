import sqlite3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def test_rfm_ignores_presignup_orders_and_keeps_rollup_consistent():
 with sqlite3.connect(':memory:') as db:
  db.executescript((ROOT/'schema/schema.sql').read_text())
  db.executemany('INSERT INTO customers VALUES (?, ?, ?, ?)',[(1,'Valid','a@test','2024-01-15'),(2,'Invalid only','b@test','2024-02-01')])
  db.executemany('INSERT INTO orders VALUES (?, ?, ?, ?)',[(1,1,'2024-01-01',900),(2,1,'2024-01-15',20),(3,2,'2024-01-31',800)])
  detail=db.execute((ROOT/'queries/rfm_segmentation.sql').read_text()).fetchall()
  assert len(detail)==1
  assert detail[0][0:6]==(1,'Valid',0.0,1,20.0,5)
  summary=db.execute((ROOT/'queries/rfm_segment_summary.sql').read_text()).fetchall()
  assert sum(row[1] for row in summary)==1
  assert sum(row[2] for row in summary)==20
