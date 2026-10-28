import shutil
import sqlite3
import subprocess
from pathlib import Path
import pytest


@pytest.mark.parametrize('orders', [[], [(1, 1, '2024-01-01', 10)],
    [(1, 1, '2024-01-01', 10), (2, 1, '2024-02-02', 20), (3, 999, '2024-03-01', 30)]])
def test_verification_uses_same_valid_order_population_as_queries(tmp_path, orders):
    root = Path(__file__).resolve().parents[1]
    shutil.copytree(root / 'queries', tmp_path / 'queries')
    (tmp_path / 'scripts').mkdir()
    shutil.copy(root / 'scripts/verify.sh', tmp_path / 'scripts/verify.sh')
    with sqlite3.connect(tmp_path / 'analytics.db') as db:
        db.executescript((root / 'schema/schema.sql').read_text())
        db.execute("INSERT INTO customers VALUES (1, 'Ada', 'ada@example.com', '2024-02-01')")
        db.executemany('INSERT INTO orders VALUES (?, ?, ?, ?)', orders)
    result = subprocess.run(['bash', str(tmp_path / 'scripts/verify.sh')], capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
