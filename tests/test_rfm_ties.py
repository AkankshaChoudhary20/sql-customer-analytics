import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_tied_frequency_ranks_follow_customer_ids():
    conn = sqlite3.connect(':memory:')
    conn.row_factory = sqlite3.Row
    conn.executescript((ROOT / 'schema/schema.sql').read_text())
    for i in range(1, 11):
        conn.execute('INSERT INTO customers VALUES (?, ?, ?, ?)', (i, f'C{i}', f'{i}@test.local', '2024-01-01'))
        conn.execute('INSERT INTO orders VALUES (?, ?, ?, ?)', (i, i, '2024-01-02', 11-i))
    rows = conn.execute((ROOT / 'queries/rfm_segmentation.sql').read_text()).fetchall()
    assert {r['customer_id']:r['f_score'] for r in rows} == {i:(i-1)//2+1 for i in range(1,11)}
    conn.close()
