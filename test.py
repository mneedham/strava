import json
import os

import requests

token = os.environ["TOKEN"]
headers = {'Authorization': "Bearer {0}".format(token)}

r = requests.get("https://www.strava.com/api/v3/athlete/activities?page={0}&after=1527811200".format(1), headers=headers)
response = r.json()

print(json.dumps(response))
