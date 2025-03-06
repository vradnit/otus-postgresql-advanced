




```
# docker create --name adcm -p 8000:8000 -v /opt/adcm:/adcm/data -e LOG_LEVEL="INFO" hub.arenadata.io/adcm/adcm:2.5.0

# docker start adcm
adcm

# docker ps -a
CONTAINER ID   IMAGE                                              COMMAND                  CREATED              STATUS                   PORTS                                      NAMES
ca75c764c602   hub.arenadata.io/adcm/adcm:2.5.0                   "/etc/startup.sh"        About a minute ago   Up 3 seconds             0.0.0.0:8000->8000/tcp                     adcm
```


```
https://docs.arenadata.io/ru/ADCM/current/get-started/install.html
```

```
User: admin
Password: admin
```

```
загружаем bundle 

adcm_host_ycc_v3.12-1_community.tgz
adcm_cluster_adb_v7.2.0_arenadata1_b1-1_community.tgz
```

```
# cat install.log_1
```


```
ansible -i ./inventory -m shell -b -a 'apt-get -y install cron' all
ansible -i ./inventory -m shell -b -a 'apt-get install -y chrony' all
```


```
gpadmin@master2:~/csv$ wget -O- https://zenodo.org/record/5092942 | grep -oP 'https://zenodo.org/records/5092942/files/flightlist_\d+_\d+\.csv\.gz' | xargs wget
              
gpadmin@master2:~/csv$ ls -al
total 4509016
drwxrwxr-x 2 gpadmin gpadmin      4096 Feb 20 18:10 .
drwxr-x--- 7 gpadmin gpadmin      4096 Feb 20 17:47 ..
-rw-rw-r-- 1 gpadmin gpadmin 149656072 Feb 20 18:11 flightlist_20190101_20190131.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 139872800 Feb 20 17:49 flightlist_20190201_20190228.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 159072441 Feb 20 18:09 flightlist_20190301_20190331.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 166006708 Feb 20 18:08 flightlist_20190401_20190430.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 177692774 Feb 20 17:48 flightlist_20190501_20190531.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 186373210 Feb 20 18:06 flightlist_20190601_20190630.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 203480200 Feb 20 18:03 flightlist_20190701_20190731.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 210148935 Feb 20 18:01 flightlist_20190801_20190831.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 191374713 Feb 20 17:58 flightlist_20190901_20190930.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 206917730 Feb 20 17:55 flightlist_20191001_20191031.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 190775945 Feb 20 17:53 flightlist_20191101_20191130.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 189553155 Feb 20 17:52 flightlist_20191201_20191231.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 193891069 Feb 20 18:04 flightlist_20200101_20200131.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 186334754 Feb 20 18:07 flightlist_20200201_20200229.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 151571888 Feb 20 18:10 flightlist_20200301_20200331.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin  58544368 Feb 20 18:09 flightlist_20200401_20200430.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin  75376842 Feb 20 18:09 flightlist_20200501_20200531.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 100336756 Feb 20 18:05 flightlist_20200601_20200630.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 134445252 Feb 20 18:03 flightlist_20200701_20200731.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 144364225 Feb 20 17:59 flightlist_20200801_20200831.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 136524682 Feb 20 17:58 flightlist_20200901_20200930.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 138560754 Feb 20 17:56 flightlist_20201001_20201031.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 126932585 Feb 20 17:49 flightlist_20201101_20201130.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 132372973 Feb 20 17:50 flightlist_20201201_20201231.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 123902516 Feb 20 17:51 flightlist_20210101_20210131.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 112332587 Feb 20 17:52 flightlist_20210201_20210228.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 144126125 Feb 20 17:54 flightlist_20210301_20210331.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 154290585 Feb 20 17:56 flightlist_20210401_20210430.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 158083429 Feb 20 18:00 flightlist_20210501_20210530.csv.gz
-rw-rw-r-- 1 gpadmin gpadmin 174242634 Feb 20 18:02 flightlist_20210601_20210630.csv.gz
```


