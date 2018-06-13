// Quickest runs
MATCH (r:Run)
WITH r { .id,
         .distance,
         date: apoc.date.format(r.startDate.epochSeconds, 's', 'd MMM yyyy'),
         duration: apoc.date.format(r.elapsedTime.milliseconds, 'ms', 'HH:mm:ss'),
         pace: duration({seconds: r.elapsedTime.seconds / r.distance * 1609.34})
       }

RETURN r.id, r.date, r.duration, r.distance,
       apoc.date.format(r.pace.milliseconds, "ms", "mm:ss") AS pace
ORDER BY r.pace
LIMIT 5

// Longest runs

MATCH (run:Run)
WITH run { .name, .averageSpeed, .startDate, .distance, .movingTime,
           pace: duration({seconds: run.movingTime.seconds / run.distance * 1609.34})}
RETURN run.name,
       apoc.date.format(run.startDate.epochSeconds, 's', 'MMM d yyyy') AS dateOfRun,
       run.averageSpeed,
       apoc.date.format(run.pace.milliseconds, "ms", "mm:ss") AS pace,
       apoc.date.format(run.movingTime.milliseconds, 'ms', 'HH:mm:ss') AS time,
       apoc.math.round(run.distance / 1609.34, 2) AS miles
ORDER BY miles DESC
LIMIT 25

// Quickest 5k
MATCH (distance:Distance {name: "5k"})<-[:DISTANCE]-(effort)<-[:DISTANCE_EFFORT]-(run)

WITH run { .id,
           .startDate,
           pace: duration({seconds: run.elapsedTime.seconds / run.distance * 1609.34})
         },
     effort { .elapsedTime,
              pace: duration({seconds: effort.elapsedTime.seconds / distance.distance * 1609.34  })
            }

RETURN run.id,
       apoc.date.format(run.startDate.epochSeconds, 's', 'MMM d yyyy') AS dateOfRun,
       apoc.date.format(effort.elapsedTime.milliseconds, 'ms', 'mm:ss') AS time,
       apoc.date.format(effort.pace.milliseconds, "ms", "mm:ss") AS pace,
       apoc.date.format(run.pace.milliseconds, "ms", "mm:ss") AS overallPace
ORDER BY effort.elapsedTime

// Quickest 5k by year

MATCH (distance:Distance {name: "5k"})<-[:DISTANCE]-(effort)<-[:DISTANCE_EFFORT]-(run)
WITH apoc.date.format(run.startDate.epochSeconds, 's', 'yyyy') AS year, run, effort, distance
ORDER BY year, effort.elapsedTime
WITH year, collect({run: run, effort: effort, distance: distance})[0] as bestEffort
WITH bestEffort.run AS run, bestEffort.effort AS effort, bestEffort.distance AS distance

WITH run { .id,
           .startDate,
           pace: duration({seconds: run.elapsedTime.seconds / run.distance * 1609.34})
         },
     effort { .elapsedTime,
              pace: duration({seconds: effort.elapsedTime.seconds / distance.distance * 1609.34  })
            }

RETURN run.id, apoc.date.format(run.startDate.epochSeconds, 's', 'MMM d yyyy') AS dateOfRun,
       apoc.date.format(effort.elapsedTime.milliseconds, 'ms', 'mm:ss') AS time,
       apoc.date.format(effort.pace.milliseconds, "ms", "mm:ss") AS pace,
       apoc.date.format(run.pace.milliseconds, "ms", "mm:ss") AS overallPace
ORDER BY run.startDate;

// Quickest segments

MATCH (segment:Segment {name: "Bridge Road (down)"})<-[:SEGMENT]-(effort)<-[:SEGMENT_EFFORT]-(run)

WITH run { .id,
           .startDate,
           pace: duration({seconds: run.elapsedTime.seconds / run.distance * 1609.34})
         },
     effort { .elapsedTime,
              pace: duration({seconds: effort.elapsedTime.seconds / segment.distance * 1609.34 })
            }, segment

return segment.name,
       apoc.date.format(run.startDate.epochSeconds, 's', 'MMM d yyyy') AS dateOfRun,
       apoc.date.format(effort.elapsedTime.milliseconds, 'ms', 'mm:ss') AS time,
       apoc.date.format(effort.pace.milliseconds, "ms", "mm:ss") AS pace,
       apoc.date.format(run.pace.milliseconds, "ms", "mm:ss") AS overallPace
ORDER BY effort.pace.milliseconds;

// Best effort on each segment

MATCH (segment:Segment)
WITH segment
ORDER BY segment.totalElevationGain DESC
MATCH (segment)<-[:SEGMENT]-(effort)<-[:SEGMENT_EFFORT]-(run)
WITH run { .id,
           .startDate,
           pace: duration({seconds: run.elapsedTime.seconds / run.distance * 1609.34})
         },
     effort { .elapsedTime,
              pace: duration({seconds: effort.elapsedTime.seconds / segment.distance * 1609.34 })
            }, segment
ORDER BY segment.id, segment.pace DESC

WITH segment, collect({run: run, effort: effort})[0] AS bestEffort

return segment.id AS id,
       segment.name AS name,
       segment.totalElevationGain AS totalElevationGain,
       segment.averageGrade AS averageGain,
       segment.distance AS distance,
       apoc.date.format(bestEffort.run.startDate.epochSeconds, 's', 'MMM d yyyy') AS dateOfRun,
       apoc.date.format(bestEffort.effort.elapsedTime.milliseconds, 'ms', 'mm:ss') AS time,
       apoc.date.format(bestEffort.effort.pace.milliseconds, "ms", "mm:ss") AS pace,
       apoc.date.format(bestEffort.run.pace.milliseconds, "ms", "mm:ss") AS overallPace
ORDER BY segment.averageGrade DESC

// Best effort on segment by (month, year)

MATCH (segment:Segment {name: "Bridge Road (down)"})<-[:SEGMENT]-(effort)<-[:SEGMENT_EFFORT]-(run)

WITH run { .id,
           .startDate,
           pace: duration({seconds: run.elapsedTime.seconds / run.distance * 1609.34})
         },
     effort { .elapsedTime,
              pace: duration({seconds: effort.elapsedTime.seconds / segment.distance * 1609.34 })
            }, segment

WITH run, effort
ORDER BY run.startDate.year, run.startDate.month, effort.pace
WITH run.startDate.year AS year, run.startDate.month AS month, COLLECT({run: run, effort: effort})[0] AS bestEffort
return month, year,
       apoc.date.format(bestEffort.run.startDate.epochSeconds, 's', 'MMM d yyyy') AS dateOfRun,
       apoc.date.format(bestEffort.effort.elapsedTime.milliseconds, 'ms', 'mm:ss') AS time,
       apoc.date.format(bestEffort.effort.pace.milliseconds, "ms", "mm:ss") AS pace,
       apoc.date.format(bestEffort.run.pace.milliseconds, "ms", "mm:ss") AS overallPace
ORDER BY year, month;


