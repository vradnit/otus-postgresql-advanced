# **HW-8 | Тюнинг Постгреса**


## **Цель:**
Развернуть инстанс Постгреса в ВМ в ЯО
Оптимизировать настройки


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Развернуть Постгрес на ВМ
Протестировать pg_bench
Выставить оптимальные настройки
Проверить насколько выросла производительность
Настроить кластер на оптимальную производительность не обращая внимания на стабильность БД
ДЗ сдаем в виде миниотчета в markdown и гите


## **Выполнение ДЗ**

### **Создаем VM**
**Создаем сетевые ресурсы**
```
[root@test2 hw-8]# yc vpc network create --name "otus-net" --description "otus-net"
id: enp7vepl760r9qrp4ti2
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-13T11:08:58Z"
name: otus-net
description: otus-net
default_security_group_id: enpmksgg1vmkg57b3mii


[root@test2 hw-8]# yc vpc subnet create --name otus-subnet --range 10.95.98.0/24 --network-name otus-net --description "otus-subnet"
id: e9bimdev5fbn811d5khc
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-13T11:09:14Z"
name: otus-subnet
description: otus-subnet
network_id: enp7vepl760r9qrp4ti2
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.95.98.0/24


[root@test2 hw-8]# yc vpc subnet list
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
|          ID          |    NAME     |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
| e9bimdev5fbn811d5khc | otus-subnet | enp7vepl760r9qrp4ti2 |                | ru-central1-a | [10.95.98.0/24] |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
```
**Создаем VM**
В качесте образа выбираем **almalinux-8**
```
[root@test2 hw-8]# yc compute instance create --name db1 --hostname db1 --cores 4 --memory 8 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=almalinux-8 --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub
done (45s)
id: fhm2nb2run9r2abfc1rb
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-13T11:25:41Z"
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
  device_name: fhmf4j3i8l799qf2i4qa
  auto_delete: true
  disk_id: fhmf4j3i8l799qf2i4qa
network_interfaces:
  - index: "0"
    mac_address: d0:0d:2b:ac:5b:f5
    subnet_id: e9bimdev5fbn811d5khc
    primary_v4_address:
      address: 10.95.98.27
      one_to_one_nat:
        address: 51.250.75.96
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
```
**Создаем и подключаем доаолнительный ssd диск**
```
[root@test2 hw-8]# yc compute disk create --name data --size 10G --type=network-ssd --description "data disk" 
done (11s)
id: fhmbdk0oqlh742ls4hml
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-13T11:27:53Z"
name: data
description: data disk
type_id: network-ssd
zone_id: ru-central1-a
size: "10737418240"
block_size: "4096"
status: READY
disk_placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1



[root@test2 hw-8]# yc compute instance attach-disk db1 --disk-name data --mode rw
done (14s)
id: fhm2nb2run9r2abfc1rb
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-13T11:25:41Z"
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
  device_name: fhmf4j3i8l799qf2i4qa
  auto_delete: true
  disk_id: fhmf4j3i8l799qf2i4qa
secondary_disks:
  - mode: READ_WRITE
    device_name: fhmbdk0oqlh742ls4hml
    disk_id: fhmbdk0oqlh742ls4hml
network_interfaces:
  - index: "0"
    mac_address: d0:0d:2b:ac:5b:f5
    subnet_id: e9bimdev5fbn811d5khc
    primary_v4_address:
      address: 10.95.98.27
      one_to_one_nat:
        address: 51.250.75.96
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


[root@test2 hw-8]# yc compute instance list
+----------------------+------+---------------+---------+--------------+-------------+
|          ID          | NAME |    ZONE ID    | STATUS  | EXTERNAL IP  | INTERNAL IP |
+----------------------+------+---------------+---------+--------------+-------------+
| fhm2nb2run9r2abfc1rb | db1  | ru-central1-a | RUNNING | 51.250.75.96 | 10.95.98.27 |
+----------------------+------+---------------+---------+--------------+-------------+


[root@test2 hw-8]# yc compute disk list
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
|          ID          | NAME |    SIZE     |     ZONE      | STATUS |     INSTANCE IDS     | PLACEMENT GROUP | DESCRIPTION |
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
| fhmbdk0oqlh742ls4hml | data | 10737418240 | ru-central1-a | READY  | fhm2nb2run9r2abfc1rb |                 | data disk   |
| fhmf4j3i8l799qf2i4qa |      | 10737418240 | ru-central1-a | READY  | fhm2nb2run9r2abfc1rb |                 |             |
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
```