```
gpadmin@master2:~$ psql -h 192.168.0.221 postgres
psql (12.12)
Type "help" for help.

postgres=# \l
                            List of databases
   Name    |  Owner  | Encoding | Collate |  Ctype  |  Access privileges  
-----------+---------+----------+---------+---------+---------------------
 adb       | gpadmin | UTF8     | C       | C.UTF-8 | =Tc/gpadmin        +
           |         |          |         |         | gpadmin=CTc/gpadmin
 postgres  | gpadmin | UTF8     | C       | C.UTF-8 | 
 template0 | gpadmin | UTF8     | C       | C.UTF-8 | =c/gpadmin         +
           |         |          |         |         | gpadmin=CTc/gpadmin
 template1 | gpadmin | UTF8     | C       | C.UTF-8 | =c/gpadmin         +
           |         |          |         |         | gpadmin=CTc/gpadmin
(4 rows)

postgres=# CREATE DATABASE otus;
CREATE DATABASE
postgres=# \dx
                                List of installed extensions
      Name       | Version |   Schema   |                    Description                    
-----------------+---------+------------+---------------------------------------------------
 gp_exttable_fdw | 1.0     | pg_catalog | External Table Foreign Data Wrapper for Greenplum
 gp_toolkit      | 1.5     | gp_toolkit | various GPDB administrative views/functions
 plpgsql         | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)

postgres=# CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION
postgres=# \dx
                                    List of installed extensions
      Name       | Version |   Schema   |                        Description                         
-----------------+---------+------------+------------------------------------------------------------
 gp_exttable_fdw | 1.0     | pg_catalog | External Table Foreign Data Wrapper for Greenplum
 gp_toolkit      | 1.5     | gp_toolkit | various GPDB administrative views/functions
 plpgsql         | 1.0     | pg_catalog | PL/pgSQL procedural language
 postgis         | 3.3.2   | public     | PostGIS geometry and geography spatial types and functions
(4 rows)
```

