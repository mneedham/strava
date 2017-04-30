import requests
import os
import json
import psycopg2

token = os.environ["TOKEN"]
headers = {'Authorization': "Bearer {0}".format(token)}

with psycopg2.connect("dbname=strava user=markneedham") as conn:
    with conn.cursor() as cur:
        page = 1
        while True:
            r = requests.get("https://www.strava.com/api/v3/athlete/activities?page={0}".format(page), headers = headers)
            response = r.json()

            if len(response) == 0:
                break
            else:
                for activity in response:
                    r = requests.get("https://www.strava.com/api/v3/activities/{0}?include_all_efforts=true".format(activity["id"]), headers = headers)
                    json_response = r.json()
                    print("importing {0}".format(activity["id"]))
                    cur.execute("INSERT INTO runs (id, data) VALUES(%s, %s)", (activity["id"], json.dumps(json_response)))
                    conn.commit()
                page += 1
