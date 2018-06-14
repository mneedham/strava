import json
import os

import requests

token = os.environ["TOKEN"]
headers = {'Authorization': "Bearer {0}".format(token)}

# r = requests.get("https://www.strava.com/api/v3/athlete/activities?after=0", headers=headers)
r = requests.get("https://www.strava.com/api/v3/activities/{0}?include_all_efforts=true".format(1620188065), headers=headers)
# r = requests.get("https://www.strava.com/api/v3/segments/{0}".format(15799546), headers=headers)
# r = requests.get("https://www.strava.com/api/v3/activities/268166617?include_all_efforts=true", headers=headers)
response = r.json()

print(json.dumps(response))