```
otus=# CREATE TABLE opensky                                                         
(
    callsign TEXT,
    number TEXT,
    icao24 TEXT,
    registration TEXT,
    typecode TEXT,
    origin TEXT,
    destination TEXT NULL,
    firstseen TIMESTAMP WITH TIME ZONE NOT NULL,
    lastseen TIMESTAMP WITH TIME ZONE NOT NULL,
    day TIMESTAMP WITH TIME ZONE NOT NULL,
    latitude_1 NUMERIC,
    longitude_1 NUMERIC,
    altitude_1 NUMERIC,
    latitude_2 NUMERIC,
    longitude_2 NUMERIC,
    altitude_2 NUMERIC
) PARTITION BY RANGE (firstseen) DISTRIBUTED BY (callsign);
CREATE TABLE
otus=# 
otus=# CREATE TABLE opensky_2018_12 PARTITION OF opensky FOR VALUES FROM ('2018-12-01 00:00:00') TO ('2019-01-01 00:00:00');
CREATE TABLE opensky_2019_01 PARTITION OF opensky FOR VALUES FROM ('2019-01-01 00:00:00') TO ('2019-02-01 00:00:00');
CREATE TABLE opensky_2019_02 PARTITION OF opensky FOR VALUES FROM ('2019-02-01 00:00:00') TO ('2019-03-01 00:00:00');
CREATE TABLE opensky_2019_03 PARTITION OF opensky FOR VALUES FROM ('2019-03-01 00:00:00') TO ('2019-04-01 00:00:00');
CREATE TABLE opensky_2019_04 PARTITION OF opensky FOR VALUES FROM ('2019-04-01 00:00:00') TO ('2019-05-01 00:00:00');
CREATE TABLE opensky_2019_05 PARTITION OF opensky FOR VALUES FROM ('2019-05-01 00:00:00') TO ('2019-06-01 00:00:00');
CREATE TABLE opensky_2019_06 PARTITION OF opensky FOR VALUES FROM ('2019-06-01 00:00:00') TO ('2019-07-01 00:00:00');
CREATE TABLE opensky_2019_07 PARTITION OF opensky FOR VALUES FROM ('2019-07-01 00:00:00') TO ('2019-08-01 00:00:00');
CREATE TABLE opensky_2019_08 PARTITION OF opensky FOR VALUES FROM ('2019-08-01 00:00:00') TO ('2019-09-01 00:00:00');
CREATE TABLE opensky_2019_09 PARTITION OF opensky FOR VALUES FROM ('2019-09-01 00:00:00') TO ('2019-10-01 00:00:00');
CREATE TABLE opensky_2019_10 PARTITION OF opensky FOR VALUES FROM ('2019-10-01 00:00:00') TO ('2019-11-01 00:00:00');
CREATE TABLE opensky_2019_11 PARTITION OF opensky FOR VALUES FROM ('2019-11-01 00:00:00') TO ('2019-12-01 00:00:00');
CREATE TABLE opensky_2019_12 PARTITION OF opensky FOR VALUES FROM ('2019-12-01 00:00:00') TO ('2020-01-01 00:00:00');
CREATE TABLE opensky_2020_01 PARTITION OF opensky FOR VALUES FROM ('2020-01-01 00:00:00') TO ('2020-02-01 00:00:00');
CREATE TABLE opensky_2020_02 PARTITION OF opensky FOR VALUES FROM ('2020-02-01 00:00:00') TO ('2020-03-01 00:00:00');
CREATE TABLE opensky_2020_03 PARTITION OF opensky FOR VALUES FROM ('2020-03-01 00:00:00') TO ('2020-04-01 00:00:00');
CREATE TABLE opensky_2020_04 PARTITION OF opensky FOR VALUES FROM ('2020-04-01 00:00:00') TO ('2020-05-01 00:00:00');
CREATE TABLE opensky_2020_05 PARTITION OF opensky FOR VALUES FROM ('2020-05-01 00:00:00') TO ('2020-06-01 00:00:00');
CREATE TABLE opensky_2020_06 PARTITION OF opensky FOR VALUES FROM ('2020-06-01 00:00:00') TO ('2020-07-01 00:00:00');
CREATE TABLE opensky_2020_07 PARTITION OF opensky FOR VALUES FROM ('2020-07-01 00:00:00') TO ('2020-08-01 00:00:00');
CREATE TABLE opensky_2020_08 PARTITION OF opensky FOR VALUES FROM ('2020-08-01 00:00:00') TO ('2020-09-01 00:00:00');
CREATE TABLE opensky_2020_09 PARTITION OF opensky FOR VALUES FROM ('2020-09-01 00:00:00') TO ('2020-10-01 00:00:00');
CREATE TABLE opensky_2020_10 PARTITION OF opensky FOR VALUES FROM ('2020-10-01 00:00:00') TO ('2020-11-01 00:00:00');
CREATE TABLE opensky_2020_11 PARTITION OF opensky FOR VALUES FROM ('2020-11-01 00:00:00') TO ('2020-12-01 00:00:00');
CREATE TABLE opensky_2020_12 PARTITION OF opensky FOR VALUES FROM ('2020-12-01 00:00:00') TO ('2021-01-01 00:00:00');
CREATE TABLE opensky_2021_01 PARTITION OF opensky FOR VALUES FROM ('2021-01-01 00:00:00') TO ('2021-02-01 00:00:00');
CREATE TABLE opensky_2021_02 PARTITION OF opensky FOR VALUES FROM ('2021-02-01 00:00:00') TO ('2021-03-01 00:00:00');
CREATE TABLE opensky_2021_03 PARTITION OF opensky FOR VALUES FROM ('2021-03-01 00:00:00') TO ('2021-04-01 00:00:00');
CREATE TABLE opensky_2021_04 PARTITION OF opensky FOR VALUES FROM ('2021-04-01 00:00:00') TO ('2021-05-01 00:00:00');
CREATE TABLE opensky_2021_05 PARTITION OF opensky FOR VALUES FROM ('2021-05-01 00:00:00') TO ('2021-06-01 00:00:00');
CREATE TABLE opensky_2021_06 PARTITION OF opensky FOR VALUES FROM ('2021-06-01 00:00:00') TO ('2021-07-01 00:00:00');
CREATE TABLE opensky_2021_07 PARTITION OF opensky FOR VALUES FROM ('2021-07-01 00:00:00') TO ('2021-08-01 00:00:00');
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
NOTICE:  table has parent, setting distribution columns to match parent table
CREATE TABLE
otus=#
```



