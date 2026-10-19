import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_presignup_orders_do_not_count_as_retained_or_extend_observation():
    with sqlite3.connect(':memory:') as db:
        db.executescript((ROOT / 'schema/schema.sql').read_text())
        db.execute("INSERT INTO customers VALUES (1, 'A', 'a@test', '2024-01-15')")
        db.execute("INSERT INTO orders VALUES (1, 1, '2024-01-01', 10)")
        query = (ROOT / 'queries/cohort_retention.sql').read_text()
        assert db.execute(query).fetchall() == [('2024-01', 1, 0, 0, 0.0)]
        db.execute("INSERT INTO orders VALUES (2, 1, '2024-01-15', 20)")
        assert db.execute(query).fetchall() == [('2024-01', 1, 0, 1, 100.0)]
