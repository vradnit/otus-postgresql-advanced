```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
                                                                                                                                                                                                                                                                                                                                              QUERY PLAN                                                                                                                                                                                                                                                                                                                                              
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1009.82..1009.85 rows=10 width=48) (actual time=114785.782..114785.787 rows=10 loops=1)
   Output: remote_scan.origin, (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)), (round((sum(remote_scan.distance) / (pg_catalog.sum(remote_scan.distance_1))::double precision)))
   Buffers: shared hit=100
   ->  Sort  (cost=1009.82..1010.32 rows=200 width=48) (actual time=114785.778..114785.780 rows=10 loops=1)
         Output: remote_scan.origin, (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)), (round((sum(remote_scan.distance) / (pg_catalog.sum(remote_scan.distance_1))::double precision)))
         Sort Key: (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         Buffers: shared hit=100
         ->  HashAggregate  (cost=1000.00..1005.50 rows=200 width=48) (actual time=114766.956..114781.846 rows=16917 loops=1)
               Output: remote_scan.origin, COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint), round((sum(remote_scan.distance) / (pg_catalog.sum(remote_scan.distance_1))::double precision))
               Group Key: remote_scan.origin
               Batches: 1  Memory Usage: 8993kB
               Buffers: shared hit=100
               ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=56) (actual time=114463.427..114514.656 rows=404833 loops=1)
                     Output: remote_scan.origin, remote_scan.count, remote_scan.distance, remote_scan.distance_1
                     Task Count: 32
                     Tuple data received from nodes: 11 MB
                     Tasks Shown: One of 32
                     ->  Task
                           Query: SELECT origin, count(*) AS count, sum(public.st_distance((public.st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::public.geography, (public.st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::public.geography, true)) AS distance, count(public.st_distance((public.st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::public.geography, (public.st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::public.geography, true)) AS distance FROM public.opensky_104383 opensky WHERE (origin OPERATOR(pg_catalog.<>) ''::text) GROUP BY origin
                           Tuple data received from node: 343 kB
                           Node: host=c-worker1-1 port=5432 dbname=otus
                           ->  Finalize GroupAggregate  (cost=150296.09..29556501.73 rows=2995 width=29) (actual time=23457.046..113334.980 rows=12550 loops=1)
                                 Output: opensky.origin, count(*), sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)), count(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))
                                 Group Key: opensky.origin
                                 Buffers: shared hit=22787, temp read=22468 written=22471
                                 ->  Gather Merge  (cost=150296.09..29556411.88 rows=5990 width=29) (actual time=23456.928..113280.544 rows=12550 loops=1)
                                       Output: opensky.origin, (PARTIAL count(*)), (PARTIAL sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))), (PARTIAL count(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)))
                                       Workers Planned: 2
                                       Workers Launched: 0
                                       Buffers: shared hit=22787, temp read=22468 written=22471
                                       ->  Partial GroupAggregate  (cost=149296.07..29554720.46 rows=2995 width=29) (actual time=23453.204..113270.924 rows=12550 loops=1)
                                             Output: opensky.origin, PARTIAL count(*), PARTIAL sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)), PARTIAL count(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))
                                             Group Key: opensky.origin
                                             Buffers: shared hit=22787, temp read=22468 written=22471
                                             ->  Sort  (cost=149296.07..152174.15 rows=1151234 width=53) (actual time=23424.575..26750.210 rows=2762054 loops=1)
                                                   Output: opensky.origin, opensky.longitude_1, opensky.latitude_1, opensky.longitude_2, opensky.latitude_2
                                                   Sort Key: opensky.origin
                                                   Sort Method: external merge  Disk: 179744kB
                                                   Buffers: shared hit=22653, temp read=22468 written=22471
                                                   ->  Parallel Append  (cost=0.00..10348.88 rows=1151234 width=53) (actual time=3627.130..9677.556 rows=2762054 loops=1)
                                                         Buffers: shared hit=22653
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_07_107391 opensky_44  (cost=0.00..252.10 rows=77829 width=53) (actual time=10.627..116.366 rows=77639 loops=1)
                                                               Output: opensky_44.origin, opensky_44.longitude_1, opensky_44.latitude_1, opensky_44.longitude_2, opensky_44.latitude_2
                                                               Filter: (opensky_44.origin <> ''::text)
                                                               Rows Removed by Filter: 24471
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=613
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_08_107423 opensky_45  (cost=0.00..250.85 rows=78392 width=53) (actual time=14.245..210.201 rows=78365 loops=1)
                                                               Output: opensky_45.origin, opensky_45.longitude_1, opensky_45.latitude_1, opensky_45.longitude_2, opensky_45.latitude_2
                                                               Filter: (opensky_45.origin <> ''::text)
                                                               Rows Removed by Filter: 23074
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=588
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_06_107359 opensky_43  (cost=0.00..246.39 rows=77141 width=53) (actual time=11.498..81.174 rows=77420 loops=1)
                                                               Output: opensky_43.origin, opensky_43.longitude_1, opensky_43.latitude_1, opensky_43.longitude_2, opensky_43.latitude_2
                                                               Filter: (opensky_43.origin <> ''::text)
                                                               Rows Removed by Filter: 22318
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=592
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_10_107487 opensky_47  (cost=0.00..246.05 rows=78569 width=53) (actual time=11.091..117.182 rows=78535 loops=1)
                                                               Output: opensky_47.origin, opensky_47.longitude_1, opensky_47.latitude_1, opensky_47.longitude_2, opensky_47.latitude_2
                                                               Filter: (opensky_47.origin <> ''::text)
                                                               Rows Removed by Filter: 21340
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=592
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_09_107455 opensky_46  (cost=0.00..242.43 rows=76524 width=53) (actual time=10.215..73.746 rows=76381 loops=1)
                                                               Output: opensky_46.origin, opensky_46.longitude_1, opensky_46.latitude_1, opensky_46.longitude_2, opensky_46.latitude_2
                                                               Filter: (opensky_46.origin <> ''::text)
                                                               Rows Removed by Filter: 21924
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=594
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_08_106271 opensky_9  (cost=0.00..239.00 rows=66626 width=53) (actual time=12.392..79.600 rows=66540 loops=1)
                                                               Output: opensky_9.origin, opensky_9.longitude_1, opensky_9.latitude_1, opensky_9.longitude_2, opensky_9.latitude_2
                                                               Filter: (opensky_9.origin <> ''::text)
                                                               Rows Removed by Filter: 27675
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=577
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_05_107327 opensky_42  (cost=0.00..235.10 rows=74791 width=53) (actual time=10.524..79.467 rows=74899 loops=1)
                                                               Output: opensky_42.origin, opensky_42.longitude_1, opensky_42.latitude_1, opensky_42.longitude_2, opensky_42.latitude_2
                                                               Filter: (opensky_42.origin <> ''::text)
                                                               Rows Removed by Filter: 20250
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=571
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_10_106335 opensky_11  (cost=0.00..232.10 rows=66786 width=53) (actual time=28.432..124.928 rows=66633 loops=1)
                                                               Output: opensky_11.origin, opensky_11.longitude_1, opensky_11.latitude_1, opensky_11.longitude_2, opensky_11.latitude_2
                                                               Filter: (opensky_11.origin <> ''::text)
                                                               Rows Removed by Filter: 24980
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=567
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_07_106239 opensky_8  (cost=0.00..231.02 rows=62881 width=53) (actual time=31.874..141.541 rows=62679 loops=1)
                                                               Output: opensky_8.origin, opensky_8.longitude_1, opensky_8.latitude_1, opensky_8.longitude_2, opensky_8.latitude_2
                                                               Filter: (opensky_8.origin <> ''::text)
                                                               Rows Removed by Filter: 28541
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=561
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106303 opensky_10  (cost=0.00..229.07 rows=65213 width=53) (actual time=9.501..92.602 rows=65298 loops=1)
                                                               Output: opensky_10.origin, opensky_10.longitude_1, opensky_10.latitude_1, opensky_10.longitude_2, opensky_10.latitude_2
                                                               Filter: (opensky_10.origin <> ''::text)
                                                               Rows Removed by Filter: 25158
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=558
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_07_107007 opensky_32  (cost=0.00..221.29 rows=69359 width=53) (actual time=10.571..81.814 rows=69211 loops=1)
                                                               Output: opensky_32.origin, opensky_32.longitude_1, opensky_32.latitude_1, opensky_32.longitude_2, opensky_32.latitude_2
                                                               Filter: (opensky_32.origin <> ''::text)
                                                               Rows Removed by Filter: 21045
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=523
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_11_107519 opensky_48  (cost=0.00..219.64 rows=70346 width=53) (actual time=63.609..231.724 rows=70205 loops=1)
                                                               Output: opensky_48.origin, opensky_48.longitude_1, opensky_48.latitude_1, opensky_48.longitude_2, opensky_48.latitude_2
                                                               Filter: (opensky_48.origin <> ''::text)
                                                               Rows Removed by Filter: 19631
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=535
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_04_107295 opensky_41  (cost=0.00..218.18 rows=69442 width=53) (actual time=11.941..75.578 rows=69123 loops=1)
                                                               Output: opensky_41.origin, opensky_41.longitude_1, opensky_41.latitude_1, opensky_41.longitude_2, opensky_41.latitude_2
                                                               Filter: (opensky_41.origin <> ''::text)
                                                               Rows Removed by Filter: 19379
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=530
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_08_107039 opensky_33  (cost=0.00..217.92 rows=68020 width=53) (actual time=12.727..80.011 rows=67736 loops=1)
                                                               Output: opensky_33.origin, opensky_33.longitude_1, opensky_33.latitude_1, opensky_33.longitude_2, opensky_33.latitude_2
                                                               Filter: (opensky_33.origin <> ''::text)
                                                               Rows Removed by Filter: 20330
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=527
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_12_106399 opensky_13  (cost=0.00..216.58 rows=61951 width=53) (actual time=11.034..89.499 rows=62022 loops=1)
                                                               Output: opensky_13.origin, opensky_13.longitude_1, opensky_13.latitude_1, opensky_13.longitude_2, opensky_13.latitude_2
                                                               Filter: (opensky_13.origin <> ''::text)
                                                               Rows Removed by Filter: 23433
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=527
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_03_107263 opensky_40  (cost=0.00..216.31 rows=68409 width=53) (actual time=29.708..169.550 rows=68448 loops=1)
                                                               Output: opensky_40.origin, opensky_40.longitude_1, opensky_40.latitude_1, opensky_40.longitude_2, opensky_40.latitude_2
                                                               Filter: (opensky_40.origin <> ''::text)
                                                               Rows Removed by Filter: 18776
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=524
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_01_106431 opensky_14  (cost=0.00..215.99 rows=60857 width=53) (actual time=10.331..109.852 rows=60824 loops=1)
                                                               Output: opensky_14.origin, opensky_14.longitude_1, opensky_14.latitude_1, opensky_14.longitude_2, opensky_14.latitude_2
                                                               Filter: (opensky_14.origin <> ''::text)
                                                               Rows Removed by Filter: 23165
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=521
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_11_106367 opensky_12  (cost=0.00..215.49 rows=62743 width=53) (actual time=10.995..126.284 rows=62410 loops=1)
                                                               Output: opensky_12.origin, opensky_12.longitude_1, opensky_12.latitude_1, opensky_12.longitude_2, opensky_12.latitude_2
                                                               Filter: (opensky_12.origin <> ''::text)
                                                               Rows Removed by Filter: 22555
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=524
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_10_107103 opensky_35  (cost=0.00..215.21 rows=66671 width=53) (actual time=9.366..68.499 rows=66555 loops=1)
                                                               Output: opensky_35.origin, opensky_35.longitude_1, opensky_35.latitude_1, opensky_35.longitude_2, opensky_35.latitude_2
                                                               Filter: (opensky_35.origin <> ''::text)
                                                               Rows Removed by Filter: 20229
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=520
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_06_106207 opensky_7  (cost=0.00..213.33 rows=57873 width=53) (actual time=26.875..145.208 rows=58101 loops=1)
                                                               Output: opensky_7.origin, opensky_7.longitude_1, opensky_7.latitude_1, opensky_7.longitude_2, opensky_7.latitude_2
                                                               Filter: (opensky_7.origin <> ''::text)
                                                               Rows Removed by Filter: 26364
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=521
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_09_107071 opensky_34  (cost=0.00..211.37 rows=66138 width=53) (actual time=30.638..122.894 rows=66128 loops=1)
                                                               Output: opensky_34.origin, opensky_34.longitude_1, opensky_34.latitude_1, opensky_34.longitude_2, opensky_34.latitude_2
                                                               Filter: (opensky_34.origin <> ''::text)
                                                               Rows Removed by Filter: 19332
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=515
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_12_107551 opensky_49  (cost=0.00..207.07 rows=64978 width=53) (actual time=9.144..140.423 rows=65420 loops=1)
                                                               Output: opensky_49.origin, opensky_49.longitude_1, opensky_49.latitude_1, opensky_49.longitude_2, opensky_49.latitude_2
                                                               Filter: (opensky_49.origin <> ''::text)
                                                               Rows Removed by Filter: 19192
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=490
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_02_106463 opensky_15  (cost=0.00..206.67 rows=61117 width=53) (actual time=11.202..145.261 rows=61028 loops=1)
                                                               Output: opensky_15.origin, opensky_15.longitude_1, opensky_15.latitude_1, opensky_15.longitude_2, opensky_15.latitude_2
                                                               Filter: (opensky_15.origin <> ''::text)
                                                               Rows Removed by Filter: 20235
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=507
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_12_107167 opensky_37  (cost=0.00..201.43 rows=62705 width=53) (actual time=26.706..187.623 rows=62690 loops=1)
                                                               Output: opensky_37.origin, opensky_37.longitude_1, opensky_37.latitude_1, opensky_37.longitude_2, opensky_37.latitude_2
                                                               Filter: (opensky_37.origin <> ''::text)
                                                               Rows Removed by Filter: 19007
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=499
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_05_106175 opensky_6  (cost=0.00..200.28 rows=54791 width=53) (actual time=30.953..151.689 rows=54927 loops=1)
                                                               Output: opensky_6.origin, opensky_6.longitude_1, opensky_6.latitude_1, opensky_6.longitude_2, opensky_6.latitude_2
                                                               Filter: (opensky_6.origin <> ''::text)
                                                               Rows Removed by Filter: 24428
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=488
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_11_107135 opensky_36  (cost=0.00..196.84 rows=62158 width=53) (actual time=25.713..161.615 rows=62175 loops=1)
                                                               Output: opensky_36.origin, opensky_36.longitude_1, opensky_36.latitude_1, opensky_36.longitude_2, opensky_36.latitude_2
                                                               Filter: (opensky_36.origin <> ''::text)
                                                               Rows Removed by Filter: 18016
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=479
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_06_106975 opensky_31  (cost=0.00..195.01 rows=61252 width=53) (actual time=12.198..106.038 rows=61374 loops=1)
                                                               Output: opensky_31.origin, opensky_31.longitude_1, opensky_31.latitude_1, opensky_31.longitude_2, opensky_31.latitude_2
                                                               Filter: (opensky_31.origin <> ''::text)
                                                               Rows Removed by Filter: 18460
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=477
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_01_107199 opensky_38  (cost=0.00..188.56 rows=57920 width=53) (actual time=24.932..99.140 rows=57792 loops=1)
                                                               Output: opensky_38.origin, opensky_38.longitude_1, opensky_38.latitude_1, opensky_38.longitude_2, opensky_38.latitude_2
                                                               Filter: (opensky_38.origin <> ''::text)
                                                               Rows Removed by Filter: 18366
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=463
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_04_106143 opensky_5  (cost=0.00..186.14 rows=49532 width=53) (actual time=9.582..72.143 rows=49594 loops=1)
                                                               Output: opensky_5.origin, opensky_5.longitude_1, opensky_5.latitude_1, opensky_5.longitude_2, opensky_5.latitude_2
                                                               Filter: (opensky_5.origin <> ''::text)
                                                               Rows Removed by Filter: 24074
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=465
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2022_02_107231 opensky_39  (cost=0.00..182.13 rows=57487 width=53) (actual time=9.434..92.153 rows=57212 loops=1)
                                                               Output: opensky_39.origin, opensky_39.longitude_1, opensky_39.latitude_1, opensky_39.longitude_2, opensky_39.latitude_2
                                                               Filter: (opensky_39.origin <> ''::text)
                                                               Rows Removed by Filter: 16365
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=451
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_03_106111 opensky_4  (cost=0.00..177.79 rows=48721 width=53) (actual time=26.703..157.449 rows=48507 loops=1)
                                                               Output: opensky_4.origin, opensky_4.longitude_1, opensky_4.latitude_1, opensky_4.longitude_2, opensky_4.latitude_2
                                                               Filter: (opensky_4.origin <> ''::text)
                                                               Rows Removed by Filter: 22048
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=447
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_05_106943 opensky_30  (cost=0.00..174.88 rows=54400 width=53) (actual time=10.586..182.484 rows=54366 loops=1)
                                                               Output: opensky_30.origin, opensky_30.longitude_1, opensky_30.latitude_1, opensky_30.longitude_2, opensky_30.latitude_2
                                                               Filter: (opensky_30.origin <> ''::text)
                                                               Rows Removed by Filter: 16378
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=440
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_04_106911 opensky_29  (cost=0.00..170.30 rows=52460 width=53) (actual time=25.297..144.789 rows=52554 loops=1)
                                                               Output: opensky_29.origin, opensky_29.longitude_1, opensky_29.latitude_1, opensky_29.longitude_2, opensky_29.latitude_2
                                                               Filter: (opensky_29.origin <> ''::text)
                                                               Rows Removed by Filter: 16426
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=418
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_03_106495 opensky_16  (cost=0.00..168.42 rows=50005 width=53) (actual time=22.224..84.007 rows=50052 loops=1)
                                                               Output: opensky_16.origin, opensky_16.longitude_1, opensky_16.latitude_1, opensky_16.longitude_2, opensky_16.latitude_2
                                                               Filter: (opensky_16.origin <> ''::text)
                                                               Rows Removed by Filter: 16271
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=414
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_01_106047 opensky_2  (cost=0.00..167.77 rows=46592 width=53) (actual time=9.591..112.144 rows=46642 loops=1)
                                                               Output: opensky_2.origin, opensky_2.longitude_1, opensky_2.latitude_1, opensky_2.longitude_2, opensky_2.latitude_2
                                                               Filter: (opensky_2.origin <> ''::text)
                                                               Rows Removed by Filter: 19862
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=420
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_08_106655 opensky_21  (cost=0.00..165.62 rows=49195 width=53) (actual time=8.502..60.153 rows=49125 loops=1)
                                                               Output: opensky_21.origin, opensky_21.longitude_1, opensky_21.latitude_1, opensky_21.longitude_2, opensky_21.latitude_2
                                                               Filter: (opensky_21.origin <> ''::text)
                                                               Rows Removed by Filter: 16031
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=411
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_03_106879 opensky_28  (cost=0.00..159.61 rows=49547 width=53) (actual time=9.611..55.520 rows=49589 loops=1)
                                                               Output: opensky_28.origin, opensky_28.longitude_1, opensky_28.latitude_1, opensky_28.longitude_2, opensky_28.latitude_2
                                                               Filter: (opensky_28.origin <> ''::text)
                                                               Rows Removed by Filter: 14973
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=397
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_10_106719 opensky_23  (cost=0.00..157.62 rows=47879 width=53) (actual time=9.361..58.097 rows=47960 loops=1)
                                                               Output: opensky_23.origin, opensky_23.longitude_1, opensky_23.latitude_1, opensky_23.longitude_2, opensky_23.latitude_2
                                                               Filter: (opensky_23.origin <> ''::text)
                                                               Rows Removed by Filter: 14832
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=400
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_09_106687 opensky_22  (cost=0.00..156.68 rows=47023 width=53) (actual time=9.254..53.993 rows=47007 loops=1)
                                                               Output: opensky_22.origin, opensky_22.longitude_1, opensky_22.latitude_1, opensky_22.longitude_2, opensky_22.latitude_2
                                                               Filter: (opensky_22.origin <> ''::text)
                                                               Rows Removed by Filter: 14495
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=397
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2019_02_106079 opensky_3  (cost=0.00..156.55 rows=43857 width=53) (actual time=25.685..84.852 rows=44091 loops=1)
                                                               Output: opensky_3.origin, opensky_3.longitude_1, opensky_3.latitude_1, opensky_3.longitude_2, opensky_3.latitude_2
                                                               Filter: (opensky_3.origin <> ''::text)
                                                               Rows Removed by Filter: 17931
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=398
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_07_106623 opensky_20  (cost=0.00..153.14 rows=45244 width=53) (actual time=30.494..146.093 rows=45276 loops=1)
                                                               Output: opensky_20.origin, opensky_20.longitude_1, opensky_20.latitude_1, opensky_20.longitude_2, opensky_20.latitude_2
                                                               Filter: (opensky_20.origin <> ''::text)
                                                               Rows Removed by Filter: 15207
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=390
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_12_106783 opensky_25  (cost=0.00..149.08 rows=44142 width=53) (actual time=27.266..143.780 rows=44116 loops=1)
                                                               Output: opensky_25.origin, opensky_25.longitude_1, opensky_25.latitude_1, opensky_25.longitude_2, opensky_25.latitude_2
                                                               Filter: (opensky_25.origin <> ''::text)
                                                               Rows Removed by Filter: 15418
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=371
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_11_106751 opensky_24  (cost=0.00..143.56 rows=43141 width=53) (actual time=24.335..153.759 rows=43155 loops=1)
                                                               Output: opensky_24.origin, opensky_24.longitude_1, opensky_24.latitude_1, opensky_24.longitude_2, opensky_24.latitude_2
                                                               Filter: (opensky_24.origin <> ''::text)
                                                               Rows Removed by Filter: 14269
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=362
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_01_106815 opensky_26  (cost=0.00..138.37 rows=41815 width=53) (actual time=8.432..113.270 rows=41846 loops=1)
                                                               Output: opensky_26.origin, opensky_26.longitude_1, opensky_26.latitude_1, opensky_26.longitude_2, opensky_26.latitude_2
                                                               Filter: (opensky_26.origin <> ''::text)
                                                               Rows Removed by Filter: 14049
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=349
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2021_02_106847 opensky_27  (cost=0.00..125.83 rows=38552 width=53) (actual time=9.097..48.040 rows=38511 loops=1)
                                                               Output: opensky_27.origin, opensky_27.longitude_1, opensky_27.latitude_1, opensky_27.longitude_2, opensky_27.latitude_2
                                                               Filter: (opensky_27.origin <> ''::text)
                                                               Rows Removed by Filter: 12369
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=328
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_06_106591 opensky_19  (cost=0.00..114.28 rows=35235 width=53) (actual time=8.011..38.011 rows=35235 loops=1)
                                                               Output: opensky_19.origin, opensky_19.longitude_1, opensky_19.latitude_1, opensky_19.longitude_2, opensky_19.latitude_2
                                                               Filter: (opensky_19.origin <> ''::text)
                                                               Rows Removed by Filter: 10757
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=300
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_05_106559 opensky_18  (cost=0.00..83.30 rows=26315 width=53) (actual time=6.761..28.139 rows=26316 loops=1)
                                                               Output: opensky_18.origin, opensky_18.longitude_1, opensky_18.latitude_1, opensky_18.longitude_2, opensky_18.latitude_2
                                                               Filter: (opensky_18.origin <> ''::text)
                                                               Rows Removed by Filter: 7277
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=235
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2020_04_106527 opensky_17  (cost=0.00..64.85 rows=20233 width=53) (actual time=6.799..22.785 rows=20237 loops=1)
                                                               Output: opensky_17.origin, opensky_17.longitude_1, opensky_17.latitude_1, opensky_17.longitude_2, opensky_17.latitude_2
                                                               Filter: (opensky_17.origin <> ''::text)
                                                               Rows Removed by Filter: 5880
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=186
                                                         ->  Custom Scan (ColumnarScan) on public.opensky_p2018_12_106015 opensky_1  (cost=0.00..0.43 rows=104 width=53) (actual time=3627.114..3627.254 rows=105 loops=1)
                                                               Output: opensky_1.origin, opensky_1.longitude_1, opensky_1.latitude_1, opensky_1.longitude_2, opensky_1.latitude_2
                                                               Filter: (opensky_1.origin <> ''::text)
                                                               Rows Removed by Filter: 29
                                                               Columnar Projected Columns: origin, latitude_1, longitude_1, latitude_2, longitude_2
                                                               Buffers: shared hit=91
                                                         ->  Seq Scan on public.opensky_p2023_01_105983 opensky_50  (cost=0.00..0.00 rows=1 width=160) (actual time=0.013..0.013 rows=0 loops=1)
                                                               Output: opensky_50.origin, opensky_50.longitude_1, opensky_50.latitude_1, opensky_50.longitude_2, opensky_50.latitude_2
                                                               Filter: (opensky_50.origin <> ''::text)
                               Planning Time: 43.930 ms
                               JIT:
                                 Functions: 110
                                 Options: Inlining true, Optimization true, Expressions true, Deforming true
                                 Timing: Generation 9.654 ms, Inlining 332.660 ms, Optimization 1994.520 ms, Emission 1301.663 ms, Total 3638.496 ms
                               Execution Time: 113488.963 ms
                     Buffers: shared hit=100
 Planning:
   Buffers: shared hit=24
 Planning Time: 3.624 ms
 Execution Time: 114791.711 ms
(350 rows)

Time: 114816.184 ms (01:54.816)
```