```
otus=# CREATE TABLE opensky                                                         
(
    callsign TEXT,
    number TEXT,
    icao24 TEXT,
    registration TEXT,
    typecode TEXT,
    origin TEXT,
    destination TEXT NULL,
    firstseen TIMESTAMP WITH TIME ZONE NOT NULL,
    lastseen TIMESTAMP WITH TIME ZONE NOT NULL,
    day TIMESTAMP WITH TIME ZONE NOT NULL,
    latitude_1 NUMERIC,
    longitude_1 NUMERIC,
    altitude_1 NUMERIC,
    latitude_2 NUMERIC,
    longitude_2 NUMERIC,
    altitude_2 NUMERIC
) USING ao_column DISTRIBUTED BY (callsign) PARTITION BY RANGE (firstseen) ( START (date '2018-12-31') INCLUSIVE END (date '2021-08-01') EXCLUSIVE EVERY (INTERVAL '1 month') );
CREATE TABLE
otus=# \dt
                          List of relations
 Schema |       Name       |       Type        |  Owner  |  Storage  
--------+------------------+-------------------+---------+-----------
 public | opensky          | partitioned table | gpadmin | ao_column
 public | opensky_1_prt_1  | table             | gpadmin | ao_column
 public | opensky_1_prt_10 | table             | gpadmin | ao_column
 public | opensky_1_prt_11 | table             | gpadmin | ao_column
 public | opensky_1_prt_12 | table             | gpadmin | ao_column
 public | opensky_1_prt_13 | table             | gpadmin | ao_column
 public | opensky_1_prt_14 | table             | gpadmin | ao_column
 public | opensky_1_prt_15 | table             | gpadmin | ao_column
 public | opensky_1_prt_16 | table             | gpadmin | ao_column
 public | opensky_1_prt_17 | table             | gpadmin | ao_column
 public | opensky_1_prt_18 | table             | gpadmin | ao_column
 public | opensky_1_prt_19 | table             | gpadmin | ao_column
 public | opensky_1_prt_2  | table             | gpadmin | ao_column
 public | opensky_1_prt_20 | table             | gpadmin | ao_column
 public | opensky_1_prt_21 | table             | gpadmin | ao_column
 public | opensky_1_prt_22 | table             | gpadmin | ao_column
 public | opensky_1_prt_23 | table             | gpadmin | ao_column
 public | opensky_1_prt_24 | table             | gpadmin | ao_column
 public | opensky_1_prt_25 | table             | gpadmin | ao_column
 public | opensky_1_prt_26 | table             | gpadmin | ao_column
 public | opensky_1_prt_27 | table             | gpadmin | ao_column
 public | opensky_1_prt_28 | table             | gpadmin | ao_column
 public | opensky_1_prt_29 | table             | gpadmin | ao_column
 public | opensky_1_prt_3  | table             | gpadmin | ao_column
 public | opensky_1_prt_30 | table             | gpadmin | ao_column
 public | opensky_1_prt_31 | table             | gpadmin | ao_column
 public | opensky_1_prt_32 | table             | gpadmin | ao_column
 public | opensky_1_prt_4  | table             | gpadmin | ao_column
 public | opensky_1_prt_5  | table             | gpadmin | ao_column
 public | opensky_1_prt_6  | table             | gpadmin | ao_column
 public | opensky_1_prt_7  | table             | gpadmin | ao_column
 public | opensky_1_prt_8  | table             | gpadmin | ao_column
 public | opensky_1_prt_9  | table             | gpadmin | ao_column
(33 rows)
```

