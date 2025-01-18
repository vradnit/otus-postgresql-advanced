# **HW-12 | Multi master**



## **Цель:**
развернуть multi master кластер PostgreSQL своими руками
развернуть PostgreSQL like географически распределенный сервис от одного из 3-х крупнейших облачных провайдеров - AWS, GCP и Azure



## **Описание/Пошаговая инструкция выполнения домашнего задания:**
1 вариант:
Развернуть CockroachDB в GKE или GCE
Потесировать dataset с чикагскими такси
Или залить 10Гб данных и протестировать скорость запросов в сравнении с 1 инстансом PostgreSQL
Описать что и как делали и с какими проблемами столкнулись

2 вариант:
Переносим тестовую БД 10 Гб в географически распределенный PostgeSQL like сервис
Описать что и как делали и с какими проблемами столкнулись



## **Выполнение ДЗ**
### **Выбранный план**
**Развернем Postgres Citus с ипользованием Patroni**



### **Подготовка ЯО**
**Создаем сетевую инфраструктуру и ВМ**
```
[root@test2 hw-12]# yc vpc network create --name "otus-net" --description "otus-net"

[root@test2 hw-12]# yc vpc subnet create --name otus-subnet --range 10.95.112.0/24 --network-name otus-net --description "otus-subnet"

[root@test2 hw-12]# for i in {1..3}; do yc compute instance create --name coord$i --hostname coord$i --cores 4 --memory 8 --core-fraction 20 --preemptible --create-boot-disk size=25G,type=network-ssd,image-folder-id=standard-images,image-family=almalinux-8 --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async ; done

[root@test2 hw-12]# for i in {1..2}; do yc compute instance create --name work1-$i --hostname work1-$i --cores 4 --memory 8 --core-fraction 20 --preemptible --create-boot-disk size=30G,type=network-ssd,image-folder-id=standard-images,image-family=almalinux-8 --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async ; done

[root@test2 hw-12]# for i in 1; do yc compute instance create --name work2-$i --hostname work2-$i --cores 4 --memory 8 --core-fraction 20 --preemptible --create-boot-disk size=30G,type=network-ssd,image-folder-id=standard-images,image-family=almalinux-8 --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async ; done

[root@test2 hw-12]# for i in 1; do yc compute instance create --name work3-$i --hostname work3-$i --cores 4 --memory 8 --core-fraction 20 --preemptible --create-boot-disk size=30G,type=network-ssd,image-folder-id=standard-images,image-family=almalinux-8 --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async ; done
```
**Проверяем**
```
[root@test2 hw-12]# yc compute instance list
+----------------------+---------+---------------+---------+----------------+--------------+
|          ID          |  NAME   |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP  |
+----------------------+---------+---------------+---------+----------------+--------------+
| fhm3nl2u7k02lhvoo9m6 | coord3  | ru-central1-a | RUNNING | 89.169.151.217 | 10.95.112.14 |
| fhm3vd1velbvc9egfdi0 | work1-1 | ru-central1-a | RUNNING | 89.169.151.239 | 10.95.112.23 |
| fhm50pmocgcq6c81eori | work3-1 | ru-central1-a | RUNNING | 89.169.148.33  | 10.95.112.31 |
| fhm7qu0qr770kv2ebnoj | coord1  | ru-central1-a | RUNNING | 51.250.11.69   | 10.95.112.9  |
| fhmj92hl9vemfnlsnmc5 | work2-1 | ru-central1-a | RUNNING | 51.250.74.95   | 10.95.112.20 |
| fhmk4dtcnbmgpol50de3 | coord2  | ru-central1-a | RUNNING | 51.250.12.38   | 10.95.112.27 |
| fhmse40jnbov2jq9b83o | work1-2 | ru-central1-a | RUNNING | 84.252.130.140 | 10.95.112.17 |
+----------------------+---------+---------------+---------+----------------+--------------+
```
, где
- coord1, coord2, coord3 - ноды координаторы CITUS + ETCD
- work1-1,work1-2 - воркер ноды шарда 1
- work2-1 - воркер нода шарда 2
- work3-1 - воркер нода шарда 3



### **Установка кластера ETCD**
**На всех в /etc/hosts нодах добавляем**
```
# cat /etc/hosts
10.95.112.9 coord1
10.95.112.27 coord2
10.95.112.14 coord3
10.95.112.23 work1-1
10.95.112.17 work1-2
10.95.112.20 work2-1
10.95.112.31 work3-1
```

**На coord1, coord2, coord3 устанавливаем пакет etcd**
```
[yc-user@coord1 ~]$ sudo dnf install -y https://dl.rockylinux.org/vault/centos/8-stream/cloud/x86_64/openstack-victoria/Packages/e/etcd-3.2.21-2.el8.x86_64.rpm
```

**На coord1, coord2, coord3 формируем конфиг etcd**
```
# cat /etc/etcd/etcd.conf

ETCD_NAME="coord1"  # << изменяем имя ноды
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://coord1:2379"  # << изменяем имя ноды
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://coord1:2380"  # << изменяем имя ноды
ETCD_INITIAL_CLUSTER_TOKEN="etcd_claster"
ETCD_INITIAL_CLUSTER="coord1=http://coord1:2380,coord2=http://coord2:2380,coord3=http://coord3:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ENABLE_V2="true"
ETCDCRL_API=2
```
**Запускаем etcd**
```
# systemctl enable etcd
# systemctl start etcd
```

**Проверяем статус кластера etcd**
```
[yc-user@coord1 ~]$ etcdctl member list
914e8caf0cf61032: name=coord3 peerURLs=http://coord3:2380 clientURLs=http://coord3:2379 isLeader=false
97604a37dacd02af: name=coord2 peerURLs=http://coord2:2380 clientURLs=http://coord2:2379 isLeader=false
d451a4dc8e87bcd0: name=coord1 peerURLs=http://coord1:2380 clientURLs=http://coord1:2379 isLeader=true

[yc-user@coord1 ~]$ etcdctl cluster-health
member 914e8caf0cf61032 is healthy: got healthy result from http://coord3:2379
member 97604a37dacd02af is healthy: got healthy result from http://coord2:2379
member d451a4dc8e87bcd0 is healthy: got healthy result from http://coord1:2379
cluster is healthy
```


### **Установка postresql + patroni**
**На все ноды устанавливаем пакеты**
```
rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
dnf config-manager --set-enabled powertools
dnf install -y epel-release

dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql16-server postgresql16-contrib -y citus_16

dnf install -y patroni patroni-etcd
```

