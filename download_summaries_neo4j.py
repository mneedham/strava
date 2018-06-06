import os

from neo4j.v1 import GraphDatabase

neo = "neo"

driver = GraphDatabase.driver("bolt://localhost", auth=("neo4j", neo))
with driver.session() as session:
    page = 1
    while True:
        result = session.run("""\
        WITH "https://www.strava.com/api/v3/athlete/activities?page=" + $page AS uri
        CALL apoc.load.jsonParams(uri, {Authorization: $stravaToken}, null)
        YIELD value

        MERGE (run:Run {id: value.id})
        SET run.distance = toFloat(value.distance),
            run.startDate = datetime(value.start_date_local),
            run.elapsedTime = duration({seconds: value.elapsed_time})
        
        RETURN count(*) AS count
        """, {"page": page, "stravaToken": "Bearer {0}".format(os.environ["TOKEN"])})

        runs_imported = result.peek()["count"]
        print("Runs imported:", runs_imported)
        if runs_imported == 0:
            break
        else:
            page += 1
