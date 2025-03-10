```
otus=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
                                                                                      QUERY PLAN                                                                                       
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=250.00..250.02 rows=1 width=8) (actual time=1598.700..1598.702 rows=1 loops=1)
   Output: COALESCE((pg_catalog.sum(remote_scan.count))::bigint, '0'::bigint)
   Buffers: shared hit=100
   ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=8) (actual time=1598.673..1598.675 rows=2 loops=1)
         Output: remote_scan.count
         Task Count: 2
         Tuple data received from nodes: 16 bytes
         Tasks Shown: One of 2
         ->  Task
               Query: SELECT count(*) AS count FROM public.opensky_104396 opensky WHERE (callsign OPERATOR(pg_catalog.=) ANY ('{UUEE,UUDD,UUWW}'::text[]))
               Tuple data received from node: 8 bytes
               Node: host=c-worker2-1 port=5432 dbname=otus
               ->  Aggregate  (cost=981.98..981.99 rows=1 width=8) (actual time=1429.238..1429.279 rows=1 loops=1)
                     Output: count(*)
                     Buffers: shared hit=8885
                     ->  Append  (cost=0.00..977.64 rows=1739 width=0) (actual time=370.742..1429.244 rows=11 loops=1)
                           Buffers: shared hit=8885
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2018_12_106028 opensky_1  (cost=0.00..0.08 rows=3 width=0) (actual time=4.394..4.395 rows=0 loops=1)
                                 Filter: (opensky_1.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 122
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=68
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_01_106060 opensky_2  (cost=0.00..16.75 rows=37 width=0) (actual time=27.532..27.533 rows=0 loops=1)
                                 Filter: (opensky_2.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 66266
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=181
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_02_106092 opensky_3  (cost=0.00..15.60 rows=35 width=0) (actual time=22.817..22.818 rows=0 loops=1)
                                 Filter: (opensky_3.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 61697
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=179
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_03_106124 opensky_4  (cost=0.00..17.62 rows=37 width=0) (actual time=29.680..29.680 rows=0 loops=1)
                                 Filter: (opensky_4.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 69911
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=182
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_04_106156 opensky_5  (cost=0.00..18.60 rows=39 width=0) (actual time=36.406..36.407 rows=0 loops=1)
                                 Filter: (opensky_5.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 73518
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=186
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_05_106188 opensky_6  (cost=0.00..19.63 rows=40 width=0) (actual time=29.217..29.218 rows=0 loops=1)
                                 Filter: (opensky_6.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 77599
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=187
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_06_106220 opensky_7  (cost=0.00..20.57 rows=40 width=0) (actual time=25.455..25.455 rows=0 loops=1)
                                 Filter: (opensky_7.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 81421
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=194
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_07_106252 opensky_8  (cost=0.00..22.48 rows=43 width=0) (actual time=27.160..27.160 rows=0 loops=1)
                                 Filter: (opensky_8.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 88819
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=199
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_08_106284 opensky_9  (cost=0.00..23.24 rows=43 width=0) (actual time=35.124..35.125 rows=0 loops=1)
                                 Filter: (opensky_9.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 91574
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=202
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_09_106316 opensky_10  (cost=0.00..22.29 rows=42 width=0) (actual time=34.002..34.002 rows=0 loops=1)
                                 Filter: (opensky_10.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 87845
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=197
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_10_106348 opensky_11  (cost=0.00..22.71 rows=41 width=0) (actual time=31.271..31.271 rows=0 loops=1)
                                 Filter: (opensky_11.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 89595
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=200
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_11_106380 opensky_12  (cost=0.00..21.27 rows=42 width=0) (actual time=28.601..28.601 rows=0 loops=1)
                                 Filter: (opensky_12.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 83770
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=194
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2019_12_106412 opensky_13  (cost=0.00..21.53 rows=42 width=0) (actual time=25.612..25.612 rows=0 loops=1)
                                 Filter: (opensky_13.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 84880
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=195
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_01_106444 opensky_14  (cost=0.00..21.79 rows=42 width=0) (actual time=13.443..18.262 rows=2 loops=1)
                                 Filter: (opensky_14.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 84748
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=195
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_02_106476 opensky_15  (cost=0.00..20.85 rows=41 width=0) (actual time=17.363..17.363 rows=0 loops=1)
                                 Filter: (opensky_15.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 81865
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=196
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_03_106508 opensky_16  (cost=0.00..16.93 rows=32 width=0) (actual time=14.426..14.427 rows=0 loops=1)
                                 Filter: (opensky_16.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 66636
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=182
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_04_106540 opensky_17  (cost=0.00..6.49 rows=18 width=0) (actual time=5.790..5.790 rows=0 loops=1)
                                 Filter: (opensky_17.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 26100
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=149
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_05_106572 opensky_18  (cost=0.00..8.18 rows=20 width=0) (actual time=7.785..7.786 rows=0 loops=1)
                                 Filter: (opensky_18.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 32854
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 1
                                 Buffers: shared hit=153
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_06_106604 opensky_19  (cost=0.00..11.20 rows=26 width=0) (actual time=12.603..12.603 rows=0 loops=1)
                                 Filter: (opensky_19.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 44977
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=164
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_07_106636 opensky_20  (cost=0.00..14.79 rows=31 width=0) (actual time=9.458..20.241 rows=1 loops=1)
                                 Filter: (opensky_20.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 58246
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=173
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_08_106668 opensky_21  (cost=0.00..16.13 rows=33 width=0) (actual time=9.283..24.849 rows=2 loops=1)
                                 Filter: (opensky_21.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 63320
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=182
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_09_106700 opensky_22  (cost=0.00..15.18 rows=31 width=0) (actual time=23.483..23.483 rows=0 loops=1)
                                 Filter: (opensky_22.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 59631
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=172
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_10_106732 opensky_23  (cost=0.00..15.21 rows=30 width=0) (actual time=32.276..32.276 rows=0 loops=1)
                                 Filter: (opensky_23.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 60622
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=178
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_11_106764 opensky_24  (cost=0.00..14.21 rows=30 width=0) (actual time=38.658..38.659 rows=0 loops=1)
                                 Filter: (opensky_24.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 56679
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=171
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2020_12_106796 opensky_25  (cost=0.00..14.65 rows=30 width=0) (actual time=34.112..34.112 rows=0 loops=1)
                                 Filter: (opensky_25.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 58275
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=173
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_01_106828 opensky_26  (cost=0.00..13.68 rows=30 width=0) (actual time=22.316..22.316 rows=0 loops=1)
                                 Filter: (opensky_26.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 55113
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=173
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_02_106860 opensky_27  (cost=0.00..12.37 rows=28 width=0) (actual time=24.432..24.433 rows=0 loops=1)
                                 Filter: (opensky_27.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 50023
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=167
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_03_106892 opensky_28  (cost=0.00..16.08 rows=32 width=0) (actual time=30.782..30.783 rows=0 loops=1)
                                 Filter: (opensky_28.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 64912
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=180
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_04_106924 opensky_29  (cost=0.00..16.91 rows=34 width=0) (actual time=25.899..27.808 rows=1 loops=1)
                                 Filter: (opensky_29.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 68482
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=181
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_05_106956 opensky_30  (cost=0.00..17.26 rows=33 width=0) (actual time=22.159..22.159 rows=0 loops=1)
                                 Filter: (opensky_30.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 69827
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=182
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_06_106988 opensky_31  (cost=0.00..19.17 rows=36 width=0) (actual time=16.838..16.838 rows=0 loops=1)
                                 Filter: (opensky_31.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 78261
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=189
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_07_107020 opensky_32  (cost=0.00..42.66 rows=38 width=0) (actual time=19.078..19.078 rows=0 loops=1)
                                 Filter: (opensky_32.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 86786
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=130
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_08_107052 opensky_33  (cost=0.00..21.41 rows=39 width=0) (actual time=42.436..44.973 rows=1 loops=1)
                                 Filter: (opensky_33.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 86453
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=197
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_09_107084 opensky_34  (cost=0.00..20.58 rows=37 width=0) (actual time=35.944..35.944 rows=0 loops=1)
                                 Filter: (opensky_34.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 83163
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=195
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_10_107116 opensky_35  (cost=0.00..20.58 rows=36 width=0) (actual time=37.647..37.647 rows=0 loops=1)
                                 Filter: (opensky_35.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 82875
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=194
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_11_107148 opensky_36  (cost=0.00..18.91 rows=35 width=0) (actual time=43.519..43.519 rows=0 loops=1)
                                 Filter: (opensky_36.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 76825
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=188
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2021_12_107180 opensky_37  (cost=0.00..19.37 rows=36 width=0) (actual time=35.882..35.882 rows=0 loops=1)
                                 Filter: (opensky_37.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 78525
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=189
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_01_107212 opensky_38  (cost=0.00..18.50 rows=35 width=0) (actual time=29.297..29.298 rows=0 loops=1)
                                 Filter: (opensky_38.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 74590
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=187
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_02_107244 opensky_39  (cost=0.00..17.80 rows=34 width=0) (actual time=28.356..28.356 rows=0 loops=1)
                                 Filter: (opensky_39.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 71878
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=186
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_03_107276 opensky_40  (cost=0.00..21.25 rows=37 width=0) (actual time=34.269..34.270 rows=0 loops=1)
                                 Filter: (opensky_40.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 85571
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=195
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_04_107308 opensky_41  (cost=0.00..21.49 rows=39 width=0) (actual time=44.139..44.139 rows=0 loops=1)
                                 Filter: (opensky_41.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 87080
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=198
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_05_107340 opensky_42  (cost=0.00..23.51 rows=42 width=0) (actual time=17.422..22.051 rows=1 loops=1)
                                 Filter: (opensky_42.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 95164
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=208
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_06_107372 opensky_43  (cost=0.00..24.27 rows=41 width=0) (actual time=41.478..41.479 rows=0 loops=1)
                                 Filter: (opensky_43.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 98160
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=207
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_07_107404 opensky_44  (cost=0.00..25.06 rows=42 width=0) (actual time=47.014..47.015 rows=0 loops=1)
                                 Filter: (opensky_44.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 101377
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=209
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_08_107436 opensky_45  (cost=0.00..49.91 rows=43 width=0) (actual time=51.602..51.603 rows=0 loops=1)
                                 Filter: (opensky_45.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 100848
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=143
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_09_107468 opensky_46  (cost=0.00..23.92 rows=42 width=0) (actual time=32.460..46.060 rows=2 loops=1)
                                 Filter: (opensky_46.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 97101
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=205
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_10_107500 opensky_47  (cost=0.00..24.55 rows=42 width=0) (actual time=42.843..42.843 rows=0 loops=1)
                                 Filter: (opensky_47.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 99695
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=205
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_11_107532 opensky_48  (cost=0.00..21.42 rows=41 width=0) (actual time=23.123..38.101 rows=1 loops=1)
                                 Filter: (opensky_48.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 87560
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=196
                           ->  Custom Scan (ColumnarScan) on public.opensky_p2022_12_107564 opensky_49  (cost=0.00..40.33 rows=38 width=0) (actual time=35.369..35.369 rows=0 loops=1)
                                 Filter: (opensky_49.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Rows Removed by Filter: 82396
                                 Columnar Projected Columns: callsign
                                 Columnar Chunk Group Filters: (callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                                 Columnar Chunk Groups Removed by Filter: 0
                                 Buffers: shared hit=129
                           ->  Seq Scan on public.opensky_p2023_01_105996 opensky_50  (cost=0.00..0.00 rows=1 width=0) (actual time=0.013..0.014 rows=0 loops=1)
                                 Filter: (opensky_50.callsign = ANY ('{UUEE,UUDD,UUWW}'::text[]))
                   Planning Time: 125.513 ms
                   Execution Time: 1445.408 ms
         Buffers: shared hit=100
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.663 ms
 Execution Time: 1598.845 ms
(369 rows)

Time: 1611.069 ms (00:01.611)
```