### **Настраиваем ОС**

**Устанавливаем postgresql**
```
[root@db1 yc-user]# dnf update -y
[root@db1 yc-user]# dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@db1 yc-user]# dnf -qy module disable postgresql
[root@db1 yc-user]# dnf install postgresql16-server postgresql16-contrib

[root@db1 yc-user]# rpm -qa | grep postgres 
postgresql16-contrib-16.6-1PGDG.rhel8.x86_64
postgresql16-libs-16.6-1PGDG.rhel8.x86_64
postgresql16-16.6-1PGDG.rhel8.x86_64
postgresql16-server-16.6-1PGDG.rhel8.x86_64
```

  **Создаем выделенный раздел для БД и монтируем в созданные ранее диск:**
```
[root@db1 yc-user]# mkdir -p /data/pg

[root@db1 yc-user]# lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda    252:0    0  10G  0 disk 
├─vda1 252:1    0   1M  0 part 
└─vda2 252:2    0  10G  0 part /
vdb    252:16   0  10G  0 disk 

[root@db1 yc-user]# mkfs.xfs /dev/vdb
meta-data=/dev/vdb               isize=512    agcount=4, agsize=655360 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[root@db1 yc-user]# blkid 
/dev/vda2: UUID="317d8fdf-b404-4f87-a680-4f79aaae1797" BLOCK_SIZE="512" TYPE="xfs" PARTUUID="5c6f4c93-e021-4a6a-9fee-3498089af0d9"
/dev/vda1: PARTUUID="9ccf00ce-7830-4940-b4c1-2d34e90e9c74"
/dev/vdb: UUID="09ff4b70-af14-4bb2-b20c-679cf0f94c24" BLOCK_SIZE="4096" TYPE="xfs"

[root@db1 yc-user]# vi /etc/fstab 
[root@db1 yc-user]# grep 09ff4b70-af14-4bb2-b20c-679cf0f94c24 /etc/fstab
UUID=09ff4b70-af14-4bb2-b20c-679cf0f94c24 /data/pg                xfs     defaults        0 0
 
[root@db1 yc-user]# mount /data/pg
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
[root@db1 yc-user]# systemctl daemon-reload
 
[root@db1 yc-user]# mount | grep '/data/pg'
/dev/vdb on /data/pg type xfs (rw,relatime,seclabel,attr2,inode64,logbufs=8,logbsize=32k,noquota)

[root@db1 yc-user]# chown postgres:postgres /data/pg/
```

**Изменяем PGDATA в systemd юните:**
```
[root@db1 yc-user]# vi /usr/lib/systemd/system/postgresql-16.service
[root@db1 yc-user]# grep 'Environment=PGDATA' /usr/lib/systemd/system/postgresql-16.service
#Environment=PGDATA=/var/lib/pgsql/16/data/
Environment=PGDATA=/data/pg/

[root@db1 yc-user]# systemctl daemon-reload
```
**Инициализируем БД**
```
[root@db1 yc-user]# /usr/pgsql-16/bin/postgresql-16-setup initdb
Initializing database ... OK
```

