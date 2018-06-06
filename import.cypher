CALL apoc.load.jsonParams("https://www.strava.com/api/v3/athlete/activities?page=1",
  {Authorization:"Bearer <token>  "},
  null)
YIELD value

MERGE (run:Run {id: value.id})
SET run.distance = toFloat(value.distance),
    run.startDate = datetime(value.start_date_local),
    run.elapsedTime = duration("PT" + value.elapsed_time +  "S")

RETURN count(*);


MATCH (r:Run)
WITH r, "https://www.strava.com/api/v3/activities/" + r.id + "?include_all_efforts=true" AS uri
LIMIT 1
CALL apoc.load.jsonParams(uri,{Authorization:$stravaToken},null)
YIELD value
MATCH (run:Run {id: value.id})
WITH run, value
UNWIND value.best_efforts AS bestEffort
MERGE (distance:Distance {name: bestEffort.name})
ON CREATE SET distance.distance = toFloat(bestEffort.distance)
MERGE (effort:DistanceEffort {id: bestEffort.id})
ON CREATE SET effort.elapsedTime = duration({seconds: bestEffort.elapsed_time})
MERGE (effort)-[:DISTANCE]->(distance)
MERGE (run)-[:DISTANCE_EFFORT]->(effort);


CALL apoc.periodic.iterate(
  "MATCH (run:Run) RETURN run",
  "WITH run, 'https://www.strava.com/api/v3/activities/' + run.id + '?include_all_efforts=true' AS uri
   CALL apoc.load.jsonParams(uri,{Authorization:$stravaToken},null)
   YIELD value
   WITH run, value
   UNWIND value.best_efforts AS bestEffort
   MERGE (distance:Distance {name: bestEffort.name})
   ON CREATE SET distance.distance = toFloat(bestEffort.distance)
   MERGE (effort:DistanceEffort {id: bestEffort.id})
   ON CREATE SET effort.elapsedTime = duration({seconds: bestEffort.elapsed_time})
   MERGE (effort)-[:DISTANCE]->(distance)
   MERGE (run)-[:DISTANCE_EFFORT]->(effort)",
  {batchSize: 10, parallel:false, params: {stravaToken: $stravaToken}});


call apoc.periodic.commit("
WITH {`1`: 5, `2`: 5, `3`: 4, `4`:0} AS values
MATCH (import:Import)
WITH coalesce(values[toString(import.page)], 0) AS rowsReturned, import
CREATE (:Foo {page: import.page})
SET import.page = import.page+1
RETURN rowsReturned
", {});

MATCH (r:Import)
UNWIND [] AS value
SET r.page = r.page+1
RETURN CASE WHEN count(*) < 30 THEN 0 ELSE count(*) END AS `count(*)`;


call apoc.periodic.commit("
  MATCH (import:Import)
  WITH 'https://www.strava.com/api/v3/athlete/activities?page=' + import.page AS uri, import.page AS initialPage, import
  CALL apoc.load.jsonParams(uri, {Authorization: $stravaToken}, null)
  YIELD value

  MERGE (run:Run {id: value.id})
  SET run.distance = toFloat(value.distance),
      run.startDate = datetime(value.start_date_local),
      run.elapsedTime = duration({seconds: value.elapsed_time})

  WITH initialPage, import, CASE WHEN count(*) < 30 THEN 0 ELSE count(*) END AS count
  FOREACH(ignoreMe in CASE WHEN count = 0 THEN [] ELSE [1] END |
    MERGE (import)
    SET import.page = initialPage+1
  )
  RETURN count;
", {stravaToken: $stravaToken})