import pygal
import psycopg2
from math import ceil

charts = [
    {
        "query": """SELECT data->>'start_date' as startDate, (data->>'average_speed')::float as averageSpeed
                    FROM runs
                    ORDER BY startDate""",
        "fileName": "averageSpeed.svg",
        "title": 'Average speed (minutes/mile)'
    },
    {
        "query": """SELECT data->>'start_date' as startDate, (data->>'max_speed')::float as maxSpeed
                    FROM runs
                    ORDER BY startDate""",
        "fileName": "maxSpeed.svg",
        "title": 'Max speed (minutes/mile)'
    },
]

with psycopg2.connect("dbname=strava user=markneedham") as conn:
    for chart in charts:
        with conn.cursor() as cur:
            cur.execute(chart["query"])
            records = cur.fetchall()
            values = [(1609.34 / row[1]) / 60 for row in records]
            dates = [row[0] for row in records]

        line_chart = pygal.Line(range = (0, ceil(max(values))))
        line_chart.title = chart["title"]
        line_chart.add('Speed', values)
        line_chart.x_labels = map(str, dates)
        line_chart.render_to_file("images/{0}".format(chart["fileName"]))
