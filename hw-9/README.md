# **HW-9 | Разворачиваем и настраиваем БД с большими данными**


## **Цель:**
знать различные механизмы загрузки данных
уметь пользоваться различными механизмами загрузки данных



## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Необходимо провести сравнение скорости работы запросов на различных СУБД  
  
Выбрать одну из СУБД
Загрузить в неё данные (от 10 до 100 Гб)
Сравнить скорость выполнения запросов на PosgreSQL и выбранной СУБД
Описать что и как делали и с какими проблемами столкнулись



## **Выполнение ДЗ**

### **Проведем тестирование в три этапа**
- Postgres
- Postgres + TimescaleDB
- Clickhouse

### **Установка ВМ**
**Создаем VM**
```
[root@test2 hw-9]# yc vpc network create --name "otus-net" --description "otus-net"
id: enp45c69dpq8kqldr494
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-16T11:20:47Z"
name: otus-net
description: otus-net
default_security_group_id: enpj1lnavpkc7k5p3c3c

[root@test2 hw-9]# yc vpc subnet create --name otus-subnet --range 10.95.99.0/24 --network-name otus-net --description "otus-subnet"
id: e9b3ainluhk4mvr977k8
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-16T11:21:02Z"
name: otus-subnet
description: otus-subnet
network_id: enp45c69dpq8kqldr494
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.95.99.0/24

[root@test2 hw-9]# yc vpc subnet list
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
|          ID          |    NAME     |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
| e9b3ainluhk4mvr977k8 | otus-subnet | enp45c69dpq8kqldr494 |                | ru-central1-a | [10.95.99.0/24] |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+

[root@test2 hw-9]# yc compute instance create --name db1 --hostname db1 --cores 4 --memory 8 --create-boot-disk size=40G,type=network-ssd,image-folder-id=standard-images,image-family=almalinux-8 --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub
done (45s)
id: fhmuduq6m2srbbeuh5co
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-16T11:25:25Z"
name: db1
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "8589934592"
  cores: "4"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm8e9lb35oa1o3tacn9
  auto_delete: true
  disk_id: fhm8e9lb35oa1o3tacn9
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1e:6f:b4:6b
    subnet_id: e9b3ainluhk4mvr977k8
    primary_v4_address:
      address: 10.95.99.7
      one_to_one_nat:
        address: 158.160.50.145
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: db1.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1

[root@test2 hw-9]# yc compute instance list
+----------------------+------+---------------+---------+----------------+-------------+
|          ID          | NAME |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+----------------------+------+---------------+---------+----------------+-------------+
| fhmuduq6m2srbbeuh5co | db1  | ru-central1-a | RUNNING | 158.160.50.145 | 10.95.99.7  |
+----------------------+------+---------------+---------+----------------+-------------+
```

### **Установка postgres**
**Установка пакетов**
```
[root@db1 yc-user]# dnf update -y
[root@db1 yc-user]# dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@db1 yc-user]# dnf -qy module disable postgresql
[root@db1 yc-user]# dnf install postgresql16-server postgresql16-contrib
```
**Установка расширения postgis для postgres**
```
[root@db1 yc-user]# dnf -y config-manager --set-enabled powertools
[root@db1 yc-user]# dnf -y install epel-release
[root@db1 yc-user]# dnf install postgis35_16
```
**Инициализируем БД и стартуем сервис**
```
[root@db1 yc-user]# /usr/pgsql-16/bin/postgresql-16-setup initdb
[root@db1 yc-user]# systemctl enable postgresql-16
[root@db1 yc-user]# systemctl start postgresql-16
[root@db1 yc-user]# systemctl status postgresql-16
● postgresql-16.service - PostgreSQL 16 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-12-16 11:54:55 UTC; 5s ago
     Docs: https://www.postgresql.org/docs/16/static/
  Process: 49857 ExecStartPre=/usr/pgsql-16/bin/postgresql-16-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)
 Main PID: 49863 (postgres)
    Tasks: 7 (limit: 48754)
   Memory: 17.7M
   CGroup: /system.slice/postgresql-16.service
           ├─49863 /usr/pgsql-16/bin/postgres -D /var/lib/pgsql/16/data/
           ├─49864 postgres: logger 
           ├─49865 postgres: checkpointer 
           ├─49866 postgres: background writer 
           ├─49868 postgres: walwriter 
           ├─49869 postgres: autovacuum launcher 
           └─49870 postgres: logical replication launcher 

Dec 16 11:54:55 db1.ru-central1.internal systemd[1]: Starting PostgreSQL 16 database server...
Dec 16 11:54:55 db1.ru-central1.internal postgres[49863]: 2024-12-16 11:54:55.764 UTC [49863] LOG:  redirecting log output to logging collector process
Dec 16 11:54:55 db1.ru-central1.internal postgres[49863]: 2024-12-16 11:54:55.764 UTC [49863] HINT:  Future log output will appear in directory "log".
Dec 16 11:54:55 db1.ru-central1.internal systemd[1]: Started PostgreSQL 16 database server.
```

