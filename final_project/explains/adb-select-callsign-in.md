```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=0.00..997.00 rows=1 width=8) (actual time=1462.448..1462.450 rows=1 loops=1)
   Output: count()
   ->  Gather Motion 24:1  (slice1; segments: 24)  (cost=0.00..997.00 rows=1 width=8) (actual time=1193.553..1462.346 rows=24 loops=1)
         Output: (PARTIAL count())
         ->  Partial Aggregate  (cost=0.00..997.00 rows=1 width=8) (actual time=1279.863..1279.865 rows=1 loops=1)
               Output: PARTIAL count()
               Buffers: shared hit=907
               ->  Dynamic Seq Scan on public.opensky  (cost=0.00..997.00 rows=82 width=7) (actual time=180.218..1389.969 rows=16 loops=1)
                     Output: callsign
                     Number of partitions to scan: 50 (out of 50)
                     Filter: (opensky.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                     Partitions scanned:  Avg 50.0 x 24 workers.  Max 50 parts (seg0).
                     Buffers: shared hit=907
 Optimizer: GPORCA
 Planning Time: 57.874 ms
   (slice0)    Executor memory: 36K bytes.
   (slice1)    Executor memory: 372K bytes avg x 24 workers, 372K bytes max (seg1).
 Memory used:  128000kB
 Execution Time: 1465.209 ms
(19 rows)

Time: 1524.658 ms (00:01.525)
```