**На всех нодах в демон tuned добавляем и активируем профиль postgresql**
```
[root@coord1 yc-user]# mkdir /usr/lib/tuned/postgresql/
[root@coord1 yc-user]# vi /usr/lib/tuned/postgresql/tuned.conf

[root@coord1 yc-user]# cat /usr/lib/tuned/postgresql/tuned.conf
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

[root@coord1 yc-user]# restorecon -RFvv /usr/lib/tuned/postgresql
[root@coord1 yc-user]# tuned-adm list | grep postgre
- postgresql                  - Optimize for PostgreSQL RDBMS
[root@coord1 yc-user]# tuned-adm profile postgresql
[root@coord1 yc-user]# tuned-adm active
Current active profile: postgresql
```


**На всех нодах формируем конфиг для patroni**
```
# cat /etc/patroni/patroni.yml 

scope: patroni
name: coord1
restapi:
  listen: 0.0.0.0:8008
  connect_address: coord1:8008  # << меняем на имя ноды
etcd:
  hosts: coord1:2379,coord2:2379,coord3:2379
citus:
  group: 0                      # << меняем на номер шард группы
  database: otus                # << имя БД с раширением citus
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
  initdb:
  - encoding: UTF8
  - data-checksums
  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: ######
      options:
        - createrole
        - createdb
postgresql:
  listen: 0.0.0.0:5432
  connect_address: coord1:5432  # << меняем на имя ноды
  data_dir: /var/lib/pgsql/16/data/
  bin_dir: /usr/pgsql-16/bin/
  pgpass: /tmp/pgpass0
  authentication:
    replication:
      username: replicator
      password: ######
    superuser:
      username: postgres
      password: ######
    rewind:
      username: rewind_user
      password: ######
  parameters:
    unix_socket_directories: '.'
tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

**Запускаем patroni, сначала на координат-нодах, и только после на остальных нодах**
```
systemctl enable patroni
systemctl start patroni
patronictl -c /etc/patroni/patroni.yml list
```
**Проверка статуса кластера patroni**
```
[root@coord1 yc-user]# patronictl -c /etc/patroni/patroni.yml list
+ Citus cluster: patroni -+----------------+-----------+----+-----------+
| Group | Member | Host   | Role           | State     | TL | Lag in MB |
+-------+--------+--------+----------------+-----------+----+-----------+
|     0 | coord1 | coord1 | Leader         | running   |  3 |           |
|     0 | coord2 | coord2 | Quorum Standby | streaming |  3 |         0 |
|     0 | coord3 | coord3 | Quorum Standby | streaming |  3 |         0 |
+-------+--------+--------+----------------+-----------+----+-----------+
```
**Проверка статуса кластера patroni с запущеннысм воркерами**
```
[root@coord1 yc-user]# patronictl -c /etc/patroni/patroni.yml list
+ Citus cluster: patroni ---+----------------+-----------+----+-----------+
| Group | Member  | Host    | Role           | State     | TL | Lag in MB |
+-------+---------+---------+----------------+-----------+----+-----------+
|     0 | coord1  | coord1  | Leader         | running   |  3 |           |
|     0 | coord2  | coord2  | Quorum Standby | streaming |  3 |         0 |
|     0 | coord3  | coord3  | Quorum Standby | streaming |  3 |         0 |
|     1 | work1-1 | work1-1 | Leader         | running   |  2 |           |
|     1 | work1-2 | work1-2 | Quorum Standby | streaming |  2 |         0 |
|     2 | work2-1 | work2-1 | Leader         | running   |  1 |           |
|     3 | work3-1 | work3-1 | Leader         | running   |  1 |           |
+-------+---------+---------+----------------+-----------+----+-----------+
```
**Видим, что все ок**


**Используя https://www.pgconfig.org и входные параметры:**
```
num_cpu=4
total_mem=8G
max_conn=100
postgres_version=16
storage=ssd
profile=dw
```

**Формируем параметры тюнинга postgresql**  
**Для тюнинга postgresql используем patroni**
```
[yc-user@coord1 ~]$ patronictl -c /etc/patroni/patroni.yml show-config
loop_wait: 10
maximum_lag_on_failover: 1048576
postgresql:
  parameters:
    checkpoint_completion_target: 0.9
    effective_cache_size: 6GB
    effective_io_concurrency: 200
    maintenance_work_mem: 410MB
    max_connections: 100
    max_parallel_workers: 2
    max_parallel_workers_per_gather: 2
    max_wal_size: 3GB
    max_worker_processes: 8
    min_wal_size: 2GB
    random_page_cost: 1.1
    shared_buffers: 2GB
    wal_buffers: -1
    work_mem: 41MB
  use_pg_rewind: true
retry_timeout: 10
synchronous_mode: quorum
ttl: 30
```

**Проверка, что база otus доступна и в ней есть расширение citus**
```
[yc-user@coord1 ~]$ psql -h 127.0.0.1 -U postgres 
psql (16.6)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

postgres=# \c otus
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
You are now connected to database "otus" as user "postgres".
otus=# 
otus=# \dx
                     List of installed extensions
      Name      | Version |   Schema   |         Description          
----------------+---------+------------+------------------------------
 citus          | 12.1-1  | pg_catalog | Citus distributed database
 citus_columnar | 11.3-1  | pg_catalog | Citus Columnar extension
 plpgsql        | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)
```



### **Загрузка датасета Opensky**
**Скачиваем датасет**
```
[yc-user@coord1 ~]$ mkdir csv
[yc-user@coord1 ~]$ cd csv/
[yc-user@coord1 csv]$ wget -O- https://zenodo.org/record/5092942 | grep -oP 'https://zenodo.org/records/5092942/files/flightlist_\d+_\d+\.csv\.gz' | xargs wget