**Настраиваем tuned**
```
[root@db1 yc-user]# mkdir /usr/lib/tuned/postgresql/
[root@db1 yc-user]# vi /usr/lib/tuned/postgresql/tuned.conf

[root@db1 yc-user]# cat /usr/lib/tuned/postgresql/tuned.conf
[main]
summary=Optimize for PostgreSQL RDBMS
include=throughput-performance
[sysctl]
vm.swappiness = 5
vm.dirty_background_ratio = 10
vm.dirty_ratio = 40
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
kernel.shmmax = 18446744073692700000
kernel.shmall = 18446744073692700000
kernel.shmmni = 4096
kernel.sem = 250 512000 100 2048
fs.file-max = 312139770
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 2048 65499
# Permits sockets in the time-wait state to be reused for new connections:
net.ipv4.tcp_tw_reuse = 1
net.core.netdev_budget = 1024
net.core.netdev_max_backlog = 2048
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
# We don't need NUMA balancing in this box:
kernel.numa_balancing = 0
# Used if not defined by the service:
net.core.somaxconn = 4096
# Other parameters to override throughput-performance template
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_window_scaling = 1
net.netfilter.nf_conntrack_max = 250000
net.ipv4.tcp_max_syn_backlog=4096
[vm]
transparent_hugepages=never

[root@db1 yc-user]# restorecon -RFvv /usr/lib/tuned/postgresql
Relabeled /usr/lib/tuned/postgresql from unconfined_u:object_r:lib_t:s0 to system_u:object_r:lib_t:s0
Relabeled /usr/lib/tuned/postgresql/tuned.conf from unconfined_u:object_r:lib_t:s0 to system_u:object_r:lib_t:s0

[root@db1 yc-user]# tuned-adm list | grep postgre
- postgresql                  - Optimize for PostgreSQL RDBMS
[root@db1 yc-user]# tuned-adm profile postgresql
[root@db1 yc-user]# tuned-adm active
Current active profile: postgresql
```

**Увеличиваем лимиты для пользователя postgres**   
в systed юните:
```
[root@db1 yc-user]# vi /usr/lib/systemd/system/postgresql-16.service
[root@db1 yc-user]# grep -B 6 ^Limit /usr/lib/systemd/system/postgresql-16.service
[Service]
Type=notify

User=postgres
Group=postgres

LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitNOFILE=500000
LimitNOPROC=500000
```
а также в /etc/security/limits.d/30-pgsqlproc.conf
```
[root@db1 vagrant]# vi /etc/security/limits.d/30-pgsqlproc.conf
[root@db1 vagrant]# cat /etc/security/limits.d/30-pgsqlproc.conf 
* soft nofile 500000
* hard nofile 500000
root soft nofile 500000
root hard nofile 500000
postgres soft nofile 500000
postgres hard nofile 500000
```
**Восстанавливаем правила selinux**
```
[root@db1 yc-user]# restorecon -Fvv /etc/security/limits.d/30-pgsqlproc.conf
Relabeled /etc/security/limits.d/30-pgsqlproc.conf from unconfined_u:object_r:etc_t:s0 to system_u:object_r:etc_t:s0
```


**Используя https://www.pgconfig.org и входные параметры:**
```
num_cpu=4
total_mem=8G
max_conn=100
postgres_version=16
storage=ssd
profile=dw
```

**Формируем параметры для postgresql.conf**
```
# Generated by PGConfig 3.1.4 (1fe6d98dedcaad1d0a114617cfd08b4fed1d8a01)
# https://api.pgconfig.org/v1/tuning/get-config?format=conf&&log_format=csvlog&max_connections=100&pg_version=16&environment_name=DW&total_ram=8GB&cpus=4&drive_type=SSD&arch=x86-64&os_type=linux

# Memory Configuration
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 41MB
maintenance_work_mem = 410MB

# Checkpoint Related Configuration
min_wal_size = 2GB
max_wal_size = 3GB
checkpoint_completion_target = 0.9
wal_buffers = -1

# Network Related Configuration
listen_addresses = '*'
max_connections = 100

# Storage Configuration
random_page_cost = 1.1
effective_io_concurrency = 200

# Worker Processes Configuration
max_worker_processes = 8
max_parallel_workers_per_gather = 2
max_parallel_workers = 2
```

**Перегружаем VM**
```
[root@db1 yc-user]# reboot
Connection to 158.160.50.145 closed by remote host.
Connection to 158.160.50.145 closed
```

**Проверяем настройки**
```
[root@db1 yc-user]# sysctl -a | grep vm.swappiness
vm.swappiness = 5
[root@db1 yc-user]# 
[root@db1 yc-user]# sudo -u postgres psql -c 'SHOW shared_buffers'
 shared_buffers 
----------------
 2GB
(1 row)

[root@db1 yc-user]# 
[root@db1 yc-user]# sudo -u postgres psql -c 'SHOW effective_cache_size'
 effective_cache_size 
----------------------
 6GB
(1 row)
```

### **Загрузка CSV на VM**
**В качесте источника больших данных выбрана статистика полетов с 2019 по 2021 год**
```
[root@db1 yc-user]# sudo -u postgres bash
bash-4.4$ mkdir /var/lib/pgsql/files
bash-4.4$ cd /var/lib/pgsql/files

bash-4.4$ wget -O- https://zenodo.org/record/5092942 | grep -oP 'https://zenodo.org/records/5092942/files/flightlist_\d+_\d+\.csv\.gz' | xargs wget

bash-4.4$ ls -al ./flightlist_20*
-rw-r--r--. 1 postgres postgres 149656072 Dec 16 12:32 ./flightlist_20190101_20190131.csv.gz
-rw-r--r--. 1 postgres postgres 139872800 Dec 16 12:31 ./flightlist_20190201_20190228.csv.gz
-rw-r--r--. 1 postgres postgres 159072441 Dec 16 12:31 ./flightlist_20190301_20190331.csv.gz
-rw-r--r--. 1 postgres postgres 166006708 Dec 16 12:31 ./flightlist_20190401_20190430.csv.gz
-rw-r--r--. 1 postgres postgres 177692774 Dec 16 12:30 ./flightlist_20190501_20190531.csv.gz
-rw-r--r--. 1 postgres postgres 186373210 Dec 16 12:31 ./flightlist_20190601_20190630.csv.gz
-rw-r--r--. 1 postgres postgres 203480200 Dec 16 12:31 ./flightlist_20190701_20190731.csv.gz
-rw-r--r--. 1 postgres postgres 210148935 Dec 16 12:31 ./flightlist_20190801_20190831.csv.gz
-rw-r--r--. 1 postgres postgres 191374713 Dec 16 12:31 ./flightlist_20190901_20190930.csv.gz
-rw-r--r--. 1 postgres postgres 206917730 Dec 16 12:31 ./flightlist_20191001_20191031.csv.gz
-rw-r--r--. 1 postgres postgres 190775945 Dec 16 12:31 ./flightlist_20191101_20191130.csv.gz
-rw-r--r--. 1 postgres postgres 189553155 Dec 16 12:31 ./flightlist_20191201_20191231.csv.gz
-rw-r--r--. 1 postgres postgres 193891069 Dec 16 12:31 ./flightlist_20200101_20200131.csv.gz
-rw-r--r--. 1 postgres postgres 186334754 Dec 16 12:31 ./flightlist_20200201_20200229.csv.gz
-rw-r--r--. 1 postgres postgres 151571888 Dec 16 12:32 ./flightlist_20200301_20200331.csv.gz
-rw-r--r--. 1 postgres postgres  58544368 Dec 16 12:32 ./flightlist_20200401_20200430.csv.gz
-rw-r--r--. 1 postgres postgres  75376842 Dec 16 12:32 ./flightlist_20200501_20200531.csv.gz
-rw-r--r--. 1 postgres postgres 100336756 Dec 16 12:31 ./flightlist_20200601_20200630.csv.gz
-rw-r--r--. 1 postgres postgres 134445252 Dec 16 12:31 ./flightlist_20200701_20200731.csv.gz
-rw-r--r--. 1 postgres postgres 144364225 Dec 16 12:31 ./flightlist_20200801_20200831.csv.gz
-rw-r--r--. 1 postgres postgres 136524682 Dec 16 12:31 ./flightlist_20200901_20200930.csv.gz
-rw-r--r--. 1 postgres postgres 138560754 Dec 16 12:31 ./flightlist_20201001_20201031.csv.gz
-rw-r--r--. 1 postgres postgres 126932585 Dec 16 12:31 ./flightlist_20201101_20201130.csv.gz
-rw-r--r--. 1 postgres postgres 132372973 Dec 16 12:31 ./flightlist_20201201_20201231.csv.gz
-rw-r--r--. 1 postgres postgres 123902516 Dec 16 12:31 ./flightlist_20210101_20210131.csv.gz
-rw-r--r--. 1 postgres postgres 112332587 Dec 16 12:31 ./flightlist_20210201_20210228.csv.gz
-rw-r--r--. 1 postgres postgres 144126125 Dec 16 12:31 ./flightlist_20210301_20210331.csv.gz
-rw-r--r--. 1 postgres postgres 154290585 Dec 16 12:31 ./flightlist_20210401_20210430.csv.gz
-rw-r--r--. 1 postgres postgres 158083429 Dec 16 12:31 ./flightlist_20210501_20210530.csv.gz
-rw-r--r--. 1 postgres postgres 174242634 Dec 16 12:31 ./flightlist_20210601_20210630.csv.gz
```

### **Подготовка БД к загрузке данных**
**Создаем БД и таблицу, а также подключаем расширение postgis:**
```
bash-4.4$ psql 
psql (16.6)
Type "help" for help.

postgres=# CREATE DATABASE opensky;
CREATE DATABASE
postgres=# \c opensky 
You are now connected to database "opensky" as user "postgres".
opensky=# \dx
                 List of installed extensions
  Name   | Version |   Schema   |         Description          
---------+---------+------------+------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(1 row)

opensky=# CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION
opensky=# \dx
                                List of installed extensions
  Name   | Version |   Schema   |                        Description                         
---------+---------+------------+------------------------------------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
 postgis | 3.5.0   | public     | PostGIS geometry and geography spatial types and functions
(2 rows)

opensky=# CREATE TABLE opensky
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
);
CREATE TABLE
opensky=#
```


### **Загружаем данные в таблицу opensky**
```
bash-4.4$ for ii in flightlist_2019* flightlist_2020* flightlist_2021* ; do echo ${ii} ; zcat ${ii} | psql -d opensky -U postgres -c "COPY opensky from stdin with delimiter ',' CSV HEADER" ; done
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
```
**Продолжительность загрузки составила 18 минут**


**Проверяем объем БД**
```
opensky=# select pg_size_pretty(pg_database_size('opensky'));
 pg_size_pretty 
----------------
 10 GB
(1 row)
```


### **Запускаем аналитические запросы в postgresql**
- **Общее кол-во полетов**
```
opensky=# \timing on
Timing is on.
opensky=# SELECT COUNT(*) FROM opensky;
  count   
----------
 66010819
(1 row)

Time: 336978.699 ms (05:36.979)
```
- **Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')"**
```
opensky=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 329208.952 ms (05:29.209)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов**
```
opensky=# SELECT origin, COUNT(*) FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC limit 10;
 origin | count  
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

Time: 332567.092 ms (05:32.567)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов и с расчетом суммарного полетного расстояния**
```
opensky=# SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
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

Time: 328940.672 ms (05:28.941)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов и с расчетом суммарного полетного расстояния за 2019-09-01**
```
opensky=# SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE firstseen >= '2019-09-01' AND firstseen < '2019-09-02' and origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
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

Time: 328315.232 ms (05:28.315)
```


### **Установка TimescaleDB**
**Установка пакетов**
```
[root@db1 yc-user]# yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %{rhel})-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@db1 yc-user]# sudo tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/$(rpm -E %{rhel})/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

[root@db1 yc-user]# yum update
[root@db1 yc-user]# dnf -qy module disable postgresql
[root@db1 yc-user]# yum install timescaledb-2-postgresql-16 postgresql16
```

**Тюнинг Postgres**  
т.е. соглашаемся на все, что предлагает timescaledb-tune
```
[root@db1 yc-user]# timescaledb-tune --pg-config=/usr/pgsql-16/bin/pg_config -conf-path=/var/lib/pgsql/16/data/postgresql.conf
Using postgresql.conf at this path:
/var/lib/pgsql/16/data/postgresql.conf

Writing backup to:
/tmp/timescaledb_tune.backup202412161344

shared_preload_libraries needs to be updated
Current:
#shared_preload_libraries = ''
Recommended:
shared_preload_libraries = 'timescaledb'
Is this okay? [(y)es/(n)o]: Y
success: shared_preload_libraries will be updated

Tune memory/parallelism/WAL and other settings? [(y)es/(n)o]: Y
Recommendations based on 7.52 GB of available memory and 4 CPUs for PostgreSQL 16

Memory settings recommendations
Current:
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 410MB
work_mem = 41MB
Recommended:
shared_buffers = 1924MB
effective_cache_size = 5772MB
maintenance_work_mem = 985238kB
work_mem = 4926kB
Is this okay? [(y)es/(s)kip/(q)uit]: y
success: memory settings will be updated

Parallelism settings recommendations
Current:
missing: timescaledb.max_background_workers
max_worker_processes = 8
max_parallel_workers = 2
Recommended:
timescaledb.max_background_workers = 16
max_worker_processes = 23
max_parallel_workers = 4
Is this okay? [(y)es/(s)kip/(q)uit]: y
success: parallelism settings will be updated

WAL settings recommendations
Current:
wal_buffers = -1
min_wal_size = 2GB
max_wal_size = 3GB
Recommended:
wal_buffers = 16MB
min_wal_size = 512MB
max_wal_size = 1GB
Is this okay? [(y)es/(s)kip/(q)uit]: y
success: WAL settings will be updated

Background writer settings recommendations
success: background writer settings are already tuned

Miscellaneous settings recommendations
Current:
#default_statistics_target = 100
#max_locks_per_transaction = 64
#autovacuum_max_workers = 3
#autovacuum_naptime = 1min
#default_toast_compression = 'pglz'
#jit = on
effective_io_concurrency = 200
Recommended:
default_statistics_target = 100
max_locks_per_transaction = 128
autovacuum_max_workers = 10
autovacuum_naptime = 10
default_toast_compression = lz4
jit = off
effective_io_concurrency = 256
Is this okay? [(y)es/(s)kip/(q)uit]: y
success: miscellaneous settings will be updated
Saving changes to: /var/lib/pgsql/16/data/postgresql.conf
```

**Рестартуем postgres**
```
[root@db1 yc-user]# systemctl restart postgresql-16
```

**Подключаем расширение timescaledb**
```
root@db1 yc-user]# sudo -u postgres bash
bash-4.4$ psql 
psql (16.6)
Type "help" for help.

postgres=# \c opensky 
You are now connected to database "opensky" as user "postgres".
opensky=# 
opensky=# \dx
                                List of installed extensions
  Name   | Version |   Schema   |                        Description                         
---------+---------+------------+------------------------------------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
 postgis | 3.5.0   | public     | PostGIS geometry and geography spatial types and functions
(2 rows)

opensky=# CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION
opensky=# \dx
                                                List of installed extensions
    Name     | Version |   Schema   |                                      Description                                      
-------------+---------+------------+---------------------------------------------------------------------------------------
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 postgis     | 3.5.0   | public     | PostGIS geometry and geography spatial types and functions
 timescaledb | 2.17.2  | public     | Enables scalable inserts and complex queries for time-series data (Community Edition)
(3 rows)
```

**Конвертируем таблицу opensky в hypertable**
```
opensky=# SELECT create_hypertable('opensky', by_range('firstseen'), create_default_indexes=>FALSE);
ERROR:  table "opensky" is not empty
HINT:  You can migrate data by specifying 'migrate_data => true' when calling this function.
Time: 2.161 ms
opensky=# 
opensky=# show_chunks('opensky');
ERROR:  syntax error at or near "show_chunks"
LINE 1: show_chunks('opensky');
        ^
Time: 0.251 ms
opensky=# 
opensky=# SELECT show_chunks('opensky');
ERROR:  "opensky" is not a hypertable or a continuous aggregate
HINT:  The operation is only possible on a hypertable or continuous aggregate.
Time: 0.628 ms
opensky=# 
opensky=# SELECT create_hypertable('opensky', by_range('firstseen'), create_default_indexes=>FALSE);
ERROR:  table "opensky" is not empty
HINT:  You can migrate data by specifying 'migrate_data => true' when calling this function.
Time: 0.503 ms
opensky=# 
opensky=# SELECT create_hypertable('opensky', by_range('firstseen'), create_default_indexes=>FALSE, migrate_data=> true);
NOTICE:  migrating data to chunks
DETAIL:  Migration might take a while depending on the amount of data.
 create_hypertable 
-------------------
 (1,t)
(1 row)

Time: 1015854.030 ms (16:55.854)
```

### **Запускаем аналитические запросы в Postgresql с TimescaleDB**
- **Общее кол-во полетов**
```
opensky=# SELECT COUNT(*) FROM opensky;
  count
----------
 66010819
(1 row)

Time: 622203.555 ms (10:22.204)
```
- **Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')"**
```
opensky=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 303610.971 ms (05:03.611)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов**
```
opensky=# SELECT origin, COUNT(*) FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC limit 10;
 origin | count  
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

Time: 291756.229 ms (04:51.756)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов и с расчетом суммарного полетного расстояния**
```
opensky=# SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
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

Time: 292699.033 ms (04:52.699)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов и с расчетом суммарного полетного расстояния за 2019-09-01**
```
opensky=# SELECT origin, count(*), round(avg(ST_Distance(ST_MakePoint(longitude_1, latitude_1)::geography, ST_MakePoint(longitude_2, latitude_2)::geography))) AS distance FROM opensky WHERE firstseen >= '2019-09-01' AND firstseen < '2019-09-02' and origin != '' GROUP BY origin ORDER BY count(*) DESC LIMIT 10;
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
 
Time: 330.602 ms 
```


### **Clickhouse**
**Установка Clickhouse**
```
[root@db1 yc-user]# grep -q sse4_2 /proc/cpuinfo && echo "SSE 4.2 supported" || echo "SSE 4.2 not supported"
SSE 4.2 supported
```

```
[root@db1 yc-user]# sudo yum install -y yum-utils

[root@db1 yc-user]# yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo
Adding repo from: https://packages.clickhouse.com/rpm/clickhouse.repo
```

```
[root@db1 yc-user]# yum install -y clickhouse-server clickhouse-client
```

```
[root@db1 yc-user]# systemctl enable clickhouse-server
Synchronizing state of clickhouse-server.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable clickhouse-server
[root@db1 yc-user]# systemctl start clickhouse-server
[root@db1 yc-user]# systemctl status clickhouse-server
● clickhouse-server.service - ClickHouse Server (analytic DBMS for big data)
   Loaded: loaded (/usr/lib/systemd/system/clickhouse-server.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-12-16 14:42:06 UTC; 4s ago
 Main PID: 6386 (clickhouse-serv)
    Tasks: 678 (limit: 48754)
   Memory: 123.7M
   CGroup: /system.slice/clickhouse-server.service
           ├─6383 clickhouse-watchdog --config=/etc/clickhouse-server/config.xml --pid-file=/run/clickhouse-server/clickhouse-server.pid
           └─6386 /usr/bin/clickhouse-server --config=/etc/clickhouse-server/config.xml --pid-file=/run/clickhouse-server/clickhouse-server.pid

Dec 16 14:42:05 db1.ru-central1.internal systemd[1]: Starting ClickHouse Server (analytic DBMS for big data)...
Dec 16 14:42:05 db1.ru-central1.internal clickhouse-server[6383]: Processing configuration file '/etc/clickhouse-server/config.xml'.
Dec 16 14:42:05 db1.ru-central1.internal clickhouse-server[6383]: Logging trace to /var/log/clickhouse-server/clickhouse-server.log
Dec 16 14:42:05 db1.ru-central1.internal clickhouse-server[6383]: Logging errors to /var/log/clickhouse-server/clickhouse-server.err.log
Dec 16 14:42:05 db1.ru-central1.internal systemd[1]: clickhouse-server.service: Supervising process 6386 which is not our child. We'll most likely not notice when it exits.
Dec 16 14:42:06 db1.ru-central1.internal systemd[1]: Started ClickHouse Server (analytic DBMS for big data).
```

### **Создаем таблицу в Сlickhouse**
```
[root@db1 yc-user]# clickhouse-client
ClickHouse client version 24.11.1.2557 (official build).
Connecting to localhost:9000 as user default.
Connected to ClickHouse server version 24.11.1.

db1.ru-central1.internal :) 
CREATE TABLE opensky
(
    `callsign` String,
    `number` String,
    `icao24` String,
    `registration` String,
    `typecode` String,
    `origin` String,
    `destination` String,
    `firstseen` DateTime,
    `lastseen` DateTime,
    `day` DateTime,
    `latitude_1` Float64,
    `longitude_1` Float64,
    `altitude_1` Float64,
    `latitude_2` Float64,
    `longitude_2` Float64,
    `altitude_2` Float64
)
ENGINE = MergeTree
ORDER BY (origin, destination, callsign)

Query id: cffab7dd-3f20-4a95-a69d-b9c4b0eb4881

Ok.

0 rows in set. Elapsed: 0.024 sec. 

db1.ru-central1.internal :) 
```

### **Загружаем данные в ClickHouse**
**Продолжительность загрузки данных составила 6 минут**
```
[root@db1 files]# for file in flightlist_*.csv.gz; do gzip -c -d "$file" | clickhouse-client --date_time_input_format best_effort --query "INSERT INTO opensky FORMAT CSVWithNames"; done
```

### **Запускаем аналитические запросы в ClickHouse**

- **Общее кол-во полетов**
```
[root@db1 files]# clickhouse-client
ClickHouse client version 24.11.1.2557 (official build).
Connecting to localhost:9000 as user default.
Connected to ClickHouse server version 24.11.1.

db1.ru-central1.internal :) SELECT COUNT(*) FROM opensky;

Query id: 90b93895-836b-493d-8212-a8416507a93f

   ┌──COUNT()─┐
1. │ 66010819 │ -- 66.01 million
   └──────────┘

1 row in set. Elapsed: 0.002 sec. 
```
- **Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')"**
```
db1.ru-central1.internal :)
SELECT COUNT(*)
FROM opensky
WHERE callsign IN ('UUEE', 'UUDD', 'UUWW')

Query id: 3011acd3-3070-467b-beac-c0a5013ef7e2

   ┌─COUNT()─┐
1. │      14 │
   └─────────┘

1 row in set. Elapsed: 0.401 sec. Processed 51.36 million rows, 779.89 MB (128.16 million rows/s., 1.95 GB/s.)
Peak memory usage: 555.43 KiB.
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов**
```
db1.ru-central1.internal :)
SELECT
    origin,
    COUNT(*)
FROM opensky
WHERE origin != ''
GROUP BY origin
ORDER BY count(*) DESC
LIMIT 10

Query id: 98d5cccf-3c55-4cf7-8ba4-0390f6ac23b2

    ┌─origin─┬─COUNT()─┐
 1. │ KORD   │  745007 │
 2. │ KDFW   │  696702 │
 3. │ KATL   │  667286 │
 4. │ KDEN   │  582709 │
 5. │ KLAX   │  581952 │
 6. │ KLAS   │  447789 │
 7. │ KPHX   │  428558 │
 8. │ KSEA   │  412592 │
 9. │ KCLT   │  404612 │
10. │ VIDP   │  363074 │
    └────────┴─────────┘

10 rows in set. Elapsed: 0.383 sec. Processed 48.33 million rows, 628.21 MB (126.10 million rows/s., 1.64 GB/s.)
Peak memory usage: 1.95 MiB.
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов и с расчетом суммарного полетного расстояния**
```
db1.ru-central1.internal :)
SELECT
    origin,
    count(),
    round(avg(geoDistance(longitude_1, latitude_1, longitude_2, latitude_2))) AS distance,
    bar(distance, 0, 10000000, 100) AS bar
FROM opensky
WHERE origin != ''
GROUP BY origin
ORDER BY count() DESC
LIMIT 10

Query id: b688732d-1062-453f-a8b8-2ed47e67cde1

    ┌─origin─┬─count()─┬─distance─┬─bar─────────────────────────┐
 1. │ KORD   │  745007 │  1546108 │ ███████████████▍            │
 2. │ KDFW   │  696702 │  1358721 │ █████████████▌              │
 3. │ KATL   │  667286 │  1169661 │ ███████████▋                │
 4. │ KDEN   │  582709 │  1287742 │ ████████████▉               │
 5. │ KLAX   │  581952 │  2628393 │ ██████████████████████████▎ │
 6. │ KLAS   │  447789 │  1336967 │ █████████████▎              │
 7. │ KPHX   │  428558 │  1345635 │ █████████████▍              │
 8. │ KSEA   │  412592 │  1757317 │ █████████████████▌          │
 9. │ KCLT   │  404612 │   880356 │ ████████▊                   │
10. │ VIDP   │  363074 │  1445052 │ ██████████████▍             │
    └────────┴─────────┴──────────┴─────────────────────────────┘

10 rows in set. Elapsed: 3.303 sec. Processed 48.33 million rows, 2.17 GB (14.63 million rows/s., 658.46 MB/s.)
Peak memory usage: 16.74 MiB.
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов и с расчетом суммарного полетного расстояния за 2019-09-01**
```
db1.ru-central1.internal :)

SELECT
    origin,
    count(),
    round(avg(geoDistance(longitude_1, latitude_1, longitude_2, latitude_2))) AS distance,
    bar(distance, 0, 10000000, 100) AS bar
FROM opensky
WHERE (origin != '') AND (firstseen >= '2019-09-01') AND (firstseen < '2019-09-02')
GROUP BY origin
ORDER BY count() DESC
LIMIT 10

Query id: 55522efe-2183-4170-9476-324e90f45981

    ┌─origin─┬─count()─┬─distance─┬─bar───────────────────────────────┐
 1. │ KORD   │     931 │  1696993 │ ████████████████▉                 │
 2. │ KATL   │     853 │  1397177 │ █████████████▉                    │
 3. │ KLAX   │     746 │  2843895 │ ████████████████████████████▍     │
 4. │ EDDF   │     687 │  2133420 │ █████████████████████▎            │
 5. │ KDFW   │     633 │  1622633 │ ████████████████▏                 │
 6. │ LFPG   │     632 │  2308757 │ ███████████████████████           │
 7. │ EGLL   │     623 │  3232826 │ ████████████████████████████████▎ │
 8. │ EHAM   │     603 │  2116703 │ █████████████████████▏            │
 9. │ KDEN   │     602 │  1335762 │ █████████████▎                    │
10. │ KLAS   │     585 │  1301395 │ █████████████                     │
    └────────┴─────────┴──────────┴───────────────────────────────────┘

10 rows in set. Elapsed: 0.758 sec. Processed 48.33 million rows, 1.11 GB (63.73 million rows/s., 1.46 GB/s.)
Peak memory usage: 6.23 MiB.
```

### **Удаляем все ранее созданные ресурсы** 
```
[root@test2 hw-9]# yc compute instance delete --name db1
done (1m5s)
[root@test2 hw-9]# yc vpc subnet delete --name otus-subnet
done (2s)
[root@test2 hw-9]# yc vpc network delete --name "otus-net"
```

### **Выводы**
- **Clickhouse однозначно выигрывает в скорости обработки OLAP запросов**
- **Postgres с TimescaleDB может конкурировать с Clickhouse при "узкой селекции по дате"**  
  (в выборке за 1 день)
- **Скорость network-ssd дисков в ЯО вызывает вопросы**  
  в директории ./screen сохранил, для истории скрины с пропускной способностью дисковой подсистемы,  
  т.е. при запросах скорость работы диска не превышала 30MB/sec и 116rps,  
  и изза этого все запросы упирались в дисковую подсистему.

