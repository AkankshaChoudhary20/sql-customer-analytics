import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RetentionTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.executescript((ROOT / 'schema/schema.sql').read_text())
        self.query = (ROOT / 'queries/cohort_retention.sql').read_text()

    def tearDown(self):
        self.db.close()

    def test_zero_months_and_nonpurchasing_cohorts_are_included(self):
        self.db.executemany('INSERT INTO customers VALUES (?, ?, ?, ?)', [
            (1, 'A', 'a@example.test', '2024-01-01'),
            (2, 'B', 'b@example.test', '2024-02-01')])
        self.db.executemany('INSERT INTO orders VALUES (?, ?, ?, ?)', [
            (1, 1, '2024-01-03', 10), (2, 1, '2024-03-03', 20),
            (3, 1, '2024-03-04', 10)])
        self.assertEqual(self.db.execute(self.query).fetchall(), [
            ('2024-01', 1, 0, 1, 100.0), ('2024-01', 1, 1, 0, 0.0),
            ('2024-01', 1, 2, 1, 100.0), ('2024-02', 1, 0, 0, 0.0),
            ('2024-02', 1, 1, 0, 0.0)])

    def test_empty_data_and_cohort_without_orders(self):
        self.assertEqual(self.db.execute(self.query).fetchall(), [])
        self.db.execute("INSERT INTO customers VALUES (1, 'A', 'a@example.test', '2024-01-01')")
        self.assertEqual(self.db.execute(self.query).fetchall(), [('2024-01', 1, 0, 0, 0.0)])


if __name__ == '__main__':
    unittest.main()