[yc-user@coord1 csv]$ ll
total 4509008
-rw-rw-r--. 1 yc-user yc-user 149656072 Jan 17 22:27 flightlist_20190101_20190131.csv.gz
-rw-rw-r--. 1 yc-user yc-user 139872800 Jan 17 22:24 flightlist_20190201_20190228.csv.gz
-rw-rw-r--. 1 yc-user yc-user 159072441 Jan 17 22:26 flightlist_20190301_20190331.csv.gz
-rw-rw-r--. 1 yc-user yc-user 166006708 Jan 17 22:26 flightlist_20190401_20190430.csv.gz
-rw-rw-r--. 1 yc-user yc-user 177692774 Jan 17 22:24 flightlist_20190501_20190531.csv.gz
-rw-rw-r--. 1 yc-user yc-user 186373210 Jan 17 22:26 flightlist_20190601_20190630.csv.gz
-rw-rw-r--. 1 yc-user yc-user 203480200 Jan 17 22:25 flightlist_20190701_20190731.csv.gz
-rw-rw-r--. 1 yc-user yc-user 210148935 Jan 17 22:25 flightlist_20190801_20190831.csv.gz
-rw-rw-r--. 1 yc-user yc-user 191374713 Jan 17 22:25 flightlist_20190901_20190930.csv.gz
-rw-rw-r--. 1 yc-user yc-user 206917730 Jan 17 22:25 flightlist_20191001_20191031.csv.gz
-rw-rw-r--. 1 yc-user yc-user 190775945 Jan 17 22:25 flightlist_20191101_20191130.csv.gz
-rw-rw-r--. 1 yc-user yc-user 189553155 Jan 17 22:25 flightlist_20191201_20191231.csv.gz
-rw-rw-r--. 1 yc-user yc-user 193891069 Jan 17 22:26 flightlist_20200101_20200131.csv.gz
-rw-rw-r--. 1 yc-user yc-user 186334754 Jan 17 22:26 flightlist_20200201_20200229.csv.gz
-rw-rw-r--. 1 yc-user yc-user 151571888 Jan 17 22:27 flightlist_20200301_20200331.csv.gz
-rw-rw-r--. 1 yc-user yc-user  58544368 Jan 17 22:27 flightlist_20200401_20200430.csv.gz
-rw-rw-r--. 1 yc-user yc-user  75376842 Jan 17 22:26 flightlist_20200501_20200531.csv.gz
-rw-rw-r--. 1 yc-user yc-user 100336756 Jan 17 22:26 flightlist_20200601_20200630.csv.gz
-rw-rw-r--. 1 yc-user yc-user 134445252 Jan 17 22:25 flightlist_20200701_20200731.csv.gz
-rw-rw-r--. 1 yc-user yc-user 144364225 Jan 17 22:25 flightlist_20200801_20200831.csv.gz
-rw-rw-r--. 1 yc-user yc-user 136524682 Jan 17 22:25 flightlist_20200901_20200930.csv.gz
-rw-rw-r--. 1 yc-user yc-user 138560754 Jan 17 22:25 flightlist_20201001_20201031.csv.gz
-rw-rw-r--. 1 yc-user yc-user 126932585 Jan 17 22:24 flightlist_20201101_20201130.csv.gz
-rw-rw-r--. 1 yc-user yc-user 132372973 Jan 17 22:24 flightlist_20201201_20201231.csv.gz
-rw-rw-r--. 1 yc-user yc-user 123902516 Jan 17 22:25 flightlist_20210101_20210131.csv.gz
-rw-rw-r--. 1 yc-user yc-user 112332587 Jan 17 22:25 flightlist_20210201_20210228.csv.gz
-rw-rw-r--. 1 yc-user yc-user 144126125 Jan 17 22:25 flightlist_20210301_20210331.csv.gz
-rw-rw-r--. 1 yc-user yc-user 154290585 Jan 17 22:25 flightlist_20210401_20210430.csv.gz
-rw-rw-r--. 1 yc-user yc-user 158083429 Jan 17 22:25 flightlist_20210501_20210530.csv.gz
-rw-rw-r--. 1 yc-user yc-user 174242634 Jan 17 22:25 flightlist_20210601_20210630.csv.gz
```

**Создаем партицированную таблицу в БД, для дистрибуции используем поле callsign**
```
[yc-user@coord1 csv]$ psql -h 127.0.0.1 -U postgres -d otus
psql (16.6)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

otus=#
```

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
) PARTITION BY RANGE (firstseen);


SELECT create_distributed_table('opensky', 'callsign');

SELECT create_time_partitions(
  table_name         := 'opensky',
  partition_interval := '1 month',
  start_from         := '2018-12-01 00:00:00',
  end_at             := '2021-12-31 23:59:59'
);
```

**Проверяем, что таблица создалась**
```
otus=# \dt
                    List of relations
 Schema |       Name       |       Type        |  Owner   
--------+------------------+-------------------+----------
 public | opensky          | partitioned table | postgres
 public | opensky_p2018_12 | table             | postgres
 public | opensky_p2019_01 | table             | postgres
 public | opensky_p2019_02 | table             | postgres
 public | opensky_p2019_03 | table             | postgres
 public | opensky_p2019_04 | table             | postgres
 public | opensky_p2019_05 | table             | postgres
 public | opensky_p2019_06 | table             | postgres
 public | opensky_p2019_07 | table             | postgres
 public | opensky_p2019_08 | table             | postgres
 public | opensky_p2019_09 | table             | postgres
 public | opensky_p2019_10 | table             | postgres
 public | opensky_p2019_11 | table             | postgres
 public | opensky_p2019_12 | table             | postgres
 public | opensky_p2020_01 | table             | postgres
 public | opensky_p2020_02 | table             | postgres
 public | opensky_p2020_03 | table             | postgres
 public | opensky_p2020_04 | table             | postgres
 public | opensky_p2020_05 | table             | postgres
 public | opensky_p2020_06 | table             | postgres
 public | opensky_p2020_07 | table             | postgres
 public | opensky_p2020_08 | table             | postgres
 public | opensky_p2020_09 | table             | postgres
 public | opensky_p2020_10 | table             | postgres
 public | opensky_p2020_11 | table             | postgres
 public | opensky_p2020_12 | table             | postgres
 public | opensky_p2021_01 | table             | postgres
 public | opensky_p2021_02 | table             | postgres
 public | opensky_p2021_03 | table             | postgres
 public | opensky_p2021_04 | table             | postgres
 public | opensky_p2021_05 | table             | postgres
 public | opensky_p2021_06 | table             | postgres
 public | opensky_p2021_07 | table             | postgres
 public | opensky_p2021_08 | table             | postgres
 public | opensky_p2021_09 | table             | postgres
 public | opensky_p2021_10 | table             | postgres
 public | opensky_p2021_11 | table             | postgres
 public | opensky_p2021_12 | table             | postgres
(38 rows)
```

**Загружаем датасет в таблицу**
```
[root@coord1 csv]# date; for ii in flightlist_2019* flightlist_2020* flightlist_2021* ; do echo ${ii} ; zcat ${ii} | psql -h 127.0.0.1 -U postgres -d otus -c "COPY opensky from stdin with delimiter ',' CSV HEADER" ; done ; date
Fri Jan 17 22:59:13 UTC 2025
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
Fri Jan 17 23:20:48 UTC 2025
```
**Время загрузки датасета составило 24 минуты**  