```
gpadmin@master2:~/csv$ date; for ii in flightlist_2019* flightlist_2020* flightlist_2021* ; do echo ${ii} ; zcat ${ii} | psql -h 192.168.0.221 -d otus -c "COPY opensky from stdin with delimiter ',' CSV HEADER" ; done ; date
Thu Feb 20 19:34:18 UTC 2025
flightlist_20190101_20190131.csv.gz
COPY 2145469
flightlist_20190201_20190228.csv.gz
COPY 2005958
flightlist_20190301_20190331.csv.gz
COPY 2283154
flightlist_20190401_20190430.csv.gz
COPY 2375102
flightlist_20190501_20190531.csv.gz
COPY 2539167
flightlist_20190601_20190630.csv.gz
COPY 2660901
flightlist_20190701_20190731.csv.gz
COPY 2898415
flightlist_20190801_20190831.csv.gz
COPY 2990061
flightlist_20190901_20190930.csv.gz
COPY 2721743
flightlist_20191001_20191031.csv.gz
COPY 2946779
flightlist_20191101_20191130.csv.gz
COPY 2721437
flightlist_20191201_20191231.csv.gz
COPY 2701295
flightlist_20200101_20200131.csv.gz
COPY 2734791
flightlist_20200201_20200229.csv.gz
COPY 2648835
flightlist_20200301_20200331.csv.gz
COPY 2152157
flightlist_20200401_20200430.csv.gz
COPY 842905
flightlist_20200501_20200531.csv.gz
COPY 1088267
flightlist_20200601_20200630.csv.gz
COPY 1444224
flightlist_20200701_20200731.csv.gz
COPY 1905528
flightlist_20200801_20200831.csv.gz
COPY 2042040
flightlist_20200901_20200930.csv.gz
COPY 1930868
flightlist_20201001_20201031.csv.gz
COPY 1985145
flightlist_20201101_20201130.csv.gz
COPY 1825015
flightlist_20201201_20201231.csv.gz
COPY 1894751
flightlist_20210101_20210131.csv.gz
COPY 1783384
flightlist_20210201_20210228.csv.gz
COPY 1617845
flightlist_20210301_20210331.csv.gz
COPY 2079436
flightlist_20210401_20210430.csv.gz
COPY 2227362
flightlist_20210501_20210530.csv.gz
COPY 2278298
flightlist_20210601_20210630.csv.gz
COPY 2540487
Thu Feb 20 21:18:22 UTC 2025
```

```
gpadmin@master2:~/csv$ psql -h 192.168.0.221 postgres
psql (12.12)
Type "help" for help.

postgres=# 
postgres=# 
postgres=# 
postgres=# 
postgres=# 
postgres=# select pg_size_pretty(pg_database_size('otus'));
 pg_size_pretty 
----------------
 7910 MB
(1 row)

postgres=# SELECT COUNT(*) FROM opensky;
ERROR:  relation "opensky" does not exist
LINE 1: SELECT COUNT(*) FROM opensky;
                             ^
postgres=# \c otus 
You are now connected to database "otus" as user "gpadmin".
otus=# SELECT COUNT(*) FROM opensky;
NOTICE:  One or more columns in the following table(s) do not have statistics: opensky
HINT:  For non-partitioned tables, run analyze <table_name>(<column_list>). For partitioned tables, run analyze rootpartition <table_name>(<column_list>). See log for columns missing statistics.
  count   
----------
 66010819
(1 row)

otus=# \timing 
Timing is on.
otus=# SELECT COUNT(*) FROM opensky;
NOTICE:  One or more columns in the following table(s) do not have statistics: opensky
HINT:  For non-partitioned tables, run analyze <table_name>(<column_list>). For partitioned tables, run analyze rootpartition <table_name>(<column_list>). See log for columns missing statistics.
  count   
----------
 66010819
(1 row)

Time: 34091.301 ms (00:34.091)
otus=# 
otus=# ANALYZE ROOTPARTITION opensky;
ANALYZE
Time: 73568.162 ms (01:13.568)
otus=# 
otus=# SELECT COUNT(*) FROM opensky;
  count   
----------
 66010819
(1 row)

Time: 29986.938 ms (00:29.987)
otus=# SELECT COUNT(*) FROM opensky;
  count   
----------
 66010819
(1 row)

Time: 36058.046 ms (00:36.058)
otus=# 
```


