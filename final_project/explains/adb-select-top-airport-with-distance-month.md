```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE firstseen >= '2019-09-01' AND firstseen < '2019-09-02' and origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
                                                                                                                                             QUERY PLAN                                                                                                                                              
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..450.93 rows=10 width=24) (actual time=297.808..297.819 rows=10 loops=1)
   Output: origin, (count()), (round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)))))
   ->  Gather Motion 24:1  (slice1; segments: 24)  (cost=0.00..450.93 rows=10 width=24) (actual time=297.802..297.808 rows=10 loops=1)
         Output: origin, (count()), (round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)))))
         Merge Key: (count())
         ->  Limit  (cost=0.00..450.93 rows=1 width=24) (actual time=296.358..296.380 rows=10 loops=1)
               Output: origin, (count()), (round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)))))
               ->  Result  (cost=0.00..450.93 rows=137 width=24) (actual time=296.355..296.367 rows=10 loops=1)
                     Output: origin, (count()), round((avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true))))
                     ->  Sort  (cost=0.00..450.91 rows=137 width=21) (actual time=296.352..296.356 rows=10 loops=1)
                           Output: (count()), (avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true))), origin
                           Sort Key: (count()) DESC
                           Sort Method:  top-N heapsort  Memory: 623kB  Max Memory: 26kB  Avg Memory: 25kB (24 segments)
                           Executor Memory: 633kB  Segments: 24  Max: 27kB (segment 0)
                           work_mem: 633kB  Segments: 24  Max: 27kB (segment 0)  Workfile: (0 spilling)
                           ->  Finalize HashAggregate  (cost=0.00..450.79 rows=137 width=21) (actual time=296.687..296.745 rows=165 loops=1)
                                 Output: count(), avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)), origin
                                 Group Key: opensky.origin
                                 work_mem: 1536kB  Segments: 24  Max: 64kB (segment 0)  Workfile: (0 spilling)
                                 Work_mem wanted: 64K bytes avg, 64K bytes max (seg0) to lessen workfile I/O affecting 24 workers.
                                 Extra Text: (seg0)   hash table(s): 1; chain length 2.2 avg, 5 max; using 112 of 256 buckets; total 0 expansions.
 
                                 Extra Text: (seg6)   hash table(s): 1; chain length 3.0 avg, 6 max; using 165 of 256 buckets; total 0 expansions.
 
                                 ->  Redistribute Motion 24:24  (slice2; segments: 24)  (cost=0.00..450.77 rows=137 width=21) (actual time=191.745..295.342 rows=910 loops=1)
                                       Output: origin, (PARTIAL count()), (PARTIAL avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true)))
                                       Hash Key: origin
                                       ->  Streaming Partial HashAggregate  (cost=0.00..450.77 rows=137 width=21) (actual time=207.572..208.183 rows=720 loops=1)
                                             Output: origin, PARTIAL count(), PARTIAL avg(st_distance((st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::geography, (st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::geography, true))
                                             Group Key: opensky.origin
                                             work_mem: 4418kB  Segments: 24  Max: 185kB (segment 0)  Workfile: (0 spilling)
                                             Work_mem wanted: 185K bytes avg, 185K bytes max (seg0) to lessen workfile I/O affecting 24 workers.
                                             Extra Text: (seg0)   hash table(s): 1; chain length 2.8 avg, 6 max; using 643 of 1024 buckets; total 2 expansions.
 
                                             Extra Text: (seg15)  hash table(s): 1; chain length 2.9 avg, 8 max; using 720 of 1024 buckets; total 2 expansions.
 
                                             Buffers: shared hit=390
                                             ->  Dynamic Seq Scan on public.opensky  (cost=0.00..450.24 rows=3950 width=61) (actual time=18.229..115.667 rows=2617 loops=1)
                                                   Output: origin, firstseen, latitude_1, longitude_1, latitude_2, longitude_2
                                                   Number of partitions to scan: 1 (out of 50)
                                                   Filter: ((opensky.firstseen >= '2019-09-01 00:00:00+00'::timestamp with time zone) AND (opensky.firstseen < '2019-09-02 00:00:00+00'::timestamp with time zone) AND (opensky.origin <> ''::text))
                                                   Partitions scanned:  Avg 1.0 x 24 workers.  Max 1 parts (seg0).
                                                   Buffers: shared hit=194
 Optimizer: GPORCA
 Planning Time: 91.866 ms
   (slice0)    Executor memory: 123K bytes.
 * (slice1)    Executor memory: 61K bytes avg x 24 workers, 64K bytes max (seg6).  Work_mem: 64K bytes max, 64K bytes wanted.
 * (slice2)    Executor memory: 975K bytes avg x 24 workers, 983K bytes max (seg15).  Work_mem: 185K bytes max, 185K bytes wanted.
 Memory used:  128000kB
 Memory wanted:  1236kB
 Execution Time: 342.829 ms
(51 rows)

Time: 436.715 ms
```
