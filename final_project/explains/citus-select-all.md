```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT COUNT(*) FROM opensky;
                                                                                                QUERY PLAN                                                                                                 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=250.00..250.02 rows=1 width=8) (actual time=3389.718..3389.721 rows=1 loops=1)
   Output: COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)
   Buffers: shared hit=100
   ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=8) (actual time=3389.676..3389.682 rows=32 loops=1)
         Output: remote_scan.count
         Task Count: 32
         Tuple data received from nodes: 256 bytes
         Tasks Shown: One of 32
         ->  Task
               Query: SELECT count(*) AS count FROM public.opensky_104388 opensky WHERE true
               Tuple data received from node: 8 bytes
               Node: host=c-worker3-1 port=5432 dbname=otus
               ->  Finalize Aggregate  (cost=12451.64..12451.65 rows=1 width=8) (actual time=2888.428..2888.753 rows=1 loops=1)
                     Output: count(*)
                     Buffers: shared hit=1514
                     ->  Gather  (cost=12451.43..12451.64 rows=2 width=8) (actual time=2888.418..2888.744 rows=1 loops=1)
                           Output: (PARTIAL count(*))
                           Workers Planned: 2
                           Workers Launched: 0
                           Buffers: shared hit=1514
                           ->  Partial Aggregate  (cost=11451.43..11451.44 rows=1 width=8) (actual time=2885.443..2885.471 rows=1 loops=1)
                                 Output: PARTIAL count(*)
                                 Buffers: shared hit=1514
                                 ->  Parallel Append  (cost=0.00..7634.28 rows=1526857 width=0) (actual time=1.057..2195.913 rows=3664459 loops=1)
                                       Buffers: shared hit=1514
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2018_12_106020 opensky_1  (cost=0.00..0.00 rows=150 width=0) (actual time=0.083..0.117 rows=150 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=16
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_01_106052 opensky_2  (cost=0.00..0.00 rows=66709 width=0) (actual time=0.161..10.777 rows=66709 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_02_106084 opensky_3  (cost=0.00..0.00 rows=63129 width=0) (actual time=0.235..10.280 rows=63129 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_03_106116 opensky_4  (cost=0.00..0.00 rows=71579 width=0) (actual time=0.255..12.627 rows=71579 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_04_106148 opensky_5  (cost=0.00..0.00 rows=74092 width=0) (actual time=0.185..12.059 rows=74092 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_05_106180 opensky_6  (cost=0.00..0.00 rows=79057 width=0) (actual time=0.203..14.603 rows=79057 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_06_106212 opensky_7  (cost=0.00..0.00 rows=82747 width=0) (actual time=0.244..15.145 rows=82747 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_07_106244 opensky_8  (cost=0.00..0.00 rows=91426 width=0) (actual time=0.415..20.295 rows=91426 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_08_106276 opensky_9  (cost=0.00..0.00 rows=93189 width=0) (actual time=0.393..26.279 rows=93189 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106308 opensky_10  (cost=0.00..0.00 rows=90047 width=0) (actual time=0.386..24.935 rows=90047 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_10_106340 opensky_11  (cost=0.00..0.00 rows=91843 width=0) (actual time=0.371..26.316 rows=91843 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_11_106372 opensky_12  (cost=0.00..0.00 rows=85626 width=0) (actual time=0.399..23.784 rows=85626 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2019_12_106404 opensky_13  (cost=0.00..0.00 rows=86921 width=0) (actual time=0.424..24.529 rows=86921 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_01_106436 opensky_14  (cost=0.00..0.00 rows=84949 width=0) (actual time=0.337..24.023 rows=84949 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_02_106468 opensky_15  (cost=0.00..0.00 rows=82445 width=0) (actual time=0.362..22.921 rows=82445 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_03_106500 opensky_16  (cost=0.00..0.00 rows=66297 width=0) (actual time=0.299..19.628 rows=66297 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_04_106532 opensky_17  (cost=0.00..0.00 rows=26057 width=0) (actual time=0.240..8.217 rows=26057 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=28
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_05_106564 opensky_18  (cost=0.00..0.00 rows=33965 width=0) (actual time=0.312..10.317 rows=33965 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=28
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_06_106596 opensky_19  (cost=0.00..0.00 rows=45628 width=0) (actual time=0.185..11.323 rows=45628 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_07_106628 opensky_20  (cost=0.00..0.00 rows=60993 width=0) (actual time=0.263..14.860 rows=60993 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=28
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_08_106660 opensky_21  (cost=0.00..0.00 rows=63825 width=0) (actual time=0.234..17.511 rows=63825 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_09_106692 opensky_22  (cost=0.00..0.00 rows=60756 width=0) (actual time=0.322..16.546 rows=60756 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_10_106724 opensky_23  (cost=0.00..0.00 rows=62046 width=0) (actual time=0.381..17.849 rows=62046 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_11_106756 opensky_24  (cost=0.00..0.00 rows=57512 width=0) (actual time=0.322..16.191 rows=57512 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2020_12_106788 opensky_25  (cost=0.00..0.00 rows=59827 width=0) (actual time=0.336..16.776 rows=59827 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_01_106820 opensky_26  (cost=0.00..0.00 rows=56769 width=0) (actual time=0.355..15.963 rows=56769 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_02_106852 opensky_27  (cost=0.00..0.00 rows=50688 width=0) (actual time=0.358..14.928 rows=50688 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_03_106884 opensky_28  (cost=0.00..0.00 rows=65145 width=0) (actual time=0.323..18.426 rows=65145 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_04_106916 opensky_29  (cost=0.00..0.00 rows=69184 width=0) (actual time=0.308..19.264 rows=69184 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_05_106948 opensky_30  (cost=0.00..0.00 rows=69990 width=0) (actual time=0.272..19.287 rows=69990 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_06_106980 opensky_31  (cost=0.00..0.00 rows=78583 width=0) (actual time=0.371..22.743 rows=78583 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_07_107012 opensky_32  (cost=0.00..0.00 rows=87722 width=0) (actual time=0.379..24.672 rows=87722 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=19
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_08_107044 opensky_33  (cost=0.00..0.00 rows=86550 width=0) (actual time=0.329..26.305 rows=86550 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_09_107076 opensky_34  (cost=0.00..0.00 rows=83117 width=0) (actual time=0.357..25.427 rows=83117 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_10_107108 opensky_35  (cost=0.00..0.00 rows=84186 width=0) (actual time=0.409..35.448 rows=84186 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_11_107140 opensky_36  (cost=0.00..0.00 rows=77578 width=0) (actual time=0.335..55.027 rows=77578 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2021_12_107172 opensky_37  (cost=0.00..0.00 rows=79004 width=0) (actual time=0.472..15.328 rows=79004 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_01_107204 opensky_38  (cost=0.00..0.00 rows=75546 width=0) (actual time=0.261..18.780 rows=75546 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_02_107236 opensky_39  (cost=0.00..0.00 rows=72543 width=0) (actual time=0.532..48.603 rows=72543 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=32
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_03_107268 opensky_40  (cost=0.00..0.00 rows=87004 width=0) (actual time=0.254..33.968 rows=87004 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=34
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_04_107300 opensky_41  (cost=0.00..0.00 rows=88524 width=0) (actual time=0.222..67.972 rows=88524 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_05_107332 opensky_42  (cost=0.00..0.00 rows=95846 width=0) (actual time=0.225..48.396 rows=95846 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=30
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_06_107364 opensky_43  (cost=0.00..0.00 rows=99954 width=0) (actual time=0.407..71.844 rows=99954 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=29
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_07_107396 opensky_44  (cost=0.00..0.00 rows=103186 width=0) (actual time=0.458..107.551 rows=103186 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_08_107428 opensky_45  (cost=0.00..0.00 rows=101956 width=0) (actual time=0.253..47.530 rows=101956 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=19
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_09_107460 opensky_46  (cost=0.00..0.00 rows=98153 width=0) (actual time=0.377..19.038 rows=98153 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=33
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_10_107492 opensky_47  (cost=0.00..0.00 rows=99778 width=0) (actual time=0.341..27.177 rows=99778 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=31
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_11_107524 opensky_48  (cost=0.00..0.00 rows=88229 width=0) (actual time=0.547..25.481 rows=88229 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=37
                                       ->  Custom Scan (ColumnarScan) on public.opensky_p2022_12_107556 opensky_49  (cost=0.00..0.00 rows=84409 width=0) (actual time=1.043..25.172 rows=84409 loops=1)
                                             Columnar Projected Columns: <columnar optimized out all columns>
                                             Buffers: shared hit=83
                                       ->  Seq Scan on public.opensky_p2023_01_105988 opensky_50  (cost=0.00..0.00 rows=1 width=0) (actual time=0.012..0.012 rows=0 loops=1)
                   Planning Time: 62.089 ms
                   Execution Time: 2890.061 ms
         Buffers: shared hit=100
 Planning:
   Buffers: shared hit=4
 Planning Time: 1.688 ms
 Execution Time: 3389.907 ms
(180 rows)

Time: 3399.976 ms (00:03.400)
```