**Проверяем, что в PGDATA появились каталоги и файлы БД**
```
[root@db1 yc-user]# ls -al /var/lib/pgsql/16/data/
total 0
drwx------. 2 postgres postgres  6 Nov 20 16:06 .
drwx------. 4 postgres postgres 51 Dec 13 12:14 ..
[root@db1 yc-user]# ls -al /data/pg/
total 60
drwx------. 20 postgres postgres  4096 Dec 13 12:17 .
drwxr-xr-x.  3 root     root        16 Dec 13 11:44 ..
drwx------.  5 postgres postgres    33 Dec 13 12:17 base
drwx------.  2 postgres postgres  4096 Dec 13 12:17 global
drwx------.  2 postgres postgres     6 Dec 13 12:17 log
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_commit_ts
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_dynshmem
-rw-------.  1 postgres postgres  5499 Dec 13 12:17 pg_hba.conf
-rw-------.  1 postgres postgres  2640 Dec 13 12:17 pg_ident.conf
drwx------.  4 postgres postgres    68 Dec 13 12:17 pg_logical
drwx------.  4 postgres postgres    36 Dec 13 12:17 pg_multixact
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_notify
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_replslot
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_serial
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_snapshots
drwx------.  2 postgres postgres    25 Dec 13 12:17 pg_stat
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_stat_tmp
drwx------.  2 postgres postgres    18 Dec 13 12:17 pg_subtrans
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_tblspc
drwx------.  2 postgres postgres     6 Dec 13 12:17 pg_twophase
-rw-------.  1 postgres postgres     3 Dec 13 12:17 PG_VERSION
drwx------.  3 postgres postgres    60 Dec 13 12:17 pg_wal
drwx------.  2 postgres postgres    18 Dec 13 12:17 pg_xact
-rw-------.  1 postgres postgres    88 Dec 13 12:17 postgresql.auto.conf
-rw-------.  1 postgres postgres 29663 Dec 13 12:17 postgresql.conf
```

**Добавляем загрузку shared_preload для pg_stat_statements**
```
[root@db1 yc-user]# vi /data/pg/postgresql.conf 
[root@db1 yc-user]# tail -n 8 /data/pg/postgresql.conf 

# Add settings for extensions here

# pg_stat_statements
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
pg_stat_statements.max = 10000
track_io_timing = on
```


**Запускаем postgresql и проверяем, что он запустился:**
```
[root@db1 yc-user]# systemctl enable postgresql-16
Created symlink /etc/systemd/system/multi-user.target.wants/postgresql-16.service → /usr/lib/systemd/system/postgresql-16.service.
[root@db1 yc-user]# systemctl status postgresql-16
● postgresql-16.service - PostgreSQL 16 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-12-13 12:24:18 UTC; 7s ago
     Docs: https://www.postgresql.org/docs/16/static/
  Process: 9063 ExecStartPre=/usr/pgsql-16/bin/postgresql-16-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)
 Main PID: 9069 (postgres)
    Tasks: 7 (limit: 48754)
   Memory: 21.5M
   CGroup: /system.slice/postgresql-16.service
           ├─9069 /usr/pgsql-16/bin/postgres -D /data/pg/
           ├─9071 postgres: logger 
           ├─9072 postgres: checkpointer 
           ├─9073 postgres: background writer 
           ├─9075 postgres: walwriter 
           ├─9076 postgres: autovacuum launcher 
           └─9077 postgres: logical replication launcher 

Dec 13 12:24:18 db1.ru-central1.internal systemd[1]: Starting PostgreSQL 16 database server...
Dec 13 12:24:18 db1.ru-central1.internal postgres[9069]: 2024-12-13 12:24:18.558 UTC [9069] LOG:  redirecting log output to logging collector process
Dec 13 12:24:18 db1.ru-central1.internal postgres[9069]: 2024-12-13 12:24:18.558 UTC [9069] HINT:  Future log output will appear in directory "log".
Dec 13 12:24:18 db1.ru-central1.internal systemd[1]: Started PostgreSQL 16 database server.
```

### **Подготовка к тестированию**

**Подключемся к postgres, создаем БД с именем 'example',  
и создаем EXTENSION pg_stat_statements**
```
[root@db1 yc-user]# su - postgres
[postgres@db1 ~]$ psql 
psql (16.6)
Type "help" for help.

postgres=# create database example;
CREATE DATABASE
postgres=# \c example 
You are now connected to database "example" as user "postgres".
example=# CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION
```

**Перегружаем VM:**
```
[root@db1 yc-user]# reboot
Connection to 51.250.75.96 closed by remote host.
Connection to 51.250.75.96 closed.
```

