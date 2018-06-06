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

// Quickest 5k
MATCH (distance:Distance {name: "5k"})<-[:DISTANCE]-(effort)<-[:DISTANCE_EFFORT]-(run)

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
ORDER BY run.startDate