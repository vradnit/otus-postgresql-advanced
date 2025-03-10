```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT origin, COUNT(*) FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC limit 10;
                                                                                 QUERY PLAN                                                                                  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..1469.97 rows=10 width=13) (actual time=4269.538..4269.552 rows=10 loops=1)
   Output: origin, (count())
   ->  Gather Motion 24:1  (slice1; segments: 24)  (cost=0.00..1469.97 rows=10 width=13) (actual time=4269.533..4269.542 rows=10 loops=1)
         Output: origin, (count())
         Merge Key: (count())
         ->  Limit  (cost=0.00..1469.97 rows=1 width=13) (actual time=4262.208..4262.219 rows=10 loops=1)
               Output: origin, (count())
               ->  Sort  (cost=0.00..1469.97 rows=137 width=13) (actual time=4262.205..4262.208 rows=10 loops=1)
                     Output: origin, (count())
                     Sort Key: (count()) DESC
                     Sort Method:  top-N heapsort  Memory: 600kB  Max Memory: 25kB  Avg Memory: 25kB (24 segments)
                     Executor Memory: 618kB  Segments: 24  Max: 26kB (segment 0)
                     work_mem: 618kB  Segments: 24  Max: 26kB (segment 0)  Workfile: (0 spilling)
                     ->  Finalize HashAggregate  (cost=0.00..1469.90 rows=137 width=13) (actual time=4260.288..4260.437 rows=741 loops=1)
                           Output: origin, count()
                           Group Key: opensky.origin
                           work_mem: 2882kB  Segments: 24  Max: 121kB (segment 0)  Workfile: (0 spilling)
                           Work_mem wanted: 121K bytes avg, 121K bytes max (seg0) to lessen workfile I/O affecting 24 workers.
                           Extra Text: (seg0)   hash table(s): 1; chain length 2.8 avg, 9 max; using 678 of 1024 buckets; total 2 expansions.
 
                           Extra Text: (seg6)   hash table(s): 1; chain length 3.5 avg, 14 max; using 741 of 1024 buckets; total 2 expansions.
 
                           ->  Redistribute Motion 24:24  (slice2; segments: 24)  (cost=0.00..1469.88 rows=137 width=13) (actual time=2181.380..4251.609 rows=13921 loops=1)
                                 Output: origin, (PARTIAL count())
                                 Hash Key: origin
                                 ->  Streaming Partial HashAggregate  (cost=0.00..1469.87 rows=137 width=13) (actual time=2175.940..2179.593 rows=13333 loops=1)
                                       Output: origin, PARTIAL count()
                                       Group Key: opensky.origin
                                       work_mem: 66178kB  Segments: 24  Max: 2849kB (segment 0)  Workfile: (0 spilling)
                                       Work_mem wanted: 2758K bytes avg, 2849K bytes max (seg0) to lessen workfile I/O affecting 24 workers.
                                       Extra Text: (seg0)   hash table(s): 1; chain length 2.3 avg, 7 max; using 13245 of 32768 buckets; total 7 expansions.
 
                                       Extra Text: (seg7)   hash table(s): 1; chain length 2.3 avg, 6 max; using 13164 of 32768 buckets; total 7 expansions.
 
                                       Buffers: shared hit=2159
                                       ->  Dynamic Seq Scan on public.opensky  (cost=0.00..1030.63 rows=3616275 width=5) (actual time=1.757..1018.324 rows=3755679 loops=1)
                                             Output: origin
                                             Number of partitions to scan: 50 (out of 50)
                                             Filter: (opensky.origin <> ''::text)
                                             Partitions scanned:  Avg 50.0 x 24 workers.  Max 50 parts (seg0).
                                             Buffers: shared hit=2159
 Optimizer: GPORCA
 Planning Time: 65.074 ms
   (slice0)    Executor memory: 99K bytes.
 * (slice1)    Executor memory: 94K bytes avg x 24 workers, 96K bytes max (seg1).  Work_mem: 121K bytes max, 121K bytes wanted.
 * (slice2)    Executor memory: 1997K bytes avg x 24 workers, 2114K bytes max (seg7).  Work_mem: 2849K bytes max, 2849K bytes wanted.
 Memory used:  128000kB
 Memory wanted:  9044kB
 Execution Time: 4274.414 ms
(49 rows)

Time: 4341.516 ms (00:04.342)
```
