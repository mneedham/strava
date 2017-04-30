import psycopg2

with psycopg2.connect("dbname=strava user=markneedham") as conn:
    with conn.cursor() as cur:
        cur.execute("""\
        SELECT data
        FROM runs
        """)

        for row in cur.fetchall():
            print(row[0]["map"]["polyline"])
