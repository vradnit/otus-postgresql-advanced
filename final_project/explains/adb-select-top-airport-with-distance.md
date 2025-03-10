```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
                                                                                                                                             QUERY PLAN                                                                                                  
                                            
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------
 Limit  (cost=0.00..1796.15 rows=10 width=24) (actual time=79707.683..79707.701 rows=10 loops=1)
   Output: origin, (count()), (round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)))))
   ->  Gather Motion 24:1  (slice1; segments: 24)  (cost=0.00..1796.15 rows=10 width=24) (actual time=79707.678..79707.689 rows=10 loops=1)
         Output: origin, (count()), (round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)
))))
         Merge Key: (count())
         ->  Limit  (cost=0.00..1796.15 rows=1 width=24) (actual time=79705.194..79705.206 rows=10 loops=1)
               Output: origin, (count()), (round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography,
 true)))))
               ->  Result  (cost=0.00..1796.15 rows=137 width=24) (actual time=79705.192..79705.198 rows=10 loops=1)
                     Output: origin, (count()), round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geogr
aphy, true))))
                     ->  Sort  (cost=0.00..1796.13 rows=137 width=21) (actual time=79705.190..79705.192 rows=10 loops=1)
                           Output: (count()), (avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, tr
ue))), origin
                           Sort Key: (count()) DESC
                           Sort Method:  top-N heapsort  Memory: 624kB  Max Memory: 26kB  Avg Memory: 26kB (24 segments)
                           Executor Memory: 633kB  Segments: 24  Max: 27kB (segment 0)
                           work_mem: 633kB  Segments: 24  Max: 27kB (segment 0)  Workfile: (0 spilling)
                           ->  Finalize HashAggregate  (cost=0.00..1796.02 rows=137 width=21) (actual time=79705.102..79705.789 rows=741 loops=1)
                                 Output: count(), avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography,
 true)), origin
                                 Group Key: opensky.origin
                                 work_mem: 4418kB  Segments: 24  Max: 185kB (segment 0)  Workfile: (0 spilling)
                                 Work_mem wanted: 185K bytes avg, 185K bytes max (seg0) to lessen workfile I/O affecting 24 workers.
                                 Extra Text: (seg0)   hash table(s): 1; chain length 2.8 avg, 9 max; using 678 of 1024 buckets; total 2 expansions.
 
                                 Extra Text: (seg6)   hash table(s): 1; chain length 3.5 avg, 14 max; using 741 of 1024 buckets; total 2 expansions.
 
                                 ->  Redistribute Motion 24:24  (slice2; segments: 24)  (cost=0.00..1796.00 rows=137 width=21) (actual time=68273.906..79689.147 rows=13921 loops=1)
                                       Output: origin, (PARTIAL count()), (PARTIAL avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2
)::double precision))::geography, true)))
                                       Hash Key: origin
                                       ->  Streaming Partial HashAggregate  (cost=0.00..1795.99 rows=137 width=21) (actual time=74441.820..74449.896 rows=13333 loops=1)
                                             Output: origin, PARTIAL count(), PARTIAL avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitud
e_2)::double precision))::geography, true))
                                             Group Key: opensky.origin
                                             work_mem: 116354kB  Segments: 24  Max: 4897kB (segment 0)  Workfile: (0 spilling)
                                             Work_mem wanted: 4849K bytes avg, 4897K bytes max (seg0) to lessen workfile I/O affecting 24 workers.
                                             Extra Text: (seg0)   hash table(s): 1; chain length 2.3 avg, 7 max; using 13245 of 32768 buckets; total 7 expansions.
 
                                             Buffers: shared hit=5868
                                             ->  Dynamic Seq Scan on public.opensky  (cost=0.00..1353.49 rows=3616275 width=53) (actual time=10.283..6887.173 rows=3755679 loops=1)
                                                   Output: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                   Number of partitions to scan: 50 (out of 50)
                                                   Filter: (opensky.origin <> ''::text)
                                                   Partitions scanned:  Avg 50.0 x 24 workers.  Max 50 parts (seg0).
                                                   Buffers: shared hit=5672
 Optimizer: GPORCA
 Planning Time: 38.226 ms
   (slice0)    Executor memory: 122K bytes.
 * (slice1)    Executor memory: 158K bytes avg x 24 workers, 162K bytes max (seg6).  Work_mem: 185K bytes max, 185K bytes wanted.
 * (slice2)    Executor memory: 3554K bytes avg x 24 workers, 3704K bytes max (seg7).  Work_mem: 4897K bytes max, 4897K bytes wanted.
 Memory used:  128000kB
 Memory wanted:  20084kB
 Execution Time: 79742.008 ms
(49 rows)

Time: 79782.364 ms (01:19.782)
```
