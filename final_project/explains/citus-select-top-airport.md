```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT origin, COUNT(*) FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC limit 10;
                                                                                                      QUERY PLAN                                                                                                      
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=507.82..507.85 rows=10 width=40) (actual time=5634.716..5634.721 rows=10 loops=1)
   Output: remote_scan.origin, (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint))
   Buffers: shared hit=100
   ->  Sort  (cost=507.82..508.32 rows=200 width=40) (actual time=5634.713..5634.715 rows=10 loops=1)
         Output: remote_scan.origin, (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint))
         Sort Key: (COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=100
         ->  HashAggregate  (cost=500.00..503.50 rows=200 width=40) (actual time=5621.105..5630.033 rows=16917 loops=1)
               Output: remote_scan.origin, COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)
               Group Key: remote_scan.origin
               Batches: 1  Memory Usage: 4897kB
               Buffers: shared hit=100
               ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=40) (actual time=5383.099..5428.742 rows=404833 loops=1)
                     Output: remote_scan.origin, remote_scan.count
                     Task Count: 32
                     Tuple data received from nodes: 4744 kB
                     Tasks Shown: One of 32
                     ->  Task
                           Query: SELECT origin, count(*) AS count FROM public.opensky_104387 opensky WHERE (origin OPERATOR(pg_catalog.<>) ''::text) GROUP BY origin
                           Tuple data received from node: 147 kB
                           Node: host=c-worker2-1 port=5432 dbname=otus
                           ->  Finalize HashAggregate  (cost=14058.20..14087.99 rows=2979 width=13) (actual time=4696.646..4698.779 rows=12580 loops=1)
                                 Output: opensky.origin, count(*)
                                 Group Key: opensky.origin
                                 Batches: 1  Memory Usage: 1425kB
                                 Buffers: shared hit=3222
                                 ->  Gather  (cost=13402.82..14028.41 rows=5958 width=13) (actual time=4688.079..4691.875 rows=12580 loops=1)
                                       Output: opensky.origin, (PARTIAL count(*))
                                       Workers Planned: 2
                                       Workers Launched: 0
                                       Buffers: shared hit=3222
                                       ->  Partial HashAggregate  (cost=12402.82..12432.61 rows=2979 width=13) (actual time=4684.432..4686.729 rows=12580 loops=1)
                                             Output: opensky.origin, PARTIAL count(*)
                                             Group Key: opensky.origin
                                             Batches: 1  Memory Usage: 1425kB
                                             Buffers: shared hit=3222
                                             ->  Parallel Append  (cost=0.00..6661.96 rows=1148171 width=5) (actual time=1.238..2575.814 rows=2757632 loops=1)
                                                   Buffers: shared hit=3222
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_07_107395 opensky_44  (cost=0.00..51.23 rows=77750 width=5) (actual time=0.965..17.104 rows=77798 loops=1)
                                                         Output: opensky_44.origin
                                                         Filter: (opensky_44.origin <> ''::text)
                                                         Rows Removed by Filter: 25762
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=80
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_08_107427 opensky_45  (cost=0.00..50.98 rows=78445 width=5) (actual time=1.055..17.747 rows=78230 loops=1)
                                                         Output: opensky_45.origin
                                                         Filter: (opensky_45.origin <> ''::text)
                                                         Rows Removed by Filter: 24775
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=66
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_06_107363 opensky_43  (cost=0.00..49.40 rows=76013 width=5) (actual time=0.970..16.391 rows=76406 loops=1)
                                                         Output: opensky_43.origin
                                                         Filter: (opensky_43.origin <> ''::text)
                                                         Rows Removed by Filter: 23405
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=77
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_10_107491 opensky_47  (cost=0.00..49.30 rows=78254 width=5) (actual time=1.541..17.919 rows=78106 loops=1)
                                                         Output: opensky_47.origin
                                                         Filter: (opensky_47.origin <> ''::text)
                                                         Rows Removed by Filter: 22015
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=77
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_09_107459 opensky_46  (cost=0.00..48.50 rows=75720 width=5) (actual time=1.509..34.847 rows=75795 loops=1)
                                                         Output: opensky_46.origin
                                                         Filter: (opensky_46.origin <> ''::text)
                                                         Rows Removed by Filter: 22675
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=78
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_05_107331 opensky_42  (cost=0.00..47.29 rows=74076 width=5) (actual time=1.301..33.830 rows=74190 loops=1)
                                                         Output: opensky_42.origin
                                                         Filter: (opensky_42.origin <> ''::text)
                                                         Rows Removed by Filter: 21343
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=78
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_08_106275 opensky_9  (cost=0.00..46.88 rows=66490 width=5) (actual time=1.238..32.280 rows=66289 loops=1)
                                                         Output: opensky_9.origin
                                                         Filter: (opensky_9.origin <> ''::text)
                                                         Rows Removed by Filter: 26042
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=73
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_10_106339 opensky_11  (cost=0.00..46.10 rows=66889 width=5) (actual time=17.387..46.653 rows=66712 loops=1)
                                                         Output: opensky_11.origin
                                                         Filter: (opensky_11.origin <> ''::text)
                                                         Rows Removed by Filter: 24093
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=72
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_07_106243 opensky_8  (cost=0.00..45.21 rows=62211 width=5) (actual time=1.308..84.341 rows=61913 loops=1)
                                                         Output: opensky_8.origin
                                                         Filter: (opensky_8.origin <> ''::text)
                                                         Rows Removed by Filter: 27372
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=69
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106307 opensky_10  (cost=0.00..44.98 rows=64252 width=5) (actual time=1.293..40.166 rows=64281 loops=1)
                                                         Output: opensky_10.origin
                                                         Filter: (opensky_10.origin <> ''::text)
                                                         Rows Removed by Filter: 24384
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=69
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_04_107299 opensky_41  (cost=0.00..44.23 rows=69085 width=5) (actual time=1.262..33.840 rows=69165 loops=1)
                                                         Output: opensky_41.origin
                                                         Filter: (opensky_41.origin <> ''::text)
                                                         Rows Removed by Filter: 20385
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=72
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_12_106403 opensky_13  (cost=0.00..44.12 rows=62647 width=5) (actual time=1.331..31.044 rows=62681 loops=1)
                                                         Output: opensky_13.origin
                                                         Filter: (opensky_13.origin <> ''::text)
                                                         Rows Removed by Filter: 24221
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=68
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_07_107011 opensky_32  (cost=0.00..44.07 rows=68639 width=5) (actual time=1.458..52.561 rows=68812 loops=1)
                                                         Output: opensky_32.origin
                                                         Filter: (opensky_32.origin <> ''::text)
                                                         Rows Removed by Filter: 20974
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=57
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_08_107043 opensky_33  (cost=0.00..44.05 rows=67408 width=5) (actual time=1.403..40.940 rows=67489 loops=1)
                                                         Output: opensky_33.origin
                                                         Filter: (opensky_33.origin <> ''::text)
                                                         Rows Removed by Filter: 21459
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=72
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_11_107523 opensky_48  (cost=0.00..44.00 rows=69195 width=5) (actual time=1.362..97.244 rows=69224 loops=1)
                                                         Output: opensky_48.origin
                                                         Filter: (opensky_48.origin <> ''::text)
                                                         Rows Removed by Filter: 20621
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=71
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_01_106435 opensky_14  (cost=0.00..43.95 rows=61722 width=5) (actual time=1.205..62.416 rows=61797 loops=1)
                                                         Output: opensky_14.origin
                                                         Filter: (opensky_14.origin <> ''::text)
                                                         Rows Removed by Filter: 23554
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=68
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_03_107267 opensky_40  (cost=0.00..43.13 rows=66445 width=5) (actual time=1.227..30.568 rows=66745 loops=1)
                                                         Output: opensky_40.origin
                                                         Filter: (opensky_40.origin <> ''::text)
                                                         Rows Removed by Filter: 19945
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=71
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_11_106371 opensky_12  (cost=0.00..43.00 rows=61785 width=5) (actual time=9.261..67.347 rows=61501 loops=1)
                                                         Output: opensky_12.origin
                                                         Filter: (opensky_12.origin <> ''::text)
                                                         Rows Removed by Filter: 22986
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=69
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_10_107107 opensky_35  (cost=0.00..42.42 rows=64634 width=5) (actual time=1.337..27.768 rows=64975 loops=1)
                                                         Output: opensky_35.origin
                                                         Filter: (opensky_35.origin <> ''::text)
                                                         Rows Removed by Filter: 20391
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=72
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_09_107075 opensky_34  (cost=0.00..42.11 rows=64987 width=5) (actual time=2.102..30.621 rows=65087 loops=1)
                                                         Output: opensky_34.origin
                                                         Filter: (opensky_34.origin <> ''::text)
                                                         Rows Removed by Filter: 19940
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=73
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_02_106467 opensky_15  (cost=0.00..42.04 rows=61591 width=5) (actual time=1.245..30.822 rows=61989 loops=1)
                                                         Output: opensky_15.origin
                                                         Filter: (opensky_15.origin <> ''::text)
                                                         Rows Removed by Filter: 20390
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=71
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_06_106211 opensky_7  (cost=0.00..41.54 rows=56967 width=5) (actual time=0.998..27.366 rows=57015 loops=1)
                                                         Output: opensky_7.origin
                                                         Filter: (opensky_7.origin <> ''::text)
                                                         Rows Removed by Filter: 25094
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=68
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_12_107555 opensky_49  (cost=0.00..40.90 rows=62980 width=5) (actual time=1.146..27.175 rows=63191 loops=1)
                                                         Output: opensky_49.origin
                                                         Filter: (opensky_49.origin <> ''::text)
                                                         Rows Removed by Filter: 20236
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=55
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_12_107171 opensky_37  (cost=0.00..40.34 rows=61146 width=5) (actual time=1.052..75.835 rows=61221 loops=1)
                                                         Output: opensky_37.origin
                                                         Filter: (opensky_37.origin <> ''::text)
                                                         Rows Removed by Filter: 20290
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=68
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_05_106179 opensky_6  (cost=0.00..39.73 rows=56333 width=5) (actual time=0.926..72.522 rows=56205 loops=1)
                                                         Output: opensky_6.origin
                                                         Filter: (opensky_6.origin <> ''::text)
                                                         Rows Removed by Filter: 22364
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=64
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_06_106979 opensky_31  (cost=0.00..39.29 rows=62151 width=5) (actual time=1.015..41.810 rows=62098 loops=1)
                                                         Output: opensky_31.origin
                                                         Filter: (opensky_31.origin <> ''::text)
                                                         Rows Removed by Filter: 18235
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=71
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_11_107139 opensky_36  (cost=0.00..39.02 rows=60568 width=5) (actual time=1.142..28.027 rows=60641 loops=1)
                                                         Output: opensky_36.origin
                                                         Filter: (opensky_36.origin <> ''::text)
                                                         Rows Removed by Filter: 18578
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=65
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_04_106147 opensky_5  (cost=0.00..37.79 rows=51619 width=5) (actual time=0.844..25.993 rows=51740 loops=1)
                                                         Output: opensky_5.origin
                                                         Filter: (opensky_5.origin <> ''::text)
                                                         Rows Removed by Filter: 22877
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=64
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_01_107203 opensky_38  (cost=0.00..37.76 rows=56375 width=5) (actual time=0.907..27.044 rows=56472 loops=1)
                                                         Output: opensky_38.origin
                                                         Filter: (opensky_38.origin <> ''::text)
                                                         Rows Removed by Filter: 19547
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=64
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2022_02_107235 opensky_39  (cost=0.00..36.45 rows=55615 width=5) (actual time=1.262..27.021 rows=55621 loops=1)
                                                         Output: opensky_39.origin
                                                         Filter: (opensky_39.origin <> ''::text)
                                                         Rows Removed by Filter: 17802
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=65
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_03_106115 opensky_4  (cost=0.00..36.09 rows=50103 width=5) (actual time=1.296..61.158 rows=50203 loops=1)
                                                         Output: opensky_4.origin
                                                         Filter: (opensky_4.origin <> ''::text)
                                                         Rows Removed by Filter: 21312
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=64
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_05_106947 opensky_30  (cost=0.00..36.06 rows=56375 width=5) (actual time=0.985..49.933 rows=56430 loops=1)
                                                         Output: opensky_30.origin
                                                         Filter: (opensky_30.origin <> ''::text)
                                                         Rows Removed by Filter: 16355
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=66
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_04_106915 opensky_29  (cost=0.00..34.82 rows=54064 width=5) (actual time=1.061..25.793 rows=53963 loops=1)
                                                         Output: opensky_29.origin
                                                         Filter: (opensky_29.origin <> ''::text)
                                                         Rows Removed by Filter: 16503
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=66
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_01_106051 opensky_2  (cost=0.00..34.72 rows=49302 width=5) (actual time=0.772..23.677 rows=49296 loops=1)
                                                         Output: opensky_2.origin
                                                         Filter: (opensky_2.origin <> ''::text)
                                                         Rows Removed by Filter: 19500
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=59
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_03_106499 opensky_16  (cost=0.00..34.40 rows=50872 width=5) (actual time=0.958..24.495 rows=50919 loops=1)
                                                         Output: opensky_16.origin
                                                         Filter: (opensky_16.origin <> ''::text)
                                                         Rows Removed by Filter: 16653
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=60
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_08_106659 opensky_21  (cost=0.00..32.74 rows=49136 width=5) (actual time=0.949..23.728 rows=49042 loops=1)
                                                         Output: opensky_21.origin
                                                         Filter: (opensky_21.origin <> ''::text)
                                                         Rows Removed by Filter: 15258
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=63
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_03_106883 opensky_28  (cost=0.00..32.50 rows=50036 width=5) (actual time=0.969..24.578 rows=50200 loops=1)
                                                         Output: opensky_28.origin
                                                         Filter: (opensky_28.origin <> ''::text)
                                                         Rows Removed by Filter: 15430
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=63
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2019_02_106083 opensky_3  (cost=0.00..32.15 rows=45655 width=5) (actual time=0.943..41.601 rows=45613 loops=1)
                                                         Output: opensky_3.origin
                                                         Filter: (opensky_3.origin <> ''::text)
                                                         Rows Removed by Filter: 17942
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=59
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_10_106723 opensky_23  (cost=0.00..31.38 rows=46987 width=5) (actual time=2.085..92.226 rows=47122 loops=1)
                                                         Output: opensky_23.origin
                                                         Filter: (opensky_23.origin <> ''::text)
                                                         Rows Removed by Filter: 15294
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=61
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_09_106691 opensky_22  (cost=0.00..30.88 rows=45870 width=5) (actual time=0.888..27.549 rows=45941 loops=1)
                                                         Output: opensky_22.origin
                                                         Filter: (opensky_22.origin <> ''::text)
                                                         Rows Removed by Filter: 14688
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=61
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_07_106627 opensky_20  (cost=0.00..30.79 rows=46490 width=5) (actual time=1.071..22.320 rows=46607 loops=1)
                                                         Output: opensky_20.origin
                                                         Filter: (opensky_20.origin <> ''::text)
                                                         Rows Removed by Filter: 14066
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=60
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_12_106787 opensky_25  (cost=0.00..29.60 rows=43904 width=5) (actual time=0.797..37.708 rows=43941 loops=1)
                                                         Output: opensky_25.origin
                                                         Filter: (opensky_25.origin <> ''::text)
                                                         Rows Removed by Filter: 15002
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=56
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_11_106755 opensky_24  (cost=0.00..28.38 rows=42367 width=5) (actual time=1.143..50.166 rows=42430 loops=1)
                                                         Output: opensky_24.origin
                                                         Filter: (opensky_24.origin <> ''::text)
                                                         Rows Removed by Filter: 14182
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=57
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_01_106819 opensky_26  (cost=0.00..27.53 rows=41436 width=5) (actual time=1.022..38.940 rows=41540 loops=1)
                                                         Output: opensky_26.origin
                                                         Filter: (opensky_26.origin <> ''::text)
                                                         Rows Removed by Filter: 13894
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=58
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2021_02_106851 opensky_27  (cost=0.00..24.70 rows=37756 width=5) (actual time=1.126..21.921 rows=37687 loops=1)
                                                         Output: opensky_27.origin
                                                         Filter: (opensky_27.origin <> ''::text)
                                                         Rows Removed by Filter: 12249
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=57
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_06_106595 opensky_19  (cost=0.00..22.93 rows=35493 width=5) (actual time=1.619..29.096 rows=35480 loops=1)
                                                         Output: opensky_19.origin
                                                         Filter: (opensky_19.origin <> ''::text)
                                                         Rows Removed by Filter: 10475
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=53
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_05_106563 opensky_18  (cost=0.00..17.07 rows=26530 width=5) (actual time=0.902..15.557 rows=26583 loops=1)
                                                         Output: opensky_18.origin
                                                         Filter: (opensky_18.origin <> ''::text)
                                                         Rows Removed by Filter: 7725
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=47
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2020_04_106531 opensky_17  (cost=0.00..13.49 rows=21145 width=5) (actual time=1.260..14.597 rows=21150 loops=1)
                                                         Output: opensky_17.origin
                                                         Filter: (opensky_17.origin <> ''::text)
                                                         Rows Removed by Filter: 6035
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=43
                                                   ->  Custom Scan (ColumnarScan) on public.opensky_p2018_12_106019 opensky_1  (cost=0.00..0.09 rows=95 width=5) (actual time=1.224..1.308 rows=96 loops=1)
                                                         Output: opensky_1.origin
                                                         Filter: (opensky_1.origin <> ''::text)
                                                         Rows Removed by Filter: 39
                                                         Columnar Projected Columns: origin
                                                         Buffers: shared hit=82
                                                   ->  Seq Scan on public.opensky_p2023_01_105987 opensky_50  (cost=0.00..0.00 rows=1 width=32) (actual time=0.012..0.012 rows=0 loops=1)
                                                         Output: opensky_50.origin
                                                         Filter: (opensky_50.origin <> ''::text)
                               Planning Time: 90.144 ms
                               Execution Time: 4705.563 ms
                     Buffers: shared hit=100
 Planning:
   Buffers: shared hit=4
 Planning Time: 2.095 ms
 Execution Time: 5644.450 ms
(343 rows)

Time: 5656.481 ms (00:05.656)
```