```
otus=# SELECT origin, COUNT(*) AS c FROM opensky WHERE origin != '' GROUP BY origin ORDER BY c DESC limit 10;
 origin |   c    
--------+--------
 KORD   | 745007
 KDFW   | 696702
 KATL   | 667286
 KDEN   | 582709
 KLAX   | 581952
 KLAS   | 447789
 KPHX   | 428558
 KSEA   | 412592
 KCLT   | 404612
 VIDP   | 363074
(10 rows)

Time: 78753.492 ms (01:18.753)
otus=# 
otus=# SELECT origin, COUNT(*) AS c FROM opensky WHERE origin != '' GROUP BY origin ORDER BY c DESC limit 10;
 origin |   c    
--------+--------
 KORD   | 745007
 KDFW   | 696702
 KATL   | 667286
 KDEN   | 582709
 KLAX   | 581952
 KLAS   | 447789
 KPHX   | 428558
 KSEA   | 412592
 KCLT   | 404612
 VIDP   | 363074
(10 rows)

Time: 76253.781 ms (01:16.254)
```

```
otus=# 
otus=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 26984.200 ms (00:26.984)
otus=# 
otus=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 28438.271 ms (00:28.438)
```


```
otus=# CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION
Time: 47254.808 ms (00:47.255)
otus=# 
otus=# SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;



 origin | count  | distance 
--------+--------+----------
 KORD   | 745007 |  1547892
 KDFW   | 696702 |  1359825
 KATL   | 667286 |  1170196
 KDEN   | 582709 |  1289130
 KLAX   | 581952 |  2632101
 KLAS   | 447789 |  1338753
 KPHX   | 428558 |  1346816
 KSEA   | 412592 |  1759454
 KCLT   | 404612 |   880548
 VIDP   | 363074 |  1445852
(10 rows)

Time: 2408522.805 ms (40:08.523)
```

```
otus=# SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE firstseen >= '2019-09-01' AND firstseen < '2019-09-02' and origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
 origin | count | distance 
--------+-------+----------
 KORD   |   931 |  1699486
 KATL   |   853 |  1398233
 KLAX   |   746 |  2847843
 EDDF   |   687 |  2136078
 KDFW   |   633 |  1624383
 LFPG   |   632 |  2311505
 EGLL   |   623 |  3237910
 EHAM   |   603 |  2118953
 KDEN   |   602 |  1337483
 KLAS   |   585 |  1303276
(10 rows)

Time: 6733.077 ms (00:06.733)
```



-----------------------------------

```
CREATE TABLE opensky
(
    callsign TEXT,
    number TEXT,
    icao24 TEXT,
    registration TEXT,
    typecode TEXT,
    origin TEXT,
    destination TEXT NULL,
    firstseen TIMESTAMP WITH TIME ZONE NOT NULL,
    lastseen TIMESTAMP WITH TIME ZONE NOT NULL,
    day TIMESTAMP WITH TIME ZONE NOT NULL,
    latitude_1 NUMERIC,
    longitude_1 NUMERIC,
    altitude_1 NUMERIC,
    latitude_2 NUMERIC,
    longitude_2 NUMERIC,
    altitude_2 NUMERIC
) WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=1) DISTRIBUTED BY (callsign) PARTITION BY RANGE (firstseen) ( START (date '2018-12-31') INCLUSIVE END (date '2021-08-01') EXCLUSIVE EVERY (INTERVAL '1 month') );
```

