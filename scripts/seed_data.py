#!/usr/bin/env python3
"""Generates deterministic, realistic-looking seed data:
12 monthly signup cohorts (2024-01 .. 2024-12), each customer has a
per-customer "loyalty" factor that drives a decaying probability of
ordering in later months -- so cohort retention curves look like real ones
(steep drop after month 0, long tail) instead of random noise.
"""
import calendar
import random
from pathlib import Path
from datetime import date, timedelta

random.seed(42)

COHORT_MONTHS = [(2024, m) for m in range(1, 13)]
# how many months of activity we simulate after each cohort's signup month
TRACK_MONTHS = 8

customers = []  # (id, name, email, signup_date)
orders = []     # (id, customer_id, order_date, amount)

customer_id = 1
order_id = 1

FIRST_NAMES = ["Aarav","Diya","Kabir","Isha","Rohan","Meera","Vikram","Ananya","Arjun","Sara",
               "Nikhil","Priya","Karan","Neha","Aditya","Riya","Manish","Tara","Yash","Zara"]
LAST_NAMES = ["Sharma","Verma","Gupta","Nair","Iyer","Reddy","Kapoor","Menon","Joshi","Rao"]

for (year, month) in COHORT_MONTHS:
    days_in_month = calendar.monthrange(year, month)[1]
    cohort_size = random.randint(30, 60)

    for _ in range(cohort_size):
        signup_day = random.randint(1, days_in_month)
        signup_date = date(year, month, signup_day)
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        email = f"{name.lower().replace(' ', '.')}{customer_id}@example.com"
        customers.append((customer_id, name, email, signup_date.isoformat()))

        # Per-customer loyalty in [0.55, 0.98]; higher = keeps ordering longer.
        loyalty = random.uniform(0.55, 0.98)

        for period in range(TRACK_MONTHS):
            # Probability of being active in this period decays geometrically,
            # modulated by the customer's personal loyalty factor.
            prob = (0.88 ** period) * loyalty
            if random.random() > prob:
                continue

            # active this period -> 1-3 orders, spread across the period's month
            active_year = year + (month - 1 + period) // 12
            active_month = (month - 1 + period) % 12 + 1
            days_in_active_month = calendar.monthrange(active_year, active_month)[1]

            for _ in range(random.randint(1, 3)):
                order_day = random.randint(1, days_in_active_month)
                order_date = date(active_year, active_month, order_day)
                if order_date < signup_date:
                    continue
                amount = round(random.uniform(15, 300), 2)
                orders.append((order_id, customer_id, order_date.isoformat(), amount))
                order_id += 1

        customer_id += 1

seed_path = Path(__file__).resolve().parents[1] / "schema" / "seed.sql"
with seed_path.open("w", encoding="utf-8") as f:
    f.write("BEGIN TRANSACTION;\n")
    for c in customers:
        f.write(
            "INSERT INTO customers (id, name, email, signup_date) VALUES "
            f"({c[0]}, '{c[1]}', '{c[2]}', '{c[3]}');\n"
        )
    for o in orders:
        f.write(
            "INSERT INTO orders (id, customer_id, order_date, amount) VALUES "
            f"({o[0]}, {o[1]}, '{o[2]}', {o[3]});\n"
        )
    f.write("COMMIT;\n")

print(f"generated {len(customers)} customers, {len(orders)} orders -> schema/seed.sql")