**На этом этапе у нас есть преднастроенный инстанс БД postgres  
с дефолтными настройками.**
  
**Инициализируем pgbench на использование БД "example":**
```
[postgres@db1 ~]$ /usr/pgsql-16/bin/pgbench -s 100 -i example
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
10000000 of 10000000 tuples (100%) done (elapsed 197.73 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 253.77 s (drop tables 0.00 s, create tables 0.03 s, client-side generate 224.40 s, vacuum 0.30 s, primary keys 29.03 s).
```

### **Тестирование с дефолтной конфигурацией**

**Предварительно очищаем статистику:**
```
[postgres@db1 ~]$ psql -d example -c 'SELECT pg_stat_statements_reset();'
 pg_stat_statements_reset 
--------------------------
 
(1 row)
```

**Запускаем три раза pgbench и выбираем лучший результат:**
```
[postgres@db1 ~]$ /usr/pgsql-16/bin/pgbench -c 50 -j 4 -T 120 example
pgbench (16.6)
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: simple
number of clients: 50
number of threads: 4
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 61704
number of failed transactions: 0 (0.000%)
latency average = 97.250 ms
initial connection time = 49.601 ms
tps = 514.137776 (without initial connection time)
```

**Собираем статистику запросов с pg_stat_statements**
```
[postgres@db1 ~]$ psql -d example -c 'SELECT substring(query, 1, 50) AS short_query, round(total_exec_time::numeric, 2) AS total_time, calls, rows, round(total_exec_time::numeric / calls, 2) AS avg_time, round((100 * total_exec_time/ sum(total_exec_time::numeric) OVER ())::numeric, 2) AS percentage_cpu FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;'
                    short_query                     | total_time | calls  |  rows  | avg_time | percentage_cpu 
----------------------------------------------------+------------+--------+--------+----------+----------------
 UPDATE pgbench_branches SET bbalance = bbalance +  | 3766941.98 | 164627 | 164627 |    22.88 |          87.97
 UPDATE pgbench_tellers SET tbalance = tbalance + $ |  485080.08 | 164627 | 164627 |     2.95 |          11.33
 UPDATE pgbench_accounts SET abalance = abalance +  |   25553.79 | 164627 | 164627 |     0.16 |           0.60
 SELECT abalance FROM pgbench_accounts WHERE aid =  |    2288.34 | 164627 | 164627 |     0.01 |           0.05
 INSERT INTO pgbench_history (tid, bid, aid, delta, |    1913.35 | 164627 | 164627 |     0.01 |           0.04
 BEGIN                                              |     109.58 | 164627 |      0 |     0.00 |           0.00
 END                                                |      97.32 | 164627 |      0 |     0.00 |           0.00
 vacuum pgbench_branches                            |      34.78 |      3 |      0 |    11.59 |           0.00
 vacuum pgbench_tellers                             |       2.31 |      3 |      0 |     0.77 |           0.00
 select count(\*) from pgbench_branches              |       0.78 |      3 |      3 |     0.26 |           0.00
(10 rows)
```


### **Тюним БД**

**Добавляем опции "noatime,nodiratime" в "/etc/fstab" и перемонтируем "/data/pg" и  
проверяем, что параметры добавились:**
```
[root@db1 yc-user]# grep 09ff4b70-af14-4bb2-b20c-679cf0f94c24 /etc/fstab
UUID=09ff4b70-af14-4bb2-b20c-679cf0f94c24 /data/pg                xfs     defaults,noatime,nodiratime        0 0

[root@db1 yc-user]# systemctl daemon-reload
[root@db1 yc-user]# mount -o remount /data/pg

[root@db1 yc-user]# mount | grep '/data/pg'
/dev/vdb on /data/pg type xfs (rw,noatime,nodiratime,seclabel,attr2,inode64,logbufs=8,logbsize=32k,noquota)
```

  Настраиваем tuned:
  Проверяем, что демон запущен