```
adb=# CREATE DATABASE otus;
CREATE DATABASE
adb=# \c otus 
You are now connected to database "otus" as user "gpadmin".
otus=# 
otus=# 
otus=# \dx
                                List of installed extensions
      Name       | Version |   Schema   |                    Description                    
-----------------+---------+------------+---------------------------------------------------
 gp_exttable_fdw | 1.0     | pg_catalog | External Table Foreign Data Wrapper for Greenplum
 gp_toolkit      | 1.5     | gp_toolkit | various GPDB administrative views/functions
 plpgsql         | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)

otus=# CREATE EXTE
EXTENSION       EXTERNAL TABLE  
otus=# CREATE EXTENSION postgis;
CREATE EXTENSION
otus=# 
otus=# 
otus=# \dx
                                    List of installed extensions
      Name       | Version |   Schema   |                        Description                         
-----------------+---------+------------+------------------------------------------------------------
 gp_exttable_fdw | 1.0     | pg_catalog | External Table Foreign Data Wrapper for Greenplum
 gp_toolkit      | 1.5     | gp_toolkit | various GPDB administrative views/functions
 plpgsql         | 1.0     | pg_catalog | PL/pgSQL procedural language
 postgis         | 3.3.2   | public     | PostGIS geometry and geography spatial types and functions
(4 rows)

otus=# 
otus=# 
otus=# CREATE TABLE opensky
(
    callsign TEXT,
    number TEXT,
    icao24 TEXT,
    registration TEXT,
    typecode TEXT,
    origin TEXT,
    destination TEXT NULL,
    firstseen TIMESTAMP WITH TIME ZONE NOT NULL,
    lastseen TIMESTAMP WITH TIME ZONE NOT NULL,
    day TIMESTAMP WITH TIME ZONE NOT NULL,
    latitude_1 NUMERIC,
    longitude_1 NUMERIC,
    altitude_1 NUMERIC,
    latitude_2 NUMERIC,
    longitude_2 NUMERIC,
    altitude_2 NUMERIC
) WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=1) DISTRIBUTED BY (callsign) PARTITION BY RANGE (firstseen) ( START (date '2018-12-31') INCLUSIVE END (date '2021-08-01') EXCLUSIVE EVERY (INTERVAL '1 month') );
CREATE TABLE
otus=# 

otus=# \dt
                          List of relations
 Schema |       Name       |       Type        |  Owner  |  Storage  
--------+------------------+-------------------+---------+-----------
 public | opensky          | partitioned table | gpadmin | ao_column
 public | opensky_1_prt_1  | table             | gpadmin | ao_column
 public | opensky_1_prt_10 | table             | gpadmin | ao_column
 public | opensky_1_prt_11 | table             | gpadmin | ao_column
 public | opensky_1_prt_12 | table             | gpadmin | ao_column
 public | opensky_1_prt_13 | table             | gpadmin | ao_column
 public | opensky_1_prt_14 | table             | gpadmin | ao_column
 public | opensky_1_prt_15 | table             | gpadmin | ao_column
 public | opensky_1_prt_16 | table             | gpadmin | ao_column
 public | opensky_1_prt_17 | table             | gpadmin | ao_column
 public | opensky_1_prt_18 | table             | gpadmin | ao_column
 public | opensky_1_prt_19 | table             | gpadmin | ao_column
 public | opensky_1_prt_2  | table             | gpadmin | ao_column
 public | opensky_1_prt_20 | table             | gpadmin | ao_column
 public | opensky_1_prt_21 | table             | gpadmin | ao_column
 public | opensky_1_prt_22 | table             | gpadmin | ao_column
 public | opensky_1_prt_23 | table             | gpadmin | ao_column
 public | opensky_1_prt_24 | table             | gpadmin | ao_column
 public | opensky_1_prt_25 | table             | gpadmin | ao_column
 public | opensky_1_prt_26 | table             | gpadmin | ao_column
 public | opensky_1_prt_27 | table             | gpadmin | ao_column
 public | opensky_1_prt_28 | table             | gpadmin | ao_column
 public | opensky_1_prt_29 | table             | gpadmin | ao_column
 public | opensky_1_prt_3  | table             | gpadmin | ao_column
 public | opensky_1_prt_30 | table             | gpadmin | ao_column
 public | opensky_1_prt_31 | table             | gpadmin | ao_column
 public | opensky_1_prt_32 | table             | gpadmin | ao_column
 public | opensky_1_prt_4  | table             | gpadmin | ao_column
 public | opensky_1_prt_5  | table             | gpadmin | ao_column
 public | opensky_1_prt_6  | table             | gpadmin | ao_column
 public | opensky_1_prt_7  | table             | gpadmin | ao_column
 public | opensky_1_prt_8  | table             | gpadmin | ao_column
 public | opensky_1_prt_9  | table             | gpadmin | ao_column
 public | spatial_ref_sys  | table             | gpadmin | heap
(34 rows)

```