**Проверяем распределение загузки по партициям**
```
otus=# SELECT table_name, table_size FROM citus_tables;
    table_name    | table_size
------------------+------------
 opensky          | 0 bytes
 opensky_p2018_12 | 1792 kB
 opensky_p2019_01 | 345 MB
 opensky_p2019_02 | 324 MB
 opensky_p2019_03 | 367 MB
 opensky_p2019_04 | 382 MB
 opensky_p2019_05 | 408 MB
 opensky_p2019_06 | 427 MB
 opensky_p2019_07 | 465 MB
 opensky_p2019_08 | 478 MB
 opensky_p2019_09 | 436 MB
 opensky_p2019_10 | 472 MB
 opensky_p2019_11 | 437 MB
 opensky_p2019_12 | 434 MB
 opensky_p2020_01 | 444 MB
 opensky_p2020_02 | 427 MB
 opensky_p2020_03 | 350 MB
 opensky_p2020_04 | 136 MB
 opensky_p2020_05 | 177 MB
 opensky_p2020_06 | 235 MB
 opensky_p2020_07 | 312 MB
 opensky_p2020_08 | 335 MB
 opensky_p2020_09 | 317 MB
 opensky_p2020_10 | 321 MB
 opensky_p2020_11 | 295 MB
 opensky_p2020_12 | 305 MB
 opensky_p2021_01 | 288 MB
 opensky_p2021_02 | 261 MB
 opensky_p2021_03 | 335 MB
 opensky_p2021_04 | 358 MB
 opensky_p2021_05 | 365 MB
 opensky_p2021_06 | 405 MB
 opensky_p2021_07 | 256 kB
 opensky_p2021_08 | 256 kB
 opensky_p2021_09 | 256 kB
 opensky_p2021_10 | 256 kB
 opensky_p2021_11 | 256 kB
 opensky_p2021_12 | 256 kB
(38 rows)
```
**Также проверяем тип таблиц**
```
otus=# SELECT partition, access_method FROM time_partitions  WHERE parent_table = 'opensky'::regclass;
    partition     | access_method
------------------+---------------
 opensky_p2018_12 | heap
 opensky_p2019_01 | heap
 opensky_p2019_02 | heap
 opensky_p2019_03 | heap
 opensky_p2019_04 | heap
 opensky_p2019_05 | heap
 opensky_p2019_06 | heap
 opensky_p2019_07 | heap
 opensky_p2019_08 | heap
 opensky_p2019_09 | heap
 opensky_p2019_10 | heap
 opensky_p2019_11 | heap
 opensky_p2019_12 | heap
 opensky_p2020_01 | heap
 opensky_p2020_02 | heap
 opensky_p2020_03 | heap
 opensky_p2020_04 | heap
 opensky_p2020_05 | heap
 opensky_p2020_06 | heap
 opensky_p2020_07 | heap
 opensky_p2020_08 | heap
 opensky_p2020_09 | heap
 opensky_p2020_10 | heap
 opensky_p2020_11 | heap
 opensky_p2020_12 | heap
 opensky_p2021_01 | heap
 opensky_p2021_02 | heap
 opensky_p2021_03 | heap
 opensky_p2021_04 | heap
 opensky_p2021_05 | heap
 opensky_p2021_06 | heap
 opensky_p2021_07 | heap
 opensky_p2021_08 | heap
 opensky_p2021_09 | heap
 opensky_p2021_10 | heap
 opensky_p2021_11 | heap
 opensky_p2021_12 | heap
````
, т.е. на тек. момент он **heap**




### **Запускаем аналитические запросы в postgresql+citus [тип таблицы heap]**
- **Общее кол-во полетов**
```
otus=# \timing
Timing is on.
otus=# select count(*) from opensky ;
  count   
----------
 66010819
(1 row)

Time: 3883.813 ms (00:03.884)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов**
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

