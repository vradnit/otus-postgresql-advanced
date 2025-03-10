```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT sum(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))/1000 AS distance FROM opensky ;
                                                                                                                      QUERY PLAN                                                                                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=0.00..1371.85 rows=1 width=8) (actual time=91433.161..91433.164 rows=1 loops=1)
   Output: (sum(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)) / '1000'::double precision)
   ->  Gather Motion 24:1  (slice1; segments: 24)  (cost=0.00..1371.85 rows=1 width=8) (actual time=76944.671..91433.001 rows=24 loops=1)
         Output: (PARTIAL sum(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)))
         ->  Partial Aggregate  (cost=0.00..1371.85 rows=1 width=8) (actual time=86238.047..86238.048 rows=1 loops=1)
               Output: PARTIAL sum(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true))
               Buffers: shared hit=1503
               ->  Dynamic Seq Scan on public.opensky  (cost=0.00..838.65 rows=4812924 width=48) (actual time=1.756..6317.503 rows=5048131 loops=1)
                     Output: latitude_1, longitude_1, latitude_2, longitude_2
                     Number of partitions to scan: 50 (out of 50)
                     Partitions scanned:  Avg 50.0 x 24 workers.  Max 50 parts (seg0).
                     Buffers: shared hit=1503
 Optimizer: GPORCA
 Planning Time: 23.480 ms
   (slice0)    Executor memory: 41K bytes.
   (slice1)    Executor memory: 716K bytes avg x 24 workers, 716K bytes max (seg7).
 Memory used:  128000kB
 Execution Time: 91437.300 ms
(18 rows)

Time: 91462.463 ms (01:31.462)
otus=# 
otus=# 
otus=# SELECT sum(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))/1000 AS distance FROM opensky ;
      distance      
--------------------
 119783942240.79977
(1 row)

Time: 98788.811 ms (01:38.789)
```