```
gpadmin@master2:~/csv$ date; for ii in flightlist_2019* flightlist_2020* flightlist_2021* ; do echo ${ii} ; zcat ${ii} | psql -h 192.168.0.221 -d otus -c "COPY opensky from stdin with delimiter ',' CSV HEADER" ; done ; date
Wed Feb 26 20:30:08 UTC 2025
flightlist_20190101_20190131.csv.gz
COPY 2145469
flightlist_20190201_20190228.csv.gz
COPY 2005958
flightlist_20190301_20190331.csv.gz
COPY 2283154
flightlist_20190401_20190430.csv.gz
COPY 2375102
flightlist_20190501_20190531.csv.gz
COPY 2539167
flightlist_20190601_20190630.csv.gz
COPY 2660901
flightlist_20190701_20190731.csv.gz
COPY 2898415
flightlist_20190801_20190831.csv.gz
COPY 2990061
flightlist_20190901_20190930.csv.gz
COPY 2721743
flightlist_20191001_20191031.csv.gz
COPY 2946779
flightlist_20191101_20191130.csv.gz
COPY 2721437
flightlist_20191201_20191231.csv.gz
COPY 2701295
flightlist_20200101_20200131.csv.gz
COPY 2734791
flightlist_20200201_20200229.csv.gz
COPY 2648835
flightlist_20200301_20200331.csv.gz
COPY 2152157
flightlist_20200401_20200430.csv.gz
COPY 842905
flightlist_20200501_20200531.csv.gz
COPY 1088267
flightlist_20200601_20200630.csv.gz
COPY 1444224
flightlist_20200701_20200731.csv.gz
COPY 1905528
flightlist_20200801_20200831.csv.gz
COPY 2042040
flightlist_20200901_20200930.csv.gz
COPY 1930868
flightlist_20201001_20201031.csv.gz
COPY 1985145
flightlist_20201101_20201130.csv.gz
COPY 1825015
flightlist_20201201_20201231.csv.gz
COPY 1894751
flightlist_20210101_20210131.csv.gz
COPY 1783384
flightlist_20210201_20210228.csv.gz
COPY 1617845
flightlist_20210301_20210331.csv.gz
COPY 2079436
flightlist_20210401_20210430.csv.gz
COPY 2227362
flightlist_20210501_20210530.csv.gz
COPY 2278298
flightlist_20210601_20210630.csv.gz
COPY 2540487
Wed Feb 26 20:42:27 UTC 2025
```


## README-install-adb.md
```
{include} README-install-adb.md
```
