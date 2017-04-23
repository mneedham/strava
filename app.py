from flask import Flask
from flask import render_template
import csv
import json

app = Flask(__name__)

@app.route('/')
def my_runs():
    runs = []
    with open("runs.csv", "r") as runs_file:
        reader = csv.DictReader(runs_file)

        for row in reader:
            runs.append(row["polyline"])

    return render_template("leaflet.html", runs = json.dumps(runs))

if __name__ == "__main__":
    app.run(port = 5001)