Time: 8688.524 ms (00:08.689)
```
- **Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')"** 
``` 
otus=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 800.654 ms
```


### **Поменяем тип таблиц с heap на columnar**
```
otus=# CALL alter_old_partitions_set_access_method('opensky','2021-12-01 00:00:00', 'columnar' );
NOTICE:  converting opensky_p2018_12 with start time 2018-12-01 00:00:00+00 and end time 2019-01-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2018_12
NOTICE:  moving the data of public.opensky_p2018_12
NOTICE:  dropping the old public.opensky_p2018_12
NOTICE:  renaming the new table to public.opensky_p2018_12
NOTICE:  converting opensky_p2019_01 with start time 2019-01-01 00:00:00+00 and end time 2019-02-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_01
NOTICE:  moving the data of public.opensky_p2019_01
NOTICE:  dropping the old public.opensky_p2019_01
NOTICE:  renaming the new table to public.opensky_p2019_01
NOTICE:  converting opensky_p2019_02 with start time 2019-02-01 00:00:00+00 and end time 2019-03-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_02
NOTICE:  moving the data of public.opensky_p2019_02
NOTICE:  dropping the old public.opensky_p2019_02
NOTICE:  renaming the new table to public.opensky_p2019_02
NOTICE:  converting opensky_p2019_03 with start time 2019-03-01 00:00:00+00 and end time 2019-04-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_03
NOTICE:  moving the data of public.opensky_p2019_03
NOTICE:  dropping the old public.opensky_p2019_03
NOTICE:  renaming the new table to public.opensky_p2019_03
NOTICE:  converting opensky_p2019_04 with start time 2019-04-01 00:00:00+00 and end time 2019-05-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_04
NOTICE:  moving the data of public.opensky_p2019_04
NOTICE:  dropping the old public.opensky_p2019_04
NOTICE:  renaming the new table to public.opensky_p2019_04
NOTICE:  converting opensky_p2019_05 with start time 2019-05-01 00:00:00+00 and end time 2019-06-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_05
NOTICE:  moving the data of public.opensky_p2019_05
NOTICE:  dropping the old public.opensky_p2019_05
NOTICE:  renaming the new table to public.opensky_p2019_05
NOTICE:  converting opensky_p2019_06 with start time 2019-06-01 00:00:00+00 and end time 2019-07-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_06
NOTICE:  moving the data of public.opensky_p2019_06
NOTICE:  dropping the old public.opensky_p2019_06
NOTICE:  renaming the new table to public.opensky_p2019_06
NOTICE:  converting opensky_p2019_07 with start time 2019-07-01 00:00:00+00 and end time 2019-08-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_07
NOTICE:  moving the data of public.opensky_p2019_07
NOTICE:  dropping the old public.opensky_p2019_07
NOTICE:  renaming the new table to public.opensky_p2019_07
NOTICE:  converting opensky_p2019_08 with start time 2019-08-01 00:00:00+00 and end time 2019-09-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_08
NOTICE:  moving the data of public.opensky_p2019_08
NOTICE:  dropping the old public.opensky_p2019_08
NOTICE:  renaming the new table to public.opensky_p2019_08
NOTICE:  converting opensky_p2019_09 with start time 2019-09-01 00:00:00+00 and end time 2019-10-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_09
NOTICE:  moving the data of public.opensky_p2019_09
NOTICE:  dropping the old public.opensky_p2019_09
NOTICE:  renaming the new table to public.opensky_p2019_09
NOTICE:  converting opensky_p2019_10 with start time 2019-10-01 00:00:00+00 and end time 2019-11-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_10
NOTICE:  moving the data of public.opensky_p2019_10
NOTICE:  dropping the old public.opensky_p2019_10
NOTICE:  renaming the new table to public.opensky_p2019_10
NOTICE:  converting opensky_p2019_11 with start time 2019-11-01 00:00:00+00 and end time 2019-12-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_11
NOTICE:  moving the data of public.opensky_p2019_11
NOTICE:  dropping the old public.opensky_p2019_11
NOTICE:  renaming the new table to public.opensky_p2019_11
NOTICE:  converting opensky_p2019_12 with start time 2019-12-01 00:00:00+00 and end time 2020-01-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2019_12
NOTICE:  moving the data of public.opensky_p2019_12
NOTICE:  dropping the old public.opensky_p2019_12
NOTICE:  renaming the new table to public.opensky_p2019_12
NOTICE:  converting opensky_p2020_01 with start time 2020-01-01 00:00:00+00 and end time 2020-02-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_01
NOTICE:  moving the data of public.opensky_p2020_01
NOTICE:  dropping the old public.opensky_p2020_01
NOTICE:  renaming the new table to public.opensky_p2020_01
NOTICE:  converting opensky_p2020_02 with start time 2020-02-01 00:00:00+00 and end time 2020-03-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_02
NOTICE:  moving the data of public.opensky_p2020_02
NOTICE:  dropping the old public.opensky_p2020_02
NOTICE:  renaming the new table to public.opensky_p2020_02
NOTICE:  converting opensky_p2020_03 with start time 2020-03-01 00:00:00+00 and end time 2020-04-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_03
NOTICE:  moving the data of public.opensky_p2020_03
NOTICE:  dropping the old public.opensky_p2020_03
NOTICE:  renaming the new table to public.opensky_p2020_03
NOTICE:  converting opensky_p2020_04 with start time 2020-04-01 00:00:00+00 and end time 2020-05-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_04
NOTICE:  moving the data of public.opensky_p2020_04
NOTICE:  dropping the old public.opensky_p2020_04
NOTICE:  renaming the new table to public.opensky_p2020_04
NOTICE:  converting opensky_p2020_05 with start time 2020-05-01 00:00:00+00 and end time 2020-06-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_05
NOTICE:  moving the data of public.opensky_p2020_05
NOTICE:  dropping the old public.opensky_p2020_05
NOTICE:  renaming the new table to public.opensky_p2020_05
NOTICE:  converting opensky_p2020_06 with start time 2020-06-01 00:00:00+00 and end time 2020-07-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_06
NOTICE:  moving the data of public.opensky_p2020_06
NOTICE:  dropping the old public.opensky_p2020_06
NOTICE:  renaming the new table to public.opensky_p2020_06
NOTICE:  converting opensky_p2020_07 with start time 2020-07-01 00:00:00+00 and end time 2020-08-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_07
NOTICE:  moving the data of public.opensky_p2020_07
NOTICE:  dropping the old public.opensky_p2020_07
NOTICE:  renaming the new table to public.opensky_p2020_07
NOTICE:  converting opensky_p2020_08 with start time 2020-08-01 00:00:00+00 and end time 2020-09-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_08
NOTICE:  moving the data of public.opensky_p2020_08
NOTICE:  dropping the old public.opensky_p2020_08
NOTICE:  renaming the new table to public.opensky_p2020_08
NOTICE:  converting opensky_p2020_09 with start time 2020-09-01 00:00:00+00 and end time 2020-10-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_09
NOTICE:  moving the data of public.opensky_p2020_09
NOTICE:  dropping the old public.opensky_p2020_09
NOTICE:  renaming the new table to public.opensky_p2020_09
NOTICE:  converting opensky_p2020_10 with start time 2020-10-01 00:00:00+00 and end time 2020-11-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_10
NOTICE:  moving the data of public.opensky_p2020_10
NOTICE:  dropping the old public.opensky_p2020_10
NOTICE:  renaming the new table to public.opensky_p2020_10
NOTICE:  converting opensky_p2020_11 with start time 2020-11-01 00:00:00+00 and end time 2020-12-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_11
NOTICE:  moving the data of public.opensky_p2020_11
NOTICE:  dropping the old public.opensky_p2020_11
NOTICE:  renaming the new table to public.opensky_p2020_11
NOTICE:  converting opensky_p2020_12 with start time 2020-12-01 00:00:00+00 and end time 2021-01-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2020_12
NOTICE:  moving the data of public.opensky_p2020_12
NOTICE:  dropping the old public.opensky_p2020_12
NOTICE:  renaming the new table to public.opensky_p2020_12
NOTICE:  converting opensky_p2021_01 with start time 2021-01-01 00:00:00+00 and end time 2021-02-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_01
NOTICE:  moving the data of public.opensky_p2021_01
NOTICE:  dropping the old public.opensky_p2021_01
NOTICE:  renaming the new table to public.opensky_p2021_01
NOTICE:  converting opensky_p2021_02 with start time 2021-02-01 00:00:00+00 and end time 2021-03-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_02
NOTICE:  moving the data of public.opensky_p2021_02
NOTICE:  dropping the old public.opensky_p2021_02
NOTICE:  renaming the new table to public.opensky_p2021_02
NOTICE:  converting opensky_p2021_03 with start time 2021-03-01 00:00:00+00 and end time 2021-04-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_03
NOTICE:  moving the data of public.opensky_p2021_03
NOTICE:  dropping the old public.opensky_p2021_03
NOTICE:  renaming the new table to public.opensky_p2021_03
NOTICE:  converting opensky_p2021_04 with start time 2021-04-01 00:00:00+00 and end time 2021-05-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_04
NOTICE:  moving the data of public.opensky_p2021_04
NOTICE:  dropping the old public.opensky_p2021_04
NOTICE:  renaming the new table to public.opensky_p2021_04
NOTICE:  converting opensky_p2021_05 with start time 2021-05-01 00:00:00+00 and end time 2021-06-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_05
NOTICE:  moving the data of public.opensky_p2021_05
NOTICE:  dropping the old public.opensky_p2021_05
NOTICE:  renaming the new table to public.opensky_p2021_05
NOTICE:  converting opensky_p2021_06 with start time 2021-06-01 00:00:00+00 and end time 2021-07-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_06
NOTICE:  moving the data of public.opensky_p2021_06
NOTICE:  dropping the old public.opensky_p2021_06
NOTICE:  renaming the new table to public.opensky_p2021_06
NOTICE:  converting opensky_p2021_07 with start time 2021-07-01 00:00:00+00 and end time 2021-08-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_07
NOTICE:  moving the data of public.opensky_p2021_07
NOTICE:  dropping the old public.opensky_p2021_07
NOTICE:  renaming the new table to public.opensky_p2021_07
NOTICE:  converting opensky_p2021_08 with start time 2021-08-01 00:00:00+00 and end time 2021-09-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_08
NOTICE:  moving the data of public.opensky_p2021_08
NOTICE:  dropping the old public.opensky_p2021_08
NOTICE:  renaming the new table to public.opensky_p2021_08
NOTICE:  converting opensky_p2021_09 with start time 2021-09-01 00:00:00+00 and end time 2021-10-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_09
NOTICE:  moving the data of public.opensky_p2021_09
NOTICE:  dropping the old public.opensky_p2021_09
NOTICE:  renaming the new table to public.opensky_p2021_09
NOTICE:  converting opensky_p2021_10 with start time 2021-10-01 00:00:00+00 and end time 2021-11-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_10
NOTICE:  moving the data of public.opensky_p2021_10
NOTICE:  dropping the old public.opensky_p2021_10
NOTICE:  renaming the new table to public.opensky_p2021_10
NOTICE:  converting opensky_p2021_11 with start time 2021-11-01 00:00:00+00 and end time 2021-12-01 00:00:00+00
NOTICE:  creating a new table for public.opensky_p2021_11
NOTICE:  moving the data of public.opensky_p2021_11
NOTICE:  dropping the old public.opensky_p2021_11
NOTICE:  renaming the new table to public.opensky_p2021_11
CALL
Time: 401068.339 ms (06:41.068)
```
**После конвертации запустим vacuum analyze**
```
otus=# VACUUM ANALYZE opensky;
VACUUM
```
**Проверяем, что тип таблицы изменился**
```
otus=# SELECT partition, access_method FROM time_partitions  WHERE parent_table = 'opensky'::regclass; 
    partition     | access_method 
