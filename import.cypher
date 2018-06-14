CREATE CONSTRAINT ON (d:Distance)
ASSERT d.name is UNIQUE;

CREATE CONSTRAINT ON (r:Run)
ASSERT r.id is UNIQUE;

CREATE CONSTRAINT ON (d:DistanceEffort)
ASSERT d.id is UNIQUE;

CREATE CONSTRAINT ON (s:SegmentEffort)
ASSERT s.id is UNIQUE;

CREATE CONSTRAINT ON (s:Segment)
ASSERT s.id is UNIQUE;

call apoc.periodic.commit("
  OPTIONAL MATCH (run:Run) WHERE exists(run.averageSpeed)
  WITH run ORDER BY run.startDate DESC LIMIT 1
  WITH coalesce(run.startDate.epochSeconds, 0) AS after
  WITH 'https://www.strava.com/api/v3/athlete/activities?after=' + after AS uri
  CALL apoc.load.jsonParams(uri, {Authorization: $stravaToken}, null)
  YIELD value

  MERGE (run:Run {id: value.id})
  SET run.distance = toFloat(value.distance),
      run.startDate = datetime(value.start_date_local),
      run.elapsedTime = duration({seconds: value.elapsed_time}),
      run.movingTime = duration({seconds: value.moving_time}),
      run.name = value.name,
      run.totalElevationGain = toInteger(value.total_elevation_gain),
      run.elevationHigh = toFloat(value.elev_high),
      run.elevationLow = toFloat(value.elev_low),
      run.averageSpeed = toFloat(value.average_speed),
      run.maximumSpeed = toFloat(value.max_speed)

  RETURN CASE WHEN count(*) < 30 THEN 0 ELSE count(*) END AS count
", {stravaToken: $stravaToken});


CALL apoc.periodic.iterate(
  "MATCH (run:Run) WHERE not (run)-[:DISTANCE_EFFORT]->()
   RETURN run",
  "WITH run, 'https://www.strava.com/api/v3/activities/' + run.id + '?include_all_efforts=true' AS uri
   CALL apoc.load.jsonParams(uri,{Authorization:$stravaToken},null)
   YIELD value

   WITH run, value
   UNWIND value.best_efforts AS bestEffort
   MERGE (distance:Distance {name: bestEffort.name})
   ON CREATE SET distance.distance = toFloat(bestEffort.distance)
   MERGE (effort:DistanceEffort {id: bestEffort.id})
   ON CREATE SET effort.elapsedTime = duration({seconds: bestEffort.elapsed_time}),
                 effort.movingTime = duration({seconds: bestEffort.moving_time})
   MERGE (effort)-[:DISTANCE]->(distance)
   MERGE (run)-[:DISTANCE_EFFORT]->(effort)

   WITH run, value, count(*) AS count

   UNWIND value.segment_efforts AS segmentEffort
   MERGE (segment:Segment {id: segmentEffort.segment.id})
   ON CREATE SET segment.name = segmentEffort.segment.name,
                 segment.distance = toFloat(segmentEffort.segment.distance)
   MERGE (effort:SegmentEffort {id: segmentEffort.id})
   ON CREATE SET effort.elapsedTime = duration({seconds: segmentEffort.elapsed_time}),
                 effort.movingTime = duration({seconds: segmentEffort.moving_time})
   MERGE (effort)-[:SEGMENT]->(segment)
   MERGE (run)-[:SEGMENT_EFFORT]->(effort)",
  {batchSize: 10, parallel:false, params: {stravaToken: $stravaToken}});


CALL apoc.periodic.iterate(
  "MATCH (segment:Segment) RETURN segment",
  "WITH segment, 'https://www.strava.com/api/v3/segments/' + segment.id AS uri
   CALL apoc.load.jsonParams(uri,{Authorization:$stravaToken},null)
   YIELD value
   WITH segment, value
   SET segment.averageGrade = toFloat(value.average_grade),
       segment.maximumGrade = toFloat(value.maximum_grade),
       segment.totalElevationGain = toFloat(value.total_elevation_gain),
       segment.elevationHigh = toFloat(value.elevation_high),
       segment.elevationLow = toFloat(value.elevation_low)
   ",
  {batchSize: 10, parallel:false, params: {stravaToken: $stravaToken}});

CALL apoc.periodic.iterate(
  "MATCH (segment: Segment)
   WHERE size((segment)<-[:SEGMENT]-()) > 1
   WITH segment
   RETURN segment",
  "MATCH (segment)<-[:SEGMENT]-(segmentEffort)<-[:SEGMENT_EFFORT]-(run)
   WITH segment, segmentEffort, run ORDER BY run.startDate
   WITH segment, collect(segmentEffort) AS efforts
   UNWIND range(0, size(efforts)-2)  AS index
   WITH efforts[index] AS one, efforts[index+1] AS two
   MERGE (one)-[:NEXT_EFFORT]->(two)",
   {batchSize: 10, parallel:false})