```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE firstseen >= '2019-09-01' AND firstseen < '2019-09-02' and origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
                                                                                                                                                                                                                                                                                                                                                                                                                                         QUERY PLAN                                                                                                                                                                                                                                                                                                                                                                                                                                          
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1009.82..1009.85 rows=10 width=48) (actual time=708.631..708.636 rows=10 loops=1)
   Output: remote_scan.origin, (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)), (round((sum(remote_scan.distance) / (pg_catalog.sum(remote_scan.distance_1))::double precision)))
   Buffers: shared hit=100
   ->  Sort  (cost=1009.82..1010.32 rows=200 width=48) (actual time=708.628..708.630 rows=10 loops=1)
         Output: remote_scan.origin, (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)), (round((sum(remote_scan.distance) / (pg_catalog.sum(remote_scan.distance_1))::double precision)))
         Sort Key: (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         Buffers: shared hit=100
         ->  HashAggregate  (cost=1000.00..1005.50 rows=200 width=48) (actual time=704.053..707.510 rows=3360 loops=1)
               Output: remote_scan.origin, COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint), round((sum(remote_scan.distance) / (pg_catalog.sum(remote_scan.distance_1))::double precision))
               Group Key: remote_scan.origin
               Batches: 1  Memory Usage: 1153kB
               Buffers: shared hit=100
               ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=56) (actual time=689.719..691.885 rows=17870 loops=1)
                     Output: remote_scan.origin, remote_scan.count, remote_scan.distance, remote_scan.distance_1
                     Task Count: 32
                     Tuple data received from nodes: 489 kB
                     Tasks Shown: One of 32
                     ->  Task
                           Query: SELECT origin, count(*) AS count, sum(public.st_distance((public.st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::public.geography, (public.st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::public.geography, true)) AS distance, count(public.st_distance((public.st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::public.geography, (public.st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::public.geography, true)) AS distance FROM public.opensky_104388 opensky WHERE ((firstseen OPERATOR(pg_catalog.>=) '2019-09-01 00:00:00+00'::timestamp with time zone) AND (firstseen OPERATOR(pg_catalog.<) '2019-09-02 00:00:00+00'::timestamp with time zone) AND (origin OPERATOR(pg_catalog.<>) ''::text)) GROUP BY origin
                           Tuple data received from node: 16 kB
                           Node: host=c-worker3-1 port=5432 dbname=otus
                           ->  Finalize GroupAggregate  (cost=1203.24..31545.50 rows=2008 width=29) (actual time=53.256..125.082 rows=578 loops=1)
                                 Output: opensky.origin, count(*), sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)), count(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))
                                 Group Key: opensky.origin
                                 Buffers: shared hit=458
                                 ->  Gather Merge  (cost=1203.24..31513.61 rows=1181 width=29) (actual time=53.203..123.395 rows=578 loops=1)
                                       Output: opensky.origin, (PARTIAL count(*)), (PARTIAL sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))), (PARTIAL count(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)))
                                       Workers Planned: 1
                                       Workers Launched: 1
                                       Buffers: shared hit=458
                                       ->  Partial GroupAggregate  (cost=203.23..30380.73 rows=1181 width=29) (actual time=25.319..60.175 rows=289 loops=2)
                                             Output: opensky.origin, PARTIAL count(*), PARTIAL sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)), PARTIAL count(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))
                                             Group Key: opensky.origin
                                             Buffers: shared hit=458
                                             Worker 0:  actual time=0.558..0.560 rows=0 loops=1
                                               Buffers: shared hit=58
                                             ->  Sort  (cost=203.23..206.18 rows=1181 width=53) (actual time=10.751..11.158 rows=948 loops=2)
                                                   Output: opensky.origin, opensky.longitude_1, opensky.latitude_1, opensky.longitude_2, opensky.latitude_2
                                                   Sort Key: opensky.origin
                                                   Sort Method: quicksort  Memory: 208kB
                                                   Buffers: shared hit=324
                                                   Worker 0:  actual time=0.556..0.557 rows=0 loops=1
                                                     Sort Method: quicksort  Memory: 25kB
                                                     Buffers: shared hit=58
                                                   ->  Parallel Append  (cost=0.00..142.97 rows=1181 width=53) (actual time=6.903..8.902 rows=948 loops=2)
                                                         Buffers: shared hit=266
                                                         Worker 0:  actual time=0.002..0.003 rows=0 loops=1
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106308 opensky_1  (cost=0.00..137.06 rows=2008 width=53) (actual time=13.801..17.325 rows=1896 loops=1)
                                                               Output: opensky_1.origin, opensky_1.longitude_1, opensky_1.latitude_1, opensky_1.longitude_2, opensky_1.latitude_2
                                                               Filter: ((opensky_1.firstseen >= '2019-09-01 00:00:00+00'::timestamp with time zone) AND (opensky_1.firstseen < '2019-09-02 00:00:00+00'::timestamp with time zone) AND (opensky_1.origin <> ''::text))
                                                               Rows Removed by Filter: 8104
                                                               Columnar Projected Columns: origin, firstseen, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Columnar Chunk Group Filters: ((firstseen >= '2019-09-01 00:00:00+00'::timestamp with time zone) AND (firstseen < '2019-09-02 00:00:00+00'::timestamp with time zone))
                                                               Columnar Chunk Groups Removed by Filter: 9
                                                               Buffers: shared hit=266
                               Planning Time: 17.049 ms
                               Execution Time: 139.621 ms
                     Buffers: shared hit=100
 Planning:
   Buffers: shared hit=24
 Planning Time: 2.492 ms
 Execution Time: 708.994 ms
(63 rows)

Time: 724.121 ms
```