------------------+---------------
 opensky_p2018_12 | columnar
 opensky_p2019_01 | columnar
 opensky_p2019_02 | columnar
 opensky_p2019_03 | columnar
 opensky_p2019_04 | columnar
 opensky_p2019_05 | columnar
 opensky_p2019_06 | columnar
 opensky_p2019_07 | columnar
 opensky_p2019_08 | columnar
 opensky_p2019_09 | columnar
 opensky_p2019_10 | columnar
 opensky_p2019_11 | columnar
 opensky_p2019_12 | columnar
 opensky_p2020_01 | columnar
 opensky_p2020_02 | columnar
 opensky_p2020_03 | columnar
 opensky_p2020_04 | columnar
 opensky_p2020_05 | columnar
 opensky_p2020_06 | columnar
 opensky_p2020_07 | columnar
 opensky_p2020_08 | columnar
 opensky_p2020_09 | columnar
 opensky_p2020_10 | columnar
 opensky_p2020_11 | columnar
 opensky_p2020_12 | columnar
 opensky_p2021_01 | columnar
 opensky_p2021_02 | columnar
 opensky_p2021_03 | columnar
 opensky_p2021_04 | columnar
 opensky_p2021_05 | columnar
 opensky_p2021_06 | columnar
 opensky_p2021_07 | columnar
 opensky_p2021_08 | columnar
 opensky_p2021_09 | columnar
 opensky_p2021_10 | columnar
 opensky_p2021_11 | columnar
 opensky_p2021_12 | heap
(37 rows)

Time: 3.134 ms
```


### **Запускаем аналитические запросы в postgresql+citus [тип таблицы columnar]**
- **Общее кол-во полетов**
```
otus=# select count(*) from opensky ;
  count   
----------
 66010819
(1 row)

Time: 860.724 ms
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов** 
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

Time: 2831.051 ms (00:02.831)
```
- **Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')"**
```
otus=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 511.946 ms
```

### **Запустим тесты pgbench**
```
[root@coord1 csv]# /usr/pgsql-16/bin/pgbench -h 127.0.0.1 -U postgres -i otus
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.02 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.47 s (drop tables 0.01 s, create tables 0.01 s, client-side generate 0.17 s, vacuum 0.13 s, primary keys 0.14 s).


[root@coord1 csv]# /usr/pgsql-16/bin/psql -h 127.0.0.1 -U postgres -d otus -c "SELECT create_distributed_table('pgbench_history', 'aid');"
 create_distributed_table 
--------------------------
 
(1 row)

[root@coord2 yc-user]# /usr/pgsql-16/bin/pgbench -h 127.0.0.1 -U postgres -c 50 -j 4 -r -T 120 otus
pgbench (16.6)
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 4
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 8654
number of failed transactions: 0 (0.000%)
latency average = 698.678 ms
initial connection time = 104.857 ms
tps = 71.563755 (without initial connection time)
statement latencies in milliseconds and failures:
         0.002           0  \set aid random(1, 100000 * :scale)
         0.001           0  \set bid random(1, 1 * :scale)
         0.001           0  \set tid random(1, 10 * :scale)
         0.001           0  \set delta random(-5000, 5000)
         0.165           0  BEGIN;
         0.723           0  UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
         0.189           0  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
       565.232           0  UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
       116.038           0  UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
         1.603           0  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
        12.326           0  END;
```
**на этом тестирование postrges + citus закончим**  

**Для сравнения postrges + citus с одним инстансом postgres установим его на ноде work1-1**



### **Установка инстансом PostgreSQL**

**Удаляем директорию с данными и инициалицируем кластер PostgreSQL (на одной ноде)**
```
[root@work1-1 yc-user]# rm -rf /var/lib/pgsql/16/*
[root@work1-1 yc-user]# /usr/pgsql-16/bin/postgresql-16-setup initdb
Initializing database ... OK

[root@work1-1 yc-user]#  systemctl enable postgresql-16
Created symlink /etc/systemd/system/multi-user.target.wants/postgresql-16.service → /usr/lib/systemd/system/postgresql-16.service.
[root@work1-1 yc-user]# systemctl start postgresql-16
[root@work1-1 yc-user]# systemctl status postgresql-16
● postgresql-16.service - PostgreSQL 16 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2025-01-18 11:01:38 UTC; 6s ago
     Docs: https://www.postgresql.org/docs/16/static/
  Process: 2246 ExecStartPre=/usr/pgsql-16/bin/postgresql-16-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)
 Main PID: 2252 (postgres)
    Tasks: 7 (limit: 48754)
   Memory: 17.7M
   CGroup: /system.slice/postgresql-16.service
           ├─2252 /usr/pgsql-16/bin/postgres -D /var/lib/pgsql/16/data/
           ├─2253 postgres: logger 
           ├─2254 postgres: checkpointer 
           ├─2255 postgres: background writer 
           ├─2257 postgres: walwriter 
           ├─2258 postgres: autovacuum launcher 
           └─2259 postgres: logical replication launcher 