```
[root@db1 yc-user]# systemctl status tuned
● tuned.service - Dynamic System Tuning Daemon
   Loaded: loaded (/usr/lib/systemd/system/tuned.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2024-12-13 12:30:13 UTC; 35min ago
     Docs: man:tuned(8)
           man:tuned.conf(5)
           man:tuned-adm(8)
 Main PID: 770 (tuned)
    Tasks: 4 (limit: 48754)
   Memory: 19.7M
   CGroup: /system.slice/tuned.service
           └─770 /usr/libexec/platform-python -Es /usr/sbin/tuned -l -P

Dec 13 12:30:12 db1.ru-central1.internal systemd[1]: Starting Dynamic System Tuning Daemon...
Dec 13 12:30:13 db1.ru-central1.internal systemd[1]: Started Dynamic System Tuning Daemon.
```
  Создаем кастомный конфиг с именем postgresql:
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
```
  Восстанавлием правила selinux:
```
[root@db1 yc-user]# restorecon -RFvv /usr/lib/tuned/postgresql
Relabeled /usr/lib/tuned/postgresql from unconfined_u:object_r:lib_t:s0 to system_u:object_r:lib_t:s0
Relabeled /usr/lib/tuned/postgresql/tuned.conf from unconfined_u:object_r:lib_t:s0 to system_u:object_r:lib_t:s0
```
  Активируем профиль с именем postgresql:
```
[root@db1 yc-user]# tuned-adm list | grep postgre
- postgresql                  - Optimize for PostgreSQL RDBMS
[root@db1 yc-user]# 
[root@db1 yc-user]# tuned-adm profile postgresql
[root@db1 yc-user]# 
[root@db1 yc-user]# tuned-adm active
Current active profile: postgresql
```

  Увеличиваем лимиты для пользователя postgres   
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

[root@db1 yc-user]# restorecon -Fvv /etc/security/limits.d/30-pgsqlproc.conf
Relabeled /etc/security/limits.d/30-pgsqlproc.conf from unconfined_u:object_r:etc_t:s0 to system_u:object_r:etc_t:s0
```


  Используя https://www.pgconfig.org и входные параметры:
```
num_cpu=4
total_mem=8G
max_conn=100
postgres_version=16
storage=ssd
profile=oltp
```
  Формируем параметры для postgresql.conf
```
# Memory Configuration
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 29MB
maintenance_work_mem = 410MB

# Checkpoint Related Configuration
min_wal_size = 2GB
max_wal_size = 3GB
checkpoint_completion_target = 0.9
wal_buffers = -1

# Storage Configuration
random_page_cost = 1.1
effective_io_concurrency = 200

# Worker Processes Configuration
max_worker_processes = 8
max_parallel_workers_per_gather = 2
max_parallel_workers = 2
```

  Перегружаем VM:
```
[root@db1 yc-user]# reboot
Connection to 51.250.75.96 closed by remote host.
Connection to 51.250.75.96 closed.
```

```
[root@db1 yc-user]# sysctl -a | grep vm.swappiness
vm.swappiness = 5

[postgres@db1 ~]$ psql -c 'SHOW shared_buffers'
 shared_buffers 
----------------
 2GB
(1 row)

[postgres@db1 ~]$ psql -c 'SHOW effective_cache_size'
 effective_cache_size 
----------------------
 6GB
(1 row)
```

  Проверяем установку limits:
```
[root@db1 yc-user]# systemctl status postgresql-16.service | grep 'Main PID'
 Main PID: 1019 (postgres)
[root@db1 yc-user]# 
[root@db1 yc-user]# cat /proc/1019/l
limits    loginuid  
[root@db1 yc-user]# cat /proc/1019/limits 
Limit                     Soft Limit           Hard Limit           Units     
Max cpu time              unlimited            unlimited            seconds   
Max file size             unlimited            unlimited            bytes     
Max data size             unlimited            unlimited            bytes     
Max stack size            8388608              unlimited            bytes     
Max core file size        unlimited            unlimited            bytes     
Max resident set          unlimited            unlimited            bytes     
Max processes             30471                30471                processes 
Max open files            500000               500000               files     
Max locked memory         65536                65536                bytes     
Max address space         unlimited            unlimited            bytes     
Max file locks            unlimited            unlimited            locks     
Max pending signals       30471                30471                signals   
Max msgqueue size         819200               819200               bytes     
Max nice priority         0                    0                    
Max realtime priority     0                    0                    
Max realtime timeout      unlimited            unlimited            us    
```

  Сбрасываем статистике pg_stat_statements:
