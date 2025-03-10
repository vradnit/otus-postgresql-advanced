```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT sum(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))/1000 AS distance FROM opensky ;
                                                                                                                                                               QUERY PLAN                                                                                                                                                                
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=250.00..250.01 rows=1 width=8) (actual time=107532.777..107532.779 rows=1 loops=1)
   Output: (sum(remote_scan.distance) / '1000'::double precision)
   Buffers: shared hit=100
   ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=8) (actual time=107532.752..107532.756 rows=32 loops=1)
         Output: remote_scan.distance
         Task Count: 32
         Tuple data received from nodes: 256 bytes
         Tasks Shown: One of 32
         ->  Task
               Query: SELECT sum(public.st_distance((public.st_makepoint((longitude_1)::double precision, (latitude_1)::double precision))::public.geography, (public.st_makepoint((longitude_2)::double precision, (latitude_2)::double precision))::public.geography, true)) AS distance FROM public.opensky_104401 opensky WHERE true
               Tuple data received from node: 8 bytes
               Node: host=c-worker1-1 port=5432 dbname=otus
               ->  Finalize Aggregate  (cost=19764334.23..19764334.24 rows=1 width=8) (actual time=105386.260..105386.662 rows=1 loops=1)
                     Output: sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))
                     Buffers: shared hit=21284
                     ->  Gather  (cost=19764334.01..19764334.22 rows=2 width=8) (actual time=105386.238..105386.641 rows=1 loops=1)
                           Output: (PARTIAL sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true)))
                           Workers Planned: 2
                           Workers Launched: 0
                           Buffers: shared hit=21284
                           ->  Partial Aggregate  (cost=19763334.01..19763334.02 rows=1 width=8) (actual time=105382.088..105382.122 rows=1 loops=1)
                                 Output: PARTIAL sum(st_distance((st_makepoint((opensky.longitude_1)::double precision, (opensky.latitude_1)::double precision))::geography, (st_makepoint((opensky.longitude_2)::double precision, (opensky.latitude_2)::double precision))::geography, true))
                                 Buffers: shared hit=21284
                                 ->  Parallel Append  (cost=0.00..11449.74 rows=1547044 width=48) (actual time=1218.173..8762.577 rows=3712904 loops=1)
                                       Buffers: shared hit=21145
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_08_107441 opensky_45  (cost=0.00..204.19 rows=103149 width=48) (actual time=11.758..67.603 rows=103149 loops=1)
                                             Output: opensky_45.longitude_1, opensky_45.latitude_1, opensky_45.longitude_2, opensky_45.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=549
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_07_107409 opensky_44  (cost=0.00..202.81 rows=102698 width=48) (actual time=11.647..64.176 rows=102698 loops=1)
                                             Output: opensky_44.longitude_1, opensky_44.latitude_1, opensky_44.longitude_2, opensky_44.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=568
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_06_107377 opensky_43  (cost=0.00..199.65 rows=100859 width=48) (actual time=11.770..72.137 rows=100859 loops=1)
                                             Output: opensky_43.longitude_1, opensky_43.latitude_1, opensky_43.longitude_2, opensky_43.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=561
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_10_107505 opensky_47  (cost=0.00..197.97 rows=100433 width=48) (actual time=11.267..107.234 rows=100433 loops=1)
                                             Output: opensky_47.longitude_1, opensky_47.latitude_1, opensky_47.longitude_2, opensky_47.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=558
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_08_106289 opensky_9  (cost=0.00..193.53 rows=95319 width=48) (actual time=11.621..65.418 rows=95319 loops=1)
                                             Output: opensky_9.longitude_1, opensky_9.latitude_1, opensky_9.longitude_2, opensky_9.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=540
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_09_107473 opensky_46  (cost=0.00..193.35 rows=97994 width=48) (actual time=11.057..100.960 rows=97994 loops=1)
                                             Output: opensky_46.longitude_1, opensky_46.latitude_1, opensky_46.longitude_2, opensky_46.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=542
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_05_107345 opensky_42  (cost=0.00..192.48 rows=97346 width=48) (actual time=12.840..82.158 rows=97346 loops=1)
                                             Output: opensky_42.longitude_1, opensky_42.latitude_1, opensky_42.longitude_2, opensky_42.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=538
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_10_106353 opensky_11  (cost=0.00..190.79 rows=94014 width=48) (actual time=9.139..108.380 rows=94014 loops=1)
                                             Output: opensky_11.longitude_1, opensky_11.latitude_1, opensky_11.longitude_2, opensky_11.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=532
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_07_106257 opensky_8  (cost=0.00..189.39 rows=93438 width=48) (actual time=8.601..75.910 rows=93438 loops=1)
                                             Output: opensky_8.longitude_1, opensky_8.latitude_1, opensky_8.longitude_2, opensky_8.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=533
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106321 opensky_10  (cost=0.00..187.61 rows=92443 width=48) (actual time=12.871..123.239 rows=92443 loops=1)
                                             Output: opensky_10.longitude_1, opensky_10.latitude_1, opensky_10.longitude_2, opensky_10.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=527
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_04_107313 opensky_41  (cost=0.00..178.71 rows=90572 width=48) (actual time=28.220..99.796 rows=90572 loops=1)
                                             Output: opensky_41.longitude_1, opensky_41.latitude_1, opensky_41.longitude_2, opensky_41.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=507
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_12_106417 opensky_13  (cost=0.00..177.00 rows=87251 width=48) (actual time=10.699..94.949 rows=87251 loops=1)
                                             Output: opensky_13.longitude_1, opensky_13.latitude_1, opensky_13.longitude_2, opensky_13.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=495
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_03_107281 opensky_40  (cost=0.00..176.50 rows=88871 width=48) (actual time=27.076..176.500 rows=88871 loops=1)
                                             Output: opensky_40.longitude_1, opensky_40.latitude_1, opensky_40.longitude_2, opensky_40.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=490
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_01_106449 opensky_14  (cost=0.00..176.31 rows=85661 width=48) (actual time=29.928..144.143 rows=85661 loops=1)
                                             Output: opensky_14.longitude_1, opensky_14.latitude_1, opensky_14.longitude_2, opensky_14.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=489
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_07_107025 opensky_32  (cost=0.00..175.35 rows=89405 width=48) (actual time=10.272..136.671 rows=89405 loops=1)
                                             Output: opensky_32.longitude_1, opensky_32.latitude_1, opensky_32.longitude_2, opensky_32.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=471
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_08_107057 opensky_33  (cost=0.00..175.16 rows=88470 width=48) (actual time=11.989..90.154 rows=88470 loops=1)
                                             Output: opensky_33.longitude_1, opensky_33.latitude_1, opensky_33.longitude_2, opensky_33.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=488
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_11_107537 opensky_48  (cost=0.00..174.58 rows=89278 width=48) (actual time=12.175..132.033 rows=89278 loops=1)
                                             Output: opensky_48.longitude_1, opensky_48.latitude_1, opensky_48.longitude_2, opensky_48.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=494
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_11_106385 opensky_12  (cost=0.00..174.18 rows=85752 width=48) (actual time=12.110..128.425 rows=85752 loops=1)
                                             Output: opensky_12.longitude_1, opensky_12.latitude_1, opensky_12.longitude_2, opensky_12.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=489
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_06_106225 opensky_7  (cost=0.00..171.19 rows=84680 width=48) (actual time=18.392..138.326 rows=84680 loops=1)
                                             Output: opensky_7.longitude_1, opensky_7.latitude_1, opensky_7.longitude_2, opensky_7.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=485
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_10_107121 opensky_35  (cost=0.00..169.96 rows=85502 width=48) (actual time=13.587..165.375 rows=85502 loops=1)
                                             Output: opensky_35.longitude_1, opensky_35.latitude_1, opensky_35.longitude_2, opensky_35.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=478
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_09_107089 opensky_34  (cost=0.00..167.91 rows=84816 width=48) (actual time=13.445..125.287 rows=84816 loops=1)
                                             Output: opensky_34.longitude_1, opensky_34.latitude_1, opensky_34.longitude_2, opensky_34.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=473
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_02_106481 opensky_15  (cost=0.00..167.87 rows=82315 width=48) (actual time=13.691..129.728 rows=82315 loops=1)
                                             Output: opensky_15.longitude_1, opensky_15.latitude_1, opensky_15.longitude_2, opensky_15.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=474
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_05_106193 opensky_6  (cost=0.00..166.15 rows=82241 width=48) (actual time=29.941..168.077 rows=82241 loops=1)
                                             Output: opensky_6.longitude_1, opensky_6.latitude_1, opensky_6.longitude_2, opensky_6.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=475
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_12_107569 opensky_49  (cost=0.00..164.05 rows=83800 width=48) (actual time=22.004..184.704 rows=83800 loops=1)
                                             Output: opensky_49.longitude_1, opensky_49.latitude_1, opensky_49.longitude_2, opensky_49.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=450
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_12_107185 opensky_37  (cost=0.00..161.96 rows=81847 width=48) (actual time=13.310..163.576 rows=81847 loops=1)
                                             Output: opensky_37.longitude_1, opensky_37.latitude_1, opensky_37.longitude_2, opensky_37.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=460
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_06_106993 opensky_31  (cost=0.00..157.12 rows=80245 width=48) (actual time=12.621..108.020 rows=80245 loops=1)
                                             Output: opensky_31.longitude_1, opensky_31.latitude_1, opensky_31.longitude_2, opensky_31.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=452
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_11_107153 opensky_36  (cost=0.00..156.24 rows=79371 width=48) (actual time=11.949..110.950 rows=79371 loops=1)
                                             Output: opensky_36.longitude_1, opensky_36.latitude_1, opensky_36.longitude_2, opensky_36.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=438
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_04_106161 opensky_5  (cost=0.00..154.93 rows=76638 width=48) (actual time=11.046..151.281 rows=76638 loops=1)
                                             Output: opensky_5.longitude_1, opensky_5.latitude_1, opensky_5.longitude_2, opensky_5.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=444
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_01_107217 opensky_38  (cost=0.00..153.00 rows=77033 width=48) (actual time=10.983..120.439 rows=77033 loops=1)
                                             Output: opensky_38.longitude_1, opensky_38.latitude_1, opensky_38.longitude_2, opensky_38.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=431
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_03_106129 opensky_4  (cost=0.00..148.17 rows=73442 width=48) (actual time=10.601..100.978 rows=73442 loops=1)
                                             Output: opensky_4.longitude_1, opensky_4.latitude_1, opensky_4.longitude_2, opensky_4.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=430
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_02_107249 opensky_39  (cost=0.00..147.77 rows=74462 width=48) (actual time=27.628..245.598 rows=74462 loops=1)
                                             Output: opensky_39.longitude_1, opensky_39.latitude_1, opensky_39.longitude_2, opensky_39.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=422
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_05_106961 opensky_30  (cost=0.00..142.55 rows=71850 width=48) (actual time=26.396..197.749 rows=71850 loops=1)
                                             Output: opensky_30.longitude_1, opensky_30.latitude_1, opensky_30.longitude_2, opensky_30.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=409
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_04_106929 opensky_29  (cost=0.00..139.61 rows=70609 width=48) (actual time=9.736..140.590 rows=70609 loops=1)
                                             Output: opensky_29.longitude_1, opensky_29.latitude_1, opensky_29.longitude_2, opensky_29.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=402
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_01_106065 opensky_2  (cost=0.00..139.15 rows=69061 width=48) (actual time=26.537..119.442 rows=69061 loops=1)
                                             Output: opensky_2.longitude_1, opensky_2.latitude_1, opensky_2.longitude_2, opensky_2.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=401
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_03_106513 opensky_16  (cost=0.00..134.66 rows=66156 width=48) (actual time=26.981..204.054 rows=66156 loops=1)
                                             Output: opensky_16.longitude_1, opensky_16.latitude_1, opensky_16.longitude_2, opensky_16.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=383
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_02_106097 opensky_3  (cost=0.00..130.48 rows=64551 width=48) (actual time=12.488..139.544 rows=64551 loops=1)
                                             Output: opensky_3.longitude_1, opensky_3.latitude_1, opensky_3.longitude_2, opensky_3.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=381
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_03_106897 opensky_28  (cost=0.00..129.62 rows=65478 width=48) (actual time=15.049..191.319 rows=65478 loops=1)
                                             Output: opensky_28.longitude_1, opensky_28.latitude_1, opensky_28.longitude_2, opensky_28.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=370
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_08_106673 opensky_21  (cost=0.00..128.91 rows=63188 width=48) (actual time=10.844..195.195 rows=63188 loops=1)
                                             Output: opensky_21.longitude_1, opensky_21.latitude_1, opensky_21.longitude_2, opensky_21.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=373
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_10_106737 opensky_23  (cost=0.00..124.50 rows=61883 width=48) (actual time=27.217..225.867 rows=61883 loops=1)
                                             Output: opensky_23.longitude_1, opensky_23.latitude_1, opensky_23.longitude_2, opensky_23.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=366
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_09_106705 opensky_22  (cost=0.00..122.87 rows=60236 width=48) (actual time=11.033..244.839 rows=60236 loops=1)
                                             Output: opensky_22.longitude_1, opensky_22.latitude_1, opensky_22.longitude_2, opensky_22.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=360
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_07_106641 opensky_20  (cost=0.00..121.77 rows=59887 width=48) (actual time=10.216..105.803 rows=59887 loops=1)
                                             Output: opensky_20.longitude_1, opensky_20.latitude_1, opensky_20.longitude_2, opensky_20.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=351
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_12_106801 opensky_25  (cost=0.00..118.81 rows=59119 width=48) (actual time=23.942..116.715 rows=59119 loops=1)
                                             Output: opensky_25.longitude_1, opensky_25.latitude_1, opensky_25.longitude_2, opensky_25.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=343
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_11_106769 opensky_24  (cost=0.00..113.75 rows=56711 width=48) (actual time=9.593..118.300 rows=56711 loops=1)
                                             Output: opensky_24.longitude_1, opensky_24.latitude_1, opensky_24.longitude_2, opensky_24.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=333
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_01_106833 opensky_26  (cost=0.00..113.42 rows=57213 width=48) (actual time=8.931..104.774 rows=57213 loops=1)
                                             Output: opensky_26.longitude_1, opensky_26.latitude_1, opensky_26.longitude_2, opensky_26.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=328
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_02_106865 opensky_27  (cost=0.00..101.50 rows=51231 width=48) (actual time=24.963..117.737 rows=51231 loops=1)
                                             Output: opensky_27.longitude_1, opensky_27.latitude_1, opensky_27.longitude_2, opensky_27.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=303
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_06_106609 opensky_19  (cost=0.00..91.49 rows=45771 width=48) (actual time=7.156..91.727 rows=45771 loops=1)
                                             Output: opensky_19.longitude_1, opensky_19.latitude_1, opensky_19.longitude_2, opensky_19.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=278
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_05_106577 opensky_18  (cost=0.00..68.74 rows=34456 width=48) (actual time=7.146..47.863 rows=34456 loops=1)
                                             Output: opensky_18.longitude_1, opensky_18.latitude_1, opensky_18.longitude_2, opensky_18.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=220
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_04_106545 opensky_17  (cost=0.00..51.73 rows=26011 width=48) (actual time=7.512..68.692 rows=26011 loops=1)
                                             Output: opensky_17.longitude_1, opensky_17.latitude_1, opensky_17.longitude_2, opensky_17.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=173
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2018_12_106033 opensky_1  (cost=0.00..0.37 rows=148 width=48) (actual time=1218.152..1218.960 rows=148 loops=1)
                                             Output: opensky_1.longitude_1, opensky_1.latitude_1, opensky_1.longitude_2, opensky_1.latitude_2
                                             Columnar Projected Columns: latitude_1, longitude_1, latitude_2, longitude_2
                                             Buffers: shared hit=88
                                       ->  Seq Scan on public.opensky_p2023_01_106001 opensky_50  (cost=0.00..0.00 rows=1 width=128) (actual time=0.017..0.017 rows=0 loops=1)
                                             Output: opensky_50.longitude_1, opensky_50.latitude_1, opensky_50.longitude_2, opensky_50.latitude_2
                   Planning Time: 189.945 ms
                   JIT:
                     Functions: 55
                     Options: Inlining true, Optimization true, Expressions true, Deforming true
                     Timing: Generation 22.062 ms, Inlining 292.358 ms, Optimization 490.722 ms, Emission 435.594 ms, Total 1240.737 ms
                   Execution Time: 108552.083 ms
         Buffers: shared hit=100
 Planning:
   Buffers: shared hit=4
 Planning Time: 2.437 ms
 Execution Time: 110532.953 ms
(234 rows)

Time: 110548.895 ms (01:50.549)
```
