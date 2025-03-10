```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT COUNT(*) FROM opensky;
                                                                                                QUERY PLAN                                                                                                
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=250.00..250.02 rows=1 width=8) (actual time=3256.949..3256.951 rows=1 loops=1)
   Output: COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)
   Buffers: shared hit=100
   ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=8) (actual time=3256.909..3256.916 rows=32 loops=1)
         Output: remote_scan.count
         Task Count: 32
         Tuple data received from nodes: 256 bytes
         Tasks Shown: One of 32
         ->  Task
               Query: SELECT count(*) AS count FROM public.opensky_104381 opensky WHERE true
               Tuple data received from node: 8 bytes
               Node: host=c-worker2-1 port=5432 dbname=otus
               ->  Finalize Aggregate  (cost=12578.60..12578.61 rows=1 width=8) (actual time=2661.237..2661.468 rows=1 loops=1)
                     Output: count(*)
                     Buffers: shared hit=1510
                     ->  Gather  (cost=12578.39..12578.60 rows=2 width=8) (actual time=2661.231..2661.461 rows=1 loops=1)
                           Output: (PARTIAL count(*))
                           Workers Planned: 2
                           Workers Launched: 0
                           Buffers: shared hit=1510
                           ->  Partial Aggregate  (cost=11578.39..11578.40 rows=1 width=8) (actual time=2658.177..2658.201 rows=1 loops=1)
                                 Output: PARTIAL count(*)
                                 Buffers: shared hit=1510
                                 ->  Parallel Append  (cost=0.00..7718.93 rows=1543785 width=0) (actual time=0.925..1987.164 rows=3705075 loops=1)
                                       Buffers: shared hit=1510
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2018_12_106013 opensky_1  (cost=0.00..0.00 rows=130 width=0) (actual time=0.044..0.065 rows=130 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=15
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_01_106045 opensky_2  (cost=0.00..0.00 rows=67626 width=0) (actual time=0.142..7.602 rows=67626 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_02_106077 opensky_3  (cost=0.00..0.00 rows=63201 width=0) (actual time=0.136..7.008 rows=63201 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_03_106109 opensky_4  (cost=0.00..0.00 rows=71745 width=0) (actual time=0.165..7.845 rows=71745 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_04_106141 opensky_5  (cost=0.00..0.00 rows=74256 width=0) (actual time=0.109..8.662 rows=74256 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_05_106173 opensky_6  (cost=0.00..0.00 rows=79093 width=0) (actual time=0.165..8.960 rows=79093 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=33
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_06_106205 opensky_7  (cost=0.00..0.00 rows=83378 width=0) (actual time=0.188..10.616 rows=83378 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_07_106237 opensky_8  (cost=0.00..0.00 rows=91225 width=0) (actual time=0.237..10.633 rows=91225 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=35
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_08_106269 opensky_9  (cost=0.00..0.00 rows=94268 width=0) (actual time=0.152..11.636 rows=94268 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106301 opensky_10  (cost=0.00..0.00 rows=90167 width=0) (actual time=0.168..10.257 rows=90167 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_10_106333 opensky_11  (cost=0.00..0.00 rows=92295 width=0) (actual time=0.149..11.320 rows=92295 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_11_106365 opensky_12  (cost=0.00..0.00 rows=84656 width=0) (actual time=0.206..9.533 rows=84656 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_12_106397 opensky_13  (cost=0.00..0.00 rows=86509 width=0) (actual time=0.249..11.495 rows=86509 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_01_106429 opensky_14  (cost=0.00..0.00 rows=85879 width=0) (actual time=0.222..16.510 rows=85879 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_02_106461 opensky_15  (cost=0.00..0.00 rows=84115 width=0) (actual time=0.251..16.172 rows=84115 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_03_106493 opensky_16  (cost=0.00..0.00 rows=67596 width=0) (actual time=0.252..13.177 rows=67596 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_04_106525 opensky_17  (cost=0.00..0.00 rows=26317 width=0) (actual time=0.158..5.235 rows=26317 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=27
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_05_106557 opensky_18  (cost=0.00..0.00 rows=34510 width=0) (actual time=0.158..10.043 rows=34510 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=28
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_06_106589 opensky_19  (cost=0.00..0.00 rows=45761 width=0) (actual time=0.169..24.437 rows=45761 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=28
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_07_106621 opensky_20  (cost=0.00..0.00 rows=60918 width=0) (actual time=0.248..13.089 rows=60918 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_08_106653 opensky_21  (cost=0.00..0.00 rows=65219 width=0) (actual time=0.362..14.120 rows=65219 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_09_106685 opensky_22  (cost=0.00..0.00 rows=60376 width=0) (actual time=0.491..13.323 rows=60376 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_10_106717 opensky_23  (cost=0.00..0.00 rows=63058 width=0) (actual time=0.229..29.868 rows=63058 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_11_106749 opensky_24  (cost=0.00..0.00 rows=58425 width=0) (actual time=0.225..11.650 rows=58425 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_12_106781 opensky_25  (cost=0.00..0.00 rows=61086 width=0) (actual time=0.290..40.670 rows=61086 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_01_106813 opensky_26  (cost=0.00..0.00 rows=57250 width=0) (actual time=0.252..11.812 rows=57250 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_02_106845 opensky_27  (cost=0.00..0.00 rows=51676 width=0) (actual time=0.225..22.514 rows=51676 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_03_106877 opensky_28  (cost=0.00..0.00 rows=65957 width=0) (actual time=0.222..29.799 rows=65957 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_04_106909 opensky_29  (cost=0.00..0.00 rows=70430 width=0) (actual time=0.231..62.510 rows=70430 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_05_106941 opensky_30  (cost=0.00..0.00 rows=72549 width=0) (actual time=0.223..30.225 rows=72549 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_06_106973 opensky_31  (cost=0.00..0.00 rows=80988 width=0) (actual time=0.357..49.860 rows=80988 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_07_107005 opensky_32  (cost=0.00..0.00 rows=90741 width=0) (actual time=0.386..91.227 rows=90741 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=19
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_08_107037 opensky_33  (cost=0.00..0.00 rows=89015 width=0) (actual time=0.339..37.656 rows=89015 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_09_107069 opensky_34  (cost=0.00..0.00 rows=84741 width=0) (actual time=0.380..48.167 rows=84741 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=34
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_10_107101 opensky_35  (cost=0.00..0.00 rows=86184 width=0) (actual time=0.350..81.123 rows=86184 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_11_107133 opensky_36  (cost=0.00..0.00 rows=78571 width=0) (actual time=0.289..55.497 rows=78571 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_12_107165 opensky_37  (cost=0.00..0.00 rows=80927 width=0) (actual time=0.244..16.072 rows=80927 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_01_107197 opensky_38  (cost=0.00..0.00 rows=75347 width=0) (actual time=0.410..18.104 rows=75347 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_02_107229 opensky_39  (cost=0.00..0.00 rows=72206 width=0) (actual time=0.307..17.331 rows=72206 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_03_107261 opensky_40  (cost=0.00..0.00 rows=87419 width=0) (actual time=0.656..22.843 rows=87419 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_04_107293 opensky_41  (cost=0.00..0.00 rows=89599 width=0) (actual time=0.326..29.444 rows=89599 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_05_107325 opensky_42  (cost=0.00..0.00 rows=97274 width=0) (actual time=0.415..23.387 rows=97274 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=36
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_06_107357 opensky_43  (cost=0.00..0.00 rows=101534 width=0) (actual time=0.414..26.798 rows=101534 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=33
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_07_107389 opensky_44  (cost=0.00..0.00 rows=103884 width=0) (actual time=0.370..26.793 rows=103884 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_08_107421 opensky_45  (cost=0.00..0.00 rows=103634 width=0) (actual time=0.432..25.203 rows=103634 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=18
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_09_107453 opensky_46  (cost=0.00..0.00 rows=98594 width=0) (actual time=0.359..26.320 rows=98594 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_10_107485 opensky_47  (cost=0.00..0.00 rows=99792 width=0) (actual time=0.389..25.516 rows=99792 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_11_107517 opensky_48  (cost=0.00..0.00 rows=90078 width=0) (actual time=0.432..28.789 rows=90078 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_12_107549 opensky_49  (cost=0.00..0.00 rows=84876 width=0) (actual time=0.910..21.468 rows=84876 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=84
                                       ->  Seq Scan on public.opensky_p2023_01_105981 opensky_50  (cost=0.00..0.00 rows=1 width=0) (actual time=0.014..0.014 rows=0 loops=1)
                   Planning Time: 64.882 ms
                   Execution Time: 2662.910 ms
         Buffers: shared hit=100
 Planning:
   Buffers: shared hit=4
 Planning Time: 1.787 ms
 Execution Time: 3257.104 ms
(180 rows)

Time: 3283.674 ms (00:03.284)
```
