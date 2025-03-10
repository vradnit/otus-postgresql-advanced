```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT COUNT(*) FROM opensky;
                                                                    QUERY PLAN                                                                     
---------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=0.00..847.61 rows=1 width=8) (actual time=2566.748..2566.752 rows=1 loops=1)
   Output: count()
   ->  Gather Motion 24:1  (slice1; segments: 24)  (cost=0.00..847.61 rows=1 width=8) (actual time=1744.995..2566.601 rows=24 loops=1)
         Output: (PARTIAL count())
         ->  Partial Aggregate  (cost=0.00..847.61 rows=1 width=8) (actual time=2309.909..2309.910 rows=1 loops=1)
               Output: PARTIAL count()
               Buffers: shared hit=907
               ->  Dynamic Seq Scan on public.opensky  (cost=0.00..838.65 rows=4812924 width=1) (actual time=0.857..1626.678 rows=5048131 loops=1)
                     Number of partitions to scan: 50 (out of 50)
                     Partitions scanned:  Avg 50.0 x 24 workers.  Max 50 parts (seg0).
                     Buffers: shared hit=907
 Optimizer: GPORCA
 Planning Time: 9.217 ms
   (slice0)    Executor memory: 34K bytes.
   (slice1)    Executor memory: 298K bytes avg x 24 workers, 298K bytes max (seg0).
 Memory used:  128000kB
 Execution Time: 2569.760 ms
(17 rows)

Time: 2580.703 ms (00:02.581)
```
