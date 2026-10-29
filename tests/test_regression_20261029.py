import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path

def test_seed_generation_from_another_working_directory(tmp_path):
    root = Path(__file__).resolve().parents[1]
    project = tmp_path / 'project'
    (project / 'scripts').mkdir(parents=True)
    (project / 'schema').mkdir()
    script = project / 'scripts' / 'seed_data.py'
    shutil.copyfile(root / 'scripts' / 'seed_data.py', script)
    result = subprocess.run([sys.executable, str(script)], cwd=tmp_path, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    seed = project / 'schema' / 'seed.sql'
    assert seed.is_file()
    assert not (tmp_path / 'schema').exists()
    with sqlite3.connect(':memory:') as db:
        db.executescript((root / 'schema' / 'schema.sql').read_text())
        db.executescript(seed.read_text())
        assert db.execute('SELECT COUNT(*) FROM customers').fetchone()[0] > 0
        assert db.execute('SELECT COUNT(*) FROM orders').fetchone()[0] > 0