```
[postgres@db1 ~]$ psql -d example -c 'SELECT pg_stat_statements_reset();'
 pg_stat_statements_reset 
--------------------------
 
(1 row)
```

  Запускаем три раза pgbench и выбираем лучший результат:
```
[postgres@db1 ~]$ /usr/pgsql-16/bin/pgbench -c 50 -j 4 -T 120 example
pgbench (16.6)
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: simple
number of clients: 50
number of threads: 4
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 175528
number of failed transactions: 0 (0.000%)
latency average = 34.228 ms
initial connection time = 51.061 ms
tps = 1460.792281 (without initial connection time)
```

```
[postgres@db1 ~]$ psql -d example -c 'SELECT substring(query, 1, 50) AS short_query, round(total_exec_time::numeric, 2) AS total_time, calls, rows, round(total_exec_time::numeric / calls, 2) AS avg_time, round((100 * total_exec_time/ sum(total_exec_time::numeric) OVER ())::numeric, 2) AS percentage_cpu FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;'
                    short_query                     | total_time | calls  |  rows  | avg_time | percentage_cpu 
----------------------------------------------------+------------+--------+--------+----------+----------------
 UPDATE pgbench_branches SET bbalance = bbalance +  | 3363124.30 | 475325 | 475325 |     7.08 |          87.27
 UPDATE pgbench_tellers SET tbalance = tbalance + $ |  449732.53 | 475325 | 475325 |     0.95 |          11.67
 UPDATE pgbench_accounts SET abalance = abalance +  |   27819.59 | 475325 | 475325 |     0.06 |           0.72
 SELECT abalance FROM pgbench_accounts WHERE aid =  |    6624.26 | 475325 | 475325 |     0.01 |           0.17
 INSERT INTO pgbench_history (tid, bid, aid, delta, |    5680.91 | 475325 | 475325 |     0.01 |           0.15
 BEGIN                                              |     286.02 | 475325 |      0 |     0.00 |           0.01
 END                                                |     273.89 | 475325 |      0 |     0.00 |           0.01
 vacuum pgbench_tellers                             |       2.04 |      3 |      0 |     0.68 |           0.00
 vacuum pgbench_branches                            |       1.21 |      3 |      0 |     0.40 |           0.00
 truncate pgbench_history                           |       0.74 |      3 |      0 |     0.25 |           0.00
(10 rows)
```

## Удаляем созданные ресурсы:
```
[root@test2 hw-8]# yc compute instance delete --name db1
done (1m23s)
[root@test2 hw-8]# yc compute disk delete --name data 
done (15s)
[root@test2 hw-8]# yc vpc subnet delete --name otus-subnet
done (3s)
[root@test2 hw-8]# yc vpc network delete --name "otus-net"
```


## Сравнение результатов

|                                                    | было       | стало      |
|----------------------------------------------------|------------|------------|
|number of transactions actually processed           | 61704      |175528      |
|latency average                                     | 97.250 ms  | 34.228 ms  | 
|initial connection time                             | 49.601 ms  | 51.061 ms  |
|tps (without initial connection time)               | 514.137776 | 1460.792281|
|UPDATE pgbench_branches SET bbalance = bbalance +   | 22.88      | 7.08       |
|UPDATE pgbench_tellers SET tbalance = tbalance + $  | 2.95       | 0.95       |
|UPDATE pgbench_accounts SET abalance = abalance +   | 0.16       | 0.06       |
|SELECT abalance FROM pgbench_accounts WHERE aid =   | 0.01       | 0.01       |
|INSERT INTO pgbench_history (tid, bid, aid, delta,  | 0.01       | 0.01       |