Jan 18 11:01:37 work1-1.ru-central1.internal systemd[1]: Starting PostgreSQL 16 database server...
Jan 18 11:01:37 work1-1.ru-central1.internal postgres[2252]: 2025-01-18 11:01:37.987 UTC [2252] LOG:  redirecting log output to logging collector process
Jan 18 11:01:37 work1-1.ru-central1.internal postgres[2252]: 2025-01-18 11:01:37.987 UTC [2252] HINT:  Future log output will appear in directory "log".
Jan 18 11:01:38 work1-1.ru-central1.internal systemd[1]: Started PostgreSQL 16 database server.
```

**Создаем базу данных и партицированную таблицу для загрузки датасета**
```
[postgres@work1-1 ~]$ psql 
psql (16.6)
Type "help" for help.

postgres=# CREATE DATABASE opensky;                         
CREATE DATABASE
postgres=# 
postgres=# \c opensky 
You are now connected to database "opensky" as user "postgres".
opensky=# 
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
) PARTITION BY RANGE (firstseen);
CREATE TABLE
opensky=# 
opensky=# CREATE TABLE opensky_2018_12 PARTITION OF opensky FOR VALUES FROM ('2018-12-01 00:00:00') TO ('2019-01-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_01 PARTITION OF opensky FOR VALUES FROM ('2019-01-01 00:00:00') TO ('2019-02-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_02 PARTITION OF opensky FOR VALUES FROM ('2019-02-01 00:00:00') TO ('2019-03-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_03 PARTITION OF opensky FOR VALUES FROM ('2019-03-01 00:00:00') TO ('2019-04-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_04 PARTITION OF opensky FOR VALUES FROM ('2019-04-01 00:00:00') TO ('2019-05-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_05 PARTITION OF opensky FOR VALUES FROM ('2019-05-01 00:00:00') TO ('2019-06-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_06 PARTITION OF opensky FOR VALUES FROM ('2019-06-01 00:00:00') TO ('2019-07-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_07 PARTITION OF opensky FOR VALUES FROM ('2019-07-01 00:00:00') TO ('2019-08-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_08 PARTITION OF opensky FOR VALUES FROM ('2019-08-01 00:00:00') TO ('2019-09-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_09 PARTITION OF opensky FOR VALUES FROM ('2019-09-01 00:00:00') TO ('2019-10-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_10 PARTITION OF opensky FOR VALUES FROM ('2019-10-01 00:00:00') TO ('2019-11-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_11 PARTITION OF opensky FOR VALUES FROM ('2019-11-01 00:00:00') TO ('2019-12-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2019_12 PARTITION OF opensky FOR VALUES FROM ('2019-12-01 00:00:00') TO ('2020-01-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_01 PARTITION OF opensky FOR VALUES FROM ('2020-01-01 00:00:00') TO ('2020-02-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_02 PARTITION OF opensky FOR VALUES FROM ('2020-02-01 00:00:00') TO ('2020-03-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_03 PARTITION OF opensky FOR VALUES FROM ('2020-03-01 00:00:00') TO ('2020-04-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_04 PARTITION OF opensky FOR VALUES FROM ('2020-04-01 00:00:00') TO ('2020-05-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_05 PARTITION OF opensky FOR VALUES FROM ('2020-05-01 00:00:00') TO ('2020-06-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_06 PARTITION OF opensky FOR VALUES FROM ('2020-06-01 00:00:00') TO ('2020-07-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_07 PARTITION OF opensky FOR VALUES FROM ('2020-07-01 00:00:00') TO ('2020-08-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_08 PARTITION OF opensky FOR VALUES FROM ('2020-08-01 00:00:00') TO ('2020-09-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_09 PARTITION OF opensky FOR VALUES FROM ('2020-09-01 00:00:00') TO ('2020-10-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_10 PARTITION OF opensky FOR VALUES FROM ('2020-10-01 00:00:00') TO ('2020-11-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_11 PARTITION OF opensky FOR VALUES FROM ('2020-11-01 00:00:00') TO ('2020-12-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2020_12 PARTITION OF opensky FOR VALUES FROM ('2020-12-01 00:00:00') TO ('2021-01-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_01 PARTITION OF opensky FOR VALUES FROM ('2021-01-01 00:00:00') TO ('2021-02-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_02 PARTITION OF opensky FOR VALUES FROM ('2021-02-01 00:00:00') TO ('2021-03-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_03 PARTITION OF opensky FOR VALUES FROM ('2021-03-01 00:00:00') TO ('2021-04-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_04 PARTITION OF opensky FOR VALUES FROM ('2021-04-01 00:00:00') TO ('2021-05-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_05 PARTITION OF opensky FOR VALUES FROM ('2021-05-01 00:00:00') TO ('2021-06-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_06 PARTITION OF opensky FOR VALUES FROM ('2021-06-01 00:00:00') TO ('2021-07-01 00:00:00');
CREATE TABLE
opensky=# CREATE TABLE opensky_2021_07 PARTITION OF opensky FOR VALUES FROM ('2021-07-01 00:00:00') TO ('2021-08-01 00:00:00');
CREATE TABLE
```
**Проверяем, что таблица создалась**
```
opensky=# \dt
                    List of relations
 Schema |      Name       |       Type        |  Owner   
--------+-----------------+-------------------+----------
 public | opensky         | partitioned table | postgres
 public | opensky_2018_12 | table             | postgres
 public | opensky_2019_01 | table             | postgres
 public | opensky_2019_02 | table             | postgres
 public | opensky_2019_03 | table             | postgres
 public | opensky_2019_04 | table             | postgres
 public | opensky_2019_05 | table             | postgres
 public | opensky_2019_06 | table             | postgres
 public | opensky_2019_07 | table             | postgres
 public | opensky_2019_08 | table             | postgres
 public | opensky_2019_09 | table             | postgres
 public | opensky_2019_10 | table             | postgres
 public | opensky_2019_11 | table             | postgres
 public | opensky_2019_12 | table             | postgres
 public | opensky_2020_01 | table             | postgres
 public | opensky_2020_02 | table             | postgres
 public | opensky_2020_03 | table             | postgres
 public | opensky_2020_04 | table             | postgres
 public | opensky_2020_05 | table             | postgres
 public | opensky_2020_06 | table             | postgres
 public | opensky_2020_07 | table             | postgres
 public | opensky_2020_08 | table             | postgres
 public | opensky_2020_09 | table             | postgres
 public | opensky_2020_10 | table             | postgres
 public | opensky_2020_11 | table             | postgres
 public | opensky_2020_12 | table             | postgres
 public | opensky_2021_01 | table             | postgres
 public | opensky_2021_02 | table             | postgres
 public | opensky_2021_03 | table             | postgres
 public | opensky_2021_04 | table             | postgres
 public | opensky_2021_05 | table             | postgres
 public | opensky_2021_06 | table             | postgres
 public | opensky_2021_07 | table             | postgres
