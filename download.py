import requests
import os
import sys
import csv

token = os.environ["TOKEN"]
headers = {'Authorization': "Bearer {0}".format(token)}

page = 1
r = requests.get("https://www.strava.com/api/v3/athlete/activities?page={0}".format(page), headers = headers)
response = r.json()

with open("runs.csv", "w") as runs_file:
    writer = csv.writer(runs_file, delimiter=",")
    writer.writerow(["id", "polyline"])
    for activity in response:
        r = requests.get("https://www.strava.com/api/v3/activities/{0}?include_all_efforts=true".format(activity["id"]), headers = headers)
        polyline = r.json()["map"]["polyline"]
        writer.writerow([activity["id"], polyline])

sys.exit(1)

page = 1
while True:
    r = requests.get("https://www.strava.com/api/v3/athlete/activities?page={0}".format(page), headers = headers)
    response = r.json()

    print(len(response))
    if len(response) == 0:
        break
    else:
        page += 1