(33 rows)
```

**Используя ранее загруженный датасет, загружаем его в таблицу**
```
[postgres@work1-1 csv]$ date; for ii in flightlist_2019* flightlist_2020* flightlist_2021* ; do echo ${ii} ; zcat ${ii} | psql -d opensky -c "COPY opensky from stdin with delimiter ',' CSV HEADER" ; done ; date
Sat Jan 18 12:27:13 UTC 2025
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
Sat Jan 18 13:06:10 UTC 2025
```
**Время загрузки датасета составило 39 минут**


**Проверяем размер загруженного датасета**
```
opensky=# select pg_size_pretty(pg_database_size('opensky'));
 pg_size_pretty 
----------------
 10 GB
(1 row)

Time: 1.453 ms
```
**Также проверяем распределение датасета по партициям**
```
opensky=# select schemaname as table_schema, 
opensky-#        relname as table_name,
opensky-#        pg_size_pretty(pg_relation_size(relid)) as data_size
opensky-# from pg_catalog.pg_statio_user_tables
opensky-# order by pg_relation_size(relid) desc;
 table_schema |   table_name    | data_size
--------------+-----------------+-----------
 public       | opensky_2019_08 | 471 MB
 public       | opensky_2019_10 | 464 MB
 public       | opensky_2019_07 | 456 MB
 public       | opensky_2020_01 | 436 MB
 public       | opensky_2019_11 | 429 MB
 public       | opensky_2019_09 | 429 MB
 public       | opensky_2019_12 | 426 MB
 public       | opensky_2019_06 | 419 MB
 public       | opensky_2020_02 | 418 MB
 public       | opensky_2019_05 | 400 MB
 public       | opensky_2021_06 | 396 MB
 public       | opensky_2019_04 | 374 MB
 public       | opensky_2019_03 | 359 MB
 public       | opensky_2021_05 | 357 MB
 public       | opensky_2021_04 | 349 MB
 public       | opensky_2020_03 | 340 MB
 public       | opensky_2019_01 | 337 MB
 public       | opensky_2021_03 | 326 MB
 public       | opensky_2020_08 | 325 MB
 public       | opensky_2019_02 | 316 MB
 public       | opensky_2020_10 | 311 MB
 public       | opensky_2020_09 | 307 MB
 public       | opensky_2020_07 | 303 MB
 public       | opensky_2020_12 | 297 MB
 public       | opensky_2020_11 | 286 MB
 public       | opensky_2021_01 | 281 MB
 public       | opensky_2021_02 | 254 MB
 public       | opensky_2020_06 | 226 MB
 public       | opensky_2020_05 | 171 MB
 public       | opensky_2020_04 | 133 MB
 public       | opensky_2018_12 | 672 kB
 public       | opensky_2021_07 | 0 bytes
(32 rows)

Time: 50.872 ms
```


### **Запускаем аналитические запросы в postgresql [одна нода]**
- **Общее кол-во полетов**
```
opensky=# SELECT COUNT(*) FROM opensky;
  count   
----------
 66010819
(1 row)

Time: 644757.556 ms (10:44.758)
```
- **ТОП 10 аэропортов с максимальным кол-вом полетов**
```
opensky=# SELECT origin, COUNT(*) AS c FROM opensky WHERE origin != '' GROUP BY origin ORDER BY c DESC limit 10;
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

Time: 667764.937 ms (11:07.765)
```
- **Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')"**
```
opensky=# SELECT COUNT(*) FROM opensky WHERE callsign IN ('UUEE', 'UUDD', 'UUWW');
 count 
-------
    14
(1 row)

Time: 667330.219 ms (11:07.330)
```


### **Тестирование pgbench PostgreSQL [одна нода]**
```
[postgres@work1-1 ~]$ /usr/pgsql-16/bin/pgbench -i opensky
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.01 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.78 s (drop tables 0.00 s, create tables 0.03 s, client-side generate 0.36 s, vacuum 0.07 s, primary keys 0.32 s).


[postgres@work1-1 ~]$ /usr/pgsql-16/bin/pgbench -c 50 -j 4 -r -T 120 opensky
pgbench (16.6)
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 4
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 92897
number of failed transactions: 0 (0.000%)
latency average = 64.601 ms
initial connection time = 50.664 ms
tps = 773.985283 (without initial connection time)
statement latencies in milliseconds and failures:
         0.002           0  \set aid random(1, 100000 * :scale)
         0.001           0  \set bid random(1, 1 * :scale)
         0.001           0  \set tid random(1, 10 * :scale)
         0.001           0  \set delta random(-5000, 5000)
         0.082           0  BEGIN;
         0.206           0  UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
         0.110           0  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
        52.786           0  UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
        10.120           0  UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
         0.137           0  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
         1.134           0  END;
```



## **Сравнение результатов**
Результаты тестирования сведены в таблицу:
| **BENCH**                                    |**Postgres**|**Postgres_Citus**|
|-----------------------------------------------------------|------------------|
| number of transactions actually processed    | 92897      |  8654            |
| latency average                              | 64.601 ms  |  698.678 ms      |
| initial connection time                      | 50.664 ms  |  104.857 ms      |
| tps (without initial connection time)        | 774        |  72              |


| Аналитические запросы                                 |**Postgres**|**Postgres_Citus [heap]**|**Postgres_Citus [column]**|
|-------------------------------------------------------|------------|-------------------------|---------------------------|
| Общее кол-во полетов                                  | 644757 ms  | 3884 ms                 | 860.724 ms                |
| Кол-во полетов "callsign IN ('UUEE', 'UUDD', 'UUWW')" | 667330 ms  | 800 ms                  | 511.946 ms                |         
| ТОП 10 аэропортов с максимальным кол-вом полетов      | 667765 ms  | 8688 ms                 | 2831 ms                   |
| Скорость загрузки датасета                            | 39 минут   |                     24 минуты                       |


**Выводы:**
- Скорость загрузки датасета в Postgres+Citus примерно в 1.5 раза быстрее чем в standalone Postgres
- Standalone Postgres примерно в 10 раз выигрывает у Postgres+Citus при OLTP нагрузке  
  это было ожидаемо, т.к. у Postgres нет необходимости планировать запросы на ноды распределенного кластер
- При тестировании OLAP нагрузки Postgres+Citus значительно выигрывает у standalone Postgres
- Если сравнивать скорость выполнения OLAP запросов Postgres+Citus между типами таблиц, то **columnar** выигрывает у **heap**,  
  это тоже было ожидаемо    
