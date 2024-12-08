# **HW-5 | Настройка дисков для Постгреса**


## **Цель:**
создавать дополнительный диск для уже существующей виртуальной машины, размечать его и делать на нем файловую систему  
переносить содержимое базы данных PostgreSQL на дополнительный диск  
переносить содержимое БД PostgreSQL между виртуальными машинами  


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
- создайте виртуальную машину c Ubuntu 20.04 LTS (bionic) в GCE типа e2-medium в default VPC в любом регионе и зоне, например us-central1-a или ЯО/VirtualBox
- поставьте на нее PostgreSQL 15 через sudo apt
- проверьте что кластер запущен через sudo -u postgres pg_lsclusters
- зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым  
  postgres=# create table test(c1 text);
  postgres=# insert into test values('1');
  \q
- остановите postgres например через  
  sudo -u postgres pg_ctlcluster 15 main stop
- создайте новый standard persistent диск GKE через Compute Engine ->   
  Disks в том же регионе и зоне что GCE инстанс размером например 10GB - или аналог в другом облаке/виртуализации
- добавьте свеже-созданный диск к виртуальной машине   
  надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
- проинициализируйте диск согласно инструкции и подмонтировать файловую систему,   
  только не забывайте менять имя диска на актуальное, в вашем случае   
  это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
- перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)
- сделайте пользователя postgres владельцем /mnt/data  
  chown -R postgres:postgres /mnt/data/
- перенесите содержимое   
  /var/lib/postgresql/15 в /mnt/data - mv /var/lib/postgresql/15 /mnt/data
- попытайтесь запустить кластер  
  sudo -u postgres pg_ctlcluster 15 main start
- напишите получилось или нет и почему
- задание:   
  найти конфигурационный параметр в файлах раположенных в /etc/postgresql/14/main который надо поменять и поменяйте его
- напишите что и почему поменяли
- попытайтесь запустить кластер  
  sudo -u postgres pg_ctlcluster 15 main start
- напишите получилось или нет и почему
- зайдите через через psql и проверьте содержимое ранее созданной таблицы
- задание со звездочкой <\*>:
  не удаляя существующий GCE инстанс/ЯО сделайте новый,   
  поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgresql,   
  перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй  
  и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске,  
  расскажите как вы это сделали и что в итоге получилось.


## **Выполнение ДЗ**

### **Выбираем и настраиваем зону для инсталлации кластера**
```
[root@test2 hw-5]# yc compute zone list
+---------------+--------+
|      ID       | STATUS |
+---------------+--------+
| ru-central1-a | UP     |
| ru-central1-b | UP     |
| ru-central1-c | DOWN   |
| ru-central1-d | UP     |
+---------------+--------+

[root@test2 hw-5]# yc config set compute-default-zone ru-central1-a && yc config get compute-default-zone
ru-central1-a
```

### **Выбираем тип локального диска**
```
[root@test2 hw-5]# yc compute disk-type list 
+---------------------------+--------------------------------+
|            ID             |          DESCRIPTION           |
+---------------------------+--------------------------------+
| network-hdd               | Network storage with HDD       |
|                           | backend                        |
| network-ssd               | Network storage with SSD       |
|                           | backend                        |
| network-ssd-io-m3         | Fast network storage with      |
|                           | three replicas                 |
| network-ssd-nonreplicated | Non-replicated network storage |
|                           | with SSD backend               |
+---------------------------+--------------------------------+
```

### **Создаем сеть "otus-net"**
```
[root@test2 hw-5]# yc vpc network create --name "otus-net" --description "otus-net"
id: enpf83aabsa50gtdn5ri
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T19:57:28Z"
name: otus-net
description: otus-net
default_security_group_id: enpacgea2thk0tsr1f4h

[root@test2 hw-5]# yc vpc network list
+----------------------+----------+
|          ID          |   NAME   |
+----------------------+----------+
| enpf83aabsa50gtdn5ri | otus-net |
+----------------------+----------+
```

### **Создаем подсеть "otus-subnet" в сети "otus-net"**
```
[root@test2 hw-5]# yc vpc subnet create --name otus-subnet --range 10.95.95.0/24 --network-name otus-net --description "otus-subnet"
id: e9bsop830oeelmo13dmc
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T19:58:30Z"
name: otus-subnet
description: otus-subnet
network_id: enpf83aabsa50gtdn5ri
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.95.95.0/24

[root@test2 hw-5]# yc vpc subnet list
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
|          ID          |    NAME     |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
| e9bsop830oeelmo13dmc | otus-subnet | enpf83aabsa50gtdn5ri |                | ru-central1-a | [10.95.95.0/24] |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
```

### **Создаем VM с именем "db1"**
```
[root@test2 hw-5]# yc compute instance create --name db1 --hostname db1 --cores 2 --memory 4 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub 
done (2m10s)
id: fhm47ougjd8b9c8j56lh
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T20:01:31Z"
name: db1
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm84e0mdgs3jera0pth
  auto_delete: true
  disk_id: fhm84e0mdgs3jera0pth
network_interfaces:
  - index: "0"
    mac_address: d0:0d:43:e3:d0:9b
    subnet_id: e9bsop830oeelmo13dmc
    primary_v4_address:
      address: 10.95.95.18
      one_to_one_nat:
        address: 51.250.7.50
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
    pci_topology: PCI_TOPOLOGY_V2
```

### **Подключаемся к VM и устанавливаем postgres 15**
```
[root@test2 hw-5]# ssh yc-user@51.250.7.50 -i /home/voronov/.ssh/id_rsa
Warning: Permanently added '51.250.7.50' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/voronov/.ssh/id_rsa': 
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-200-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro
New release '22.04.5 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

Last login: Sun Dec  8 20:09:33 2024 from 78.85.16.136
yc-user@db1:~$ 
yc-user@db1:~$ sudo apt update && sudo apt upgrade -y -q
Hit:1 http://mirror.yandex.ru/ubuntu focal InRelease
Get:2 http://mirror.yandex.ru/ubuntu focal-updates InRelease [128 kB]
Get:3 http://mirror.yandex.ru/ubuntu focal-backports InRelease [128 kB]
Get:4 http://security.ubuntu.com/ubuntu focal-security InRelease [128 kB]
Get:5 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 Packages [3,681 kB]
Get:6 http://mirror.yandex.ru/ubuntu focal-updates/main i386 Packages [1,056 kB]
Get:7 http://mirror.yandex.ru/ubuntu focal-updates/restricted i386 Packages [40.4 kB]      
Get:8 http://mirror.yandex.ru/ubuntu focal-updates/restricted amd64 Packages [3,397 kB]
Get:9 http://mirror.yandex.ru/ubuntu focal-updates/restricted Translation-en [474 kB]  
Get:10 http://mirror.yandex.ru/ubuntu focal-updates/multiverse amd64 Packages [27.9 kB]
Get:11 http://mirror.yandex.ru/ubuntu focal-updates/multiverse Translation-en [7,968 B]
Get:12 http://security.ubuntu.com/ubuntu focal-security/main amd64 Packages [3,304 kB]
Get:13 http://security.ubuntu.com/ubuntu focal-security/main i386 Packages [835 kB]
Fetched 13.2 MB in 3s (3,945 kB/s)                        
Reading package lists... Done
Building dependency tree       
Reading state information... Done
All packages are up to date.
Reading package lists...
Building dependency tree...
Reading state information...
Calculating upgrade...
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
yc-user@db1:~$ echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list
deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main
yc-user@db1:~$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
OK
yc-user@db1:~$ sudo apt-get update && sudo apt -y install postgresql-15
Hit:1 http://mirror.yandex.ru/ubuntu focal InRelease
Hit:2 http://mirror.yandex.ru/ubuntu focal-updates InRelease                                              
Hit:3 http://mirror.yandex.ru/ubuntu focal-backports InRelease                                            
Get:4 http://apt.postgresql.org/pub/repos/apt focal-pgdg InRelease [129 kB]                               
Hit:5 http://security.ubuntu.com/ubuntu focal-security InRelease                                          
Get:6 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 Packages [350 kB]
Fetched 480 kB in 1s (518 kB/s)    
Reading package lists... Done
N: Skipping acquire of configured file 'main/binary-i386/Packages' as repository 'http://apt.postgresql.org/pub/repos/apt focal-pgdg InRelease' doesn't support architecture 'i386'
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following additional packages will be installed:
  libcommon-sense-perl libgdbm-compat4 libio-pty-perl libipc-run-perl libjson-perl libjson-xs-perl libllvm10 libperl5.30 libpq5 libsensors-config libsensors5
  libtypes-serialiser-perl libxslt1.1 perl perl-modules-5.30 postgresql-client-15 postgresql-client-common postgresql-common ssl-cert sysstat
Suggested packages:
  lm-sensors perl-doc libterm-readline-gnu-perl | libterm-readline-perl-perl make libb-debug-perl liblocale-codes-perl postgresql-doc-15 openssl-blacklist isag
The following NEW packages will be installed:
  libcommon-sense-perl libgdbm-compat4 libio-pty-perl libipc-run-perl libjson-perl libjson-xs-perl libllvm10 libperl5.30 libpq5 libsensors-config libsensors5
  libtypes-serialiser-perl libxslt1.1 perl perl-modules-5.30 postgresql-15 postgresql-client-15 postgresql-client-common postgresql-common ssl-cert sysstat
0 upgraded, 21 newly installed, 0 to remove and 0 not upgraded.
Need to get 41.9 MB of archives.
After this operation, 188 MB of additional disk space will be used.
Get:1 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 perl-modules-5.30 all 5.30.0-9ubuntu0.5 [2,739 kB]
Get:2 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-client-common all 267.pgdg20.04+1 [95.1 kB]
Get:3 http://mirror.yandex.ru/ubuntu focal/main amd64 libgdbm-compat4 amd64 1.18.1-5 [6,244 B]
Get:4 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libperl5.30 amd64 5.30.0-9ubuntu0.5 [3,941 kB]
Get:5 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-common all 267.pgdg20.04+1 [241 kB]
Get:6 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 libpq5 amd64 17.2-1.pgdg20.04+1 [223 kB]
Get:7 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 perl amd64 5.30.0-9ubuntu0.5 [224 kB]
Get:8 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-client-15 amd64 15.10-1.pgdg20.04+1 [1,694 kB]
Get:9 http://mirror.yandex.ru/ubuntu focal/main amd64 libjson-perl all 4.02000-2 [80.9 kB]
Get:10 http://mirror.yandex.ru/ubuntu focal/main amd64 libio-pty-perl amd64 1:1.12-1 [32.4 kB]
Get:11 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-15 amd64 15.10-1.pgdg20.04+1 [16.5 MB]
Get:12 http://mirror.yandex.ru/ubuntu focal/main amd64 libipc-run-perl all 20180523.0-2 [89.7 kB]
Get:13 http://mirror.yandex.ru/ubuntu focal/main amd64 ssl-cert all 1.0.39 [17.0 kB]
Get:14 http://mirror.yandex.ru/ubuntu focal/main amd64 libcommon-sense-perl amd64 3.74-2build6 [20.1 kB]
Get:15 http://mirror.yandex.ru/ubuntu focal/main amd64 libtypes-serialiser-perl all 1.0-1 [12.1 kB]
Get:16 http://mirror.yandex.ru/ubuntu focal/main amd64 libjson-xs-perl amd64 4.020-1build1 [83.7 kB]
Get:17 http://mirror.yandex.ru/ubuntu focal/main amd64 libllvm10 amd64 1:10.0.0-4ubuntu1 [15.3 MB]
Get:18 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libsensors-config all 1:3.6.0-2ubuntu1.1 [6,052 B]
Get:19 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libsensors5 amd64 1:3.6.0-2ubuntu1.1 [27.2 kB]
Get:20 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libxslt1.1 amd64 1.1.34-4ubuntu0.20.04.1 [151 kB]
Get:21 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 sysstat amd64 12.2.0-2ubuntu0.3 [448 kB]
Fetched 41.9 MB in 1s (28.1 MB/s)
Preconfiguring packages ...
Selecting previously unselected package perl-modules-5.30.
(Reading database ... 102701 files and directories currently installed.)
Preparing to unpack .../00-perl-modules-5.30_5.30.0-9ubuntu0.5_all.deb ...
Unpacking perl-modules-5.30 (5.30.0-9ubuntu0.5) ...
Selecting previously unselected package libgdbm-compat4:amd64.
Preparing to unpack .../01-libgdbm-compat4_1.18.1-5_amd64.deb ...
Unpacking libgdbm-compat4:amd64 (1.18.1-5) ...
Selecting previously unselected package libperl5.30:amd64.
Preparing to unpack .../02-libperl5.30_5.30.0-9ubuntu0.5_amd64.deb ...
Unpacking libperl5.30:amd64 (5.30.0-9ubuntu0.5) ...
Selecting previously unselected package perl.
Preparing to unpack .../03-perl_5.30.0-9ubuntu0.5_amd64.deb ...
Unpacking perl (5.30.0-9ubuntu0.5) ...
Selecting previously unselected package libjson-perl.
Preparing to unpack .../04-libjson-perl_4.02000-2_all.deb ...
Unpacking libjson-perl (4.02000-2) ...
Selecting previously unselected package libio-pty-perl.
Preparing to unpack .../05-libio-pty-perl_1%3a1.12-1_amd64.deb ...
Unpacking libio-pty-perl (1:1.12-1) ...
Selecting previously unselected package libipc-run-perl.
Preparing to unpack .../06-libipc-run-perl_20180523.0-2_all.deb ...
Unpacking libipc-run-perl (20180523.0-2) ...
Selecting previously unselected package postgresql-client-common.
Preparing to unpack .../07-postgresql-client-common_267.pgdg20.04+1_all.deb ...
Unpacking postgresql-client-common (267.pgdg20.04+1) ...
Selecting previously unselected package ssl-cert.
Preparing to unpack .../08-ssl-cert_1.0.39_all.deb ...
Unpacking ssl-cert (1.0.39) ...
Selecting previously unselected package postgresql-common.
Preparing to unpack .../09-postgresql-common_267.pgdg20.04+1_all.deb ...
Adding 'diversion of /usr/bin/pg_config to /usr/bin/pg_config.libpq-dev by postgresql-common'
Unpacking postgresql-common (267.pgdg20.04+1) ...
Selecting previously unselected package libcommon-sense-perl.
Preparing to unpack .../10-libcommon-sense-perl_3.74-2build6_amd64.deb ...
Unpacking libcommon-sense-perl (3.74-2build6) ...
Selecting previously unselected package libtypes-serialiser-perl.
Preparing to unpack .../11-libtypes-serialiser-perl_1.0-1_all.deb ...
Unpacking libtypes-serialiser-perl (1.0-1) ...
Selecting previously unselected package libjson-xs-perl.
Preparing to unpack .../12-libjson-xs-perl_4.020-1build1_amd64.deb ...
Unpacking libjson-xs-perl (4.020-1build1) ...
Selecting previously unselected package libllvm10:amd64.
Preparing to unpack .../13-libllvm10_1%3a10.0.0-4ubuntu1_amd64.deb ...
Unpacking libllvm10:amd64 (1:10.0.0-4ubuntu1) ...
Selecting previously unselected package libpq5:amd64.
Preparing to unpack .../14-libpq5_17.2-1.pgdg20.04+1_amd64.deb ...
Unpacking libpq5:amd64 (17.2-1.pgdg20.04+1) ...
Selecting previously unselected package libsensors-config.
Preparing to unpack .../15-libsensors-config_1%3a3.6.0-2ubuntu1.1_all.deb ...
Unpacking libsensors-config (1:3.6.0-2ubuntu1.1) ...
Selecting previously unselected package libsensors5:amd64.
Preparing to unpack .../16-libsensors5_1%3a3.6.0-2ubuntu1.1_amd64.deb ...
Unpacking libsensors5:amd64 (1:3.6.0-2ubuntu1.1) ...
Selecting previously unselected package libxslt1.1:amd64.
Preparing to unpack .../17-libxslt1.1_1.1.34-4ubuntu0.20.04.1_amd64.deb ...
Unpacking libxslt1.1:amd64 (1.1.34-4ubuntu0.20.04.1) ...
Selecting previously unselected package postgresql-client-15.
Preparing to unpack .../18-postgresql-client-15_15.10-1.pgdg20.04+1_amd64.deb ...
Unpacking postgresql-client-15 (15.10-1.pgdg20.04+1) ...
Selecting previously unselected package postgresql-15.
Preparing to unpack .../19-postgresql-15_15.10-1.pgdg20.04+1_amd64.deb ...
Unpacking postgresql-15 (15.10-1.pgdg20.04+1) ...
Selecting previously unselected package sysstat.
Preparing to unpack .../20-sysstat_12.2.0-2ubuntu0.3_amd64.deb ...
Unpacking sysstat (12.2.0-2ubuntu0.3) ...
Setting up perl-modules-5.30 (5.30.0-9ubuntu0.5) ...
Setting up libsensors-config (1:3.6.0-2ubuntu1.1) ...
Setting up libpq5:amd64 (17.2-1.pgdg20.04+1) ...
Setting up libllvm10:amd64 (1:10.0.0-4ubuntu1) ...
Setting up ssl-cert (1.0.39) ...
Setting up libgdbm-compat4:amd64 (1.18.1-5) ...
Setting up libsensors5:amd64 (1:3.6.0-2ubuntu1.1) ...
Setting up libxslt1.1:amd64 (1.1.34-4ubuntu0.20.04.1) ...
Setting up libperl5.30:amd64 (5.30.0-9ubuntu0.5) ...
Setting up sysstat (12.2.0-2ubuntu0.3) ...

Creating config file /etc/default/sysstat with new version
update-alternatives: using /usr/bin/sar.sysstat to provide /usr/bin/sar (sar) in auto mode
Created symlink /etc/systemd/system/multi-user.target.wants/sysstat.service → /lib/systemd/system/sysstat.service.
Setting up perl (5.30.0-9ubuntu0.5) ...
Setting up libjson-perl (4.02000-2) ...
Setting up libio-pty-perl (1:1.12-1) ...
Setting up libcommon-sense-perl (3.74-2build6) ...
Setting up libipc-run-perl (20180523.0-2) ...
Setting up libtypes-serialiser-perl (1.0-1) ...
Setting up postgresql-client-common (267.pgdg20.04+1) ...
Setting up libjson-xs-perl (4.020-1build1) ...
Setting up postgresql-client-15 (15.10-1.pgdg20.04+1) ...
update-alternatives: using /usr/share/postgresql/15/man/man1/psql.1.gz to provide /usr/share/man/man1/psql.1.gz (psql.1.gz) in auto mode
Setting up postgresql-common (267.pgdg20.04+1) ...
Adding user postgres to group ssl-cert

Creating config file /etc/postgresql-common/createcluster.conf with new version
Building PostgreSQL dictionaries from installed myspell/hunspell packages...
Removing obsolete dictionary files:
'/etc/apt/trusted.gpg.d/apt.postgresql.org.gpg' -> '/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg'
Created symlink /etc/systemd/system/multi-user.target.wants/postgresql.service → /lib/systemd/system/postgresql.service.
Setting up postgresql-15 (15.10-1.pgdg20.04+1) ...
Creating new PostgreSQL cluster 15/main ...
/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/main --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/15/main ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Processing triggers for systemd (245.4-4ubuntu3.24) ...
Processing triggers for man-db (2.9.1-1) ...
Processing triggers for libc-bin (2.31-0ubuntu9.16) ...
yc-user@db1:~$
```

### **Проверяем, что postgres запустился**
```
yc-user@db1:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

### **Подключаемся к postgres и создаем тестовую бд "db_otus_hw5" с таблицей "test"**
```
yc-user@db1:~$ sudo -u postgres psql
psql (15.10 (Ubuntu 15.10-1.pgdg20.04+1))
Type "help" for help.

postgres=# CREATE DATABASE db_otus_hw5
postgres-# ;
CREATE DATABASE
postgres=# \c db_otus_hw5 
You are now connected to database "db_otus_hw5" as user "postgres".
db_otus_hw5=# 
db_otus_hw5=# create table test(c1 text);
CREATE TABLE
db_otus_hw5=# insert into test values('1');
INSERT 0 1
db_otus_hw5=# insert into test values('2');
INSERT 0 1
db_otus_hw5=# insert into test values('3');
INSERT 0 1
db_otus_hw5=# \q
```

### **Останавливаем postgres**
```
yc-user@db1:~$  sudo -u postgres pg_ctlcluster 15 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@15-main
yc-user@db1:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

### **Создаем дополнительный диск с именем "data" размером 10G**
```
[root@test2 hw-5]# yc compute disk list
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
|          ID          | NAME |    SIZE     |     ZONE      | STATUS |     INSTANCE IDS     | PLACEMENT GROUP | DESCRIPTION |
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
| fhm84e0mdgs3jera0pth |      | 10737418240 | ru-central1-a | READY  | fhm47ougjd8b9c8j56lh |                 |             |
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+

[root@test2 hw-5]# yc compute disk create --name data --size 10 --description "data disk"
done (11s)
id: fhmhov7h6d06tm1ki22o
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T20:19:34Z"
name: data
description: data disk
type_id: network-hdd
zone_id: ru-central1-a
size: "10737418240"
block_size: "4096"
status: READY
disk_placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1

[root@test2 hw-5]# yc compute disk list
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
|          ID          | NAME |    SIZE     |     ZONE      | STATUS |     INSTANCE IDS     | PLACEMENT GROUP | DESCRIPTION |
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
| fhm84e0mdgs3jera0pth |      | 10737418240 | ru-central1-a | READY  | fhm47ougjd8b9c8j56lh |                 |             |
| fhmhov7h6d06tm1ki22o | data | 10737418240 | ru-central1-a | READY  |                      |                 | data disk   |
+----------------------+------+-------------+---------------+--------+----------------------+-----------------+-------------+
```

### **Подключаем диск "data" к VM "db1"**
```
[root@test2 hw-5]# yc compute instance list
+----------------------+------+---------------+---------+-------------+-------------+
|          ID          | NAME |    ZONE ID    | STATUS  | EXTERNAL IP | INTERNAL IP |
+----------------------+------+---------------+---------+-------------+-------------+
| fhm47ougjd8b9c8j56lh | db1  | ru-central1-a | RUNNING | 51.250.7.50 | 10.95.95.18 |
+----------------------+------+---------------+---------+-------------+-------------+

[root@test2 hw-5]# yc compute instance attach-disk db1 --disk-name data --mode rw
done (10s)
id: fhm47ougjd8b9c8j56lh
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T20:01:31Z"
name: db1
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm84e0mdgs3jera0pth
  auto_delete: true
  disk_id: fhm84e0mdgs3jera0pth
secondary_disks:
  - mode: READ_WRITE
    device_name: fhmhov7h6d06tm1ki22o
    disk_id: fhmhov7h6d06tm1ki22o
network_interfaces:
  - index: "0"
    mac_address: d0:0d:43:e3:d0:9b
    subnet_id: e9bsop830oeelmo13dmc
    primary_v4_address:
      address: 10.95.95.18
      one_to_one_nat:
        address: 51.250.7.50
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
    pci_topology: PCI_TOPOLOGY_V2
```

### **Настраиваем диск в ОС и монтируем его в директорию "/mnt/data"**
````
yc-user@db1:~$ sudo lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda    252:0    0  10G  0 disk 
├─vda1 252:1    0   1M  0 part 
└─vda2 252:2    0  10G  0 part /
vdb    252:16   0  10G  0 disk 

yc-user@db1:~$ sudo bash
root@db1:/home/yc-user# mkfs.ext4 /dev/vdb
mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 2621440 4k blocks and 655360 inodes
Filesystem UUID: b9e73052-c876-45b1-b682-f30dd70bda22
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@db1:/home/yc-user# mkdir /mnt/data

root@db1:/home/yc-user# blkid 
/dev/vda2: UUID="be2c7c06-cc2b-4d4b-96c6-e3700932b129" TYPE="ext4" PARTUUID="634e05c7-9520-4e9b-bcdb-3329603f1b2c"
/dev/vda1: PARTUUID="c111767e-981d-4e57-85a0-ac66da561517"
/dev/vdb: UUID="b9e73052-c876-45b1-b682-f30dd70bda22" TYPE="ext4"

root@db1:/home/yc-user# vim /etc/fstab 

root@db1:/home/yc-user# grep b9e73052-c876-45b1-b682-f30dd70bda22 /etc/fstab 
UUID="b9e73052-c876-45b1-b682-f30dd70bda22" /mnt/data     ext4    defaults    0  0
root@db1:/home/yc-user# mount /mnt/data
````

### **Перегружаем VM**


### **После перезагрузки VM останавиваем postgres и переносим данные из "/var/lib/postgresql/15" в "/mnt/data"**
```
yc-user@db1:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
yc-user@db1:~$ 
yc-user@db1:~$ 
yc-user@db1:~$ sudo -u postgres pg_ctlcluster 15 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@15-main
yc-user@db1:~$ 
yc-user@db1:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
yc-user@db1:~$ 
yc-user@db1:~$ sudo chown -R postgres:postgres /mnt/data/
yc-user@db1:~$ sudo mv /var/lib/postgresql/15 /mnt/data
yc-user@db1:~$ ls -al /mnt/data
total 28
drwxr-xr-x 4 postgres postgres  4096 Dec  8 20:31 .
drwxr-xr-x 3 root     root      4096 Dec  8 20:25 ..
drwxr-xr-x 3 postgres postgres  4096 Dec  8 20:12 15
drwx------ 2 postgres postgres 16384 Dec  8 20:24 lost+found
```

### **Пробуем стартовать postgres**
видим ошибку, причина ошибки "отсутствует директория с данными postgres", т.к. мы их перенесли в "/mnt/data"
``` 
yc-user@db1:~$ sudo -u postgres pg_ctlcluster 15 main start
Error: /var/lib/postgresql/15/main is not accessible or does not exist
```

### **Вносим изменения в конфиг postgres**
```
yc-user@db1:~$ sudo vim /etc/postgresql/15/main/postgresql.conf 
yc-user@db1:~$ 
yc-user@db1:~$ grep data_directory /etc/postgresql/15/main/postgresql.conf 
data_directory = '/var/lib/postgresql/15/main'		# use data in another directory
data_directory = '/mnt/data/15/main'
```

### **Пробуем стартовать postgres, на этот рах успех**
```
yc-user@db1:~$ sudo -u postgres pg_ctlcluster 15 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@15-main
yc-user@db1:~$ 
yc-user@db1:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory    Log file
15  main    5432 online postgres /mnt/data/15/main /var/log/postgresql/postgresql-15-main.log
yc-user@db1:~$ 
```

### **Проверяем наличие данных**
```
yc-user@db1:~$ sudo -u postgres psql
psql (15.10 (Ubuntu 15.10-1.pgdg20.04+1))
Type "help" for help.

postgres=# 
postgres=# \c db_otus_hw5
You are now connected to database "db_otus_hw5" as user "postgres".
db_otus_hw5=# \dt
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | test | table | postgres
(1 row)

db_otus_hw5=# select * from public.test ;
 c1 
----
 1
 2
 3
(3 rows)

db_otus_hw5=# 
```


## **Дополнительное задание**
   
### **Останавливаем postgres на VM db1 и отмонтируем внешний диск "data"**
```
yc-user@db1:~$ sudo -u postgres pg_ctlcluster 15 main stop
yc-user@db1:~$ 
yc-user@db1:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory    Log file
15  main    5432 down   postgres /mnt/data/15/main /var/log/postgresql/postgresql-15-main.log
yc-user@db1:~$ sudo bash
root@db1:/home/yc-user# vim /etc/fstab 
root@db1:/home/yc-user# umount /mnt/data
```

### **Отсоединяем диск "data" от VM db1**
```
[root@test2 hw-5]# yc compute instance detach-disk db1 --disk-name data
done (9s)
id: fhm47ougjd8b9c8j56lh
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T20:01:31Z"
name: db1
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm84e0mdgs3jera0pth
  auto_delete: true
  disk_id: fhm84e0mdgs3jera0pth
network_interfaces:
  - index: "0"
    mac_address: d0:0d:43:e3:d0:9b
    subnet_id: e9bsop830oeelmo13dmc
    primary_v4_address:
      address: 10.95.95.18
      one_to_one_nat:
        address: 51.250.7.50
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
    pci_topology: PCI_TOPOLOGY_V2
```

### **Создаем VM с именем db2**
```
[root@test2 hw-5]# yc compute instance create --name db2 --hostname db2 --cores 2 --memory 4 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub
done (34s)
id: fhm8b0lksmf4u68nnkpi
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T20:42:00Z"
name: db2
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm1o6feqflsr9v9h31j
  auto_delete: true
  disk_id: fhm1o6feqflsr9v9h31j
network_interfaces:
  - index: "0"
    mac_address: d0:0d:85:82:b4:e5
    subnet_id: e9bsop830oeelmo13dmc
    primary_v4_address:
      address: 10.95.95.13
      one_to_one_nat:
        address: 62.84.127.80
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: db2.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2

[root@test2 hw-5]# yc compute instance list
+----------------------+------+---------------+---------+--------------+-------------+
|          ID          | NAME |    ZONE ID    | STATUS  | EXTERNAL IP  | INTERNAL IP |
+----------------------+------+---------------+---------+--------------+-------------+
| fhm47ougjd8b9c8j56lh | db1  | ru-central1-a | RUNNING | 51.250.7.50  | 10.95.95.18 |
| fhm8b0lksmf4u68nnkpi | db2  | ru-central1-a | RUNNING | 62.84.127.80 | 10.95.95.13 |
+----------------------+------+---------------+---------+--------------+-------------+
```

### **Подключаем к VM db2 дополнительный диск "data"**
```
[root@test2 hw-5]# yc compute instance attach-disk db2 --disk-name data --mode rw
done (7s)
id: fhm8b0lksmf4u68nnkpi
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-08T20:42:00Z"
name: db2
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm1o6feqflsr9v9h31j
  auto_delete: true
  disk_id: fhm1o6feqflsr9v9h31j
secondary_disks:
  - mode: READ_WRITE
    device_name: fhmhov7h6d06tm1ki22o
    disk_id: fhmhov7h6d06tm1ki22o
network_interfaces:
  - index: "0"
    mac_address: d0:0d:85:82:b4:e5
    subnet_id: e9bsop830oeelmo13dmc
    primary_v4_address:
      address: 10.95.95.13
      one_to_one_nat:
        address: 62.84.127.80
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: db2.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
```

### **Подключаемся к VM db2 и устанавливаем postgres 15**
```
[root@test2 hw-5]# ssh yc-user@62.84.127.80 -i /home/voronov/.ssh/id_rsa
Warning: Permanently added '62.84.127.80' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/voronov/.ssh/id_rsa': 
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-200-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

yc-user@db2:~$ 
yc-user@db2:~$ sudo apt update && sudo apt upgrade -y -q && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-15
Hit:1 http://mirror.yandex.ru/ubuntu focal InRelease
Get:2 http://mirror.yandex.ru/ubuntu focal-updates InRelease [128 kB]
Get:3 http://mirror.yandex.ru/ubuntu focal-backports InRelease [128 kB]              
Get:4 http://security.ubuntu.com/ubuntu focal-security InRelease [128 kB]  
Get:5 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 Packages [3,681 kB]
Get:6 http://mirror.yandex.ru/ubuntu focal-updates/main i386 Packages [1,056 kB]
Get:7 http://mirror.yandex.ru/ubuntu focal-updates/restricted amd64 Packages [3,397 kB]    
Get:8 http://mirror.yandex.ru/ubuntu focal-updates/restricted i386 Packages [40.4 kB] 
Get:9 http://mirror.yandex.ru/ubuntu focal-updates/restricted Translation-en [474 kB]
Get:10 http://mirror.yandex.ru/ubuntu focal-updates/multiverse amd64 Packages [27.9 kB]
Get:11 http://mirror.yandex.ru/ubuntu focal-updates/multiverse Translation-en [7,968 B]
Get:12 http://security.ubuntu.com/ubuntu focal-security/main amd64 Packages [3,304 kB]
Get:13 http://security.ubuntu.com/ubuntu focal-security/main i386 Packages [835 kB]
Fetched 13.2 MB in 3s (3,815 kB/s)                        
Reading package lists... Done
Building dependency tree       
Reading state information... Done
All packages are up to date.
Reading package lists...
Building dependency tree...
Reading state information...
Calculating upgrade...
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main
OK
Hit:1 http://mirror.yandex.ru/ubuntu focal InRelease
Hit:2 http://mirror.yandex.ru/ubuntu focal-updates InRelease                                             
Hit:3 http://mirror.yandex.ru/ubuntu focal-backports InRelease                                           
Get:4 http://apt.postgresql.org/pub/repos/apt focal-pgdg InRelease [129 kB]                              
Hit:5 http://security.ubuntu.com/ubuntu focal-security InRelease                                         
Get:6 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 Packages [350 kB]
Fetched 480 kB in 1s (529 kB/s)   
Reading package lists... Done
N: Skipping acquire of configured file 'main/binary-i386/Packages' as repository 'http://apt.postgresql.org/pub/repos/apt focal-pgdg InRelease' doesn't support architecture 'i386'
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following additional packages will be installed:
  libcommon-sense-perl libgdbm-compat4 libio-pty-perl libipc-run-perl libjson-perl libjson-xs-perl libllvm10 libperl5.30 libpq5 libsensors-config libsensors5
  libtypes-serialiser-perl libxslt1.1 perl perl-modules-5.30 postgresql-client-15 postgresql-client-common postgresql-common ssl-cert sysstat
Suggested packages:
  lm-sensors perl-doc libterm-readline-gnu-perl | libterm-readline-perl-perl make libb-debug-perl liblocale-codes-perl postgresql-doc-15 openssl-blacklist isag
The following NEW packages will be installed:
  libcommon-sense-perl libgdbm-compat4 libio-pty-perl libipc-run-perl libjson-perl libjson-xs-perl libllvm10 libperl5.30 libpq5 libsensors-config libsensors5
  libtypes-serialiser-perl libxslt1.1 perl perl-modules-5.30 postgresql-15 postgresql-client-15 postgresql-client-common postgresql-common ssl-cert sysstat
0 upgraded, 21 newly installed, 0 to remove and 0 not upgraded.
Need to get 41.9 MB of archives.
After this operation, 188 MB of additional disk space will be used.
Get:1 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 perl-modules-5.30 all 5.30.0-9ubuntu0.5 [2,739 kB]
Get:2 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-client-common all 267.pgdg20.04+1 [95.1 kB]
Get:3 http://mirror.yandex.ru/ubuntu focal/main amd64 libgdbm-compat4 amd64 1.18.1-5 [6,244 B]  
Get:4 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libperl5.30 amd64 5.30.0-9ubuntu0.5 [3,941 kB]
Get:5 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-common all 267.pgdg20.04+1 [241 kB]
Get:6 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 perl amd64 5.30.0-9ubuntu0.5 [224 kB]
Get:7 http://mirror.yandex.ru/ubuntu focal/main amd64 libjson-perl all 4.02000-2 [80.9 kB]
Get:8 http://mirror.yandex.ru/ubuntu focal/main amd64 libio-pty-perl amd64 1:1.12-1 [32.4 kB]
Get:9 http://mirror.yandex.ru/ubuntu focal/main amd64 libipc-run-perl all 20180523.0-2 [89.7 kB]
Get:10 http://mirror.yandex.ru/ubuntu focal/main amd64 ssl-cert all 1.0.39 [17.0 kB]
Get:11 http://mirror.yandex.ru/ubuntu focal/main amd64 libcommon-sense-perl amd64 3.74-2build6 [20.1 kB]
Get:12 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 libpq5 amd64 17.2-1.pgdg20.04+1 [223 kB]
Get:13 http://mirror.yandex.ru/ubuntu focal/main amd64 libtypes-serialiser-perl all 1.0-1 [12.1 kB]
Get:14 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-client-15 amd64 15.10-1.pgdg20.04+1 [1,694 kB]
Get:15 http://mirror.yandex.ru/ubuntu focal/main amd64 libjson-xs-perl amd64 4.020-1build1 [83.7 kB]
Get:16 http://mirror.yandex.ru/ubuntu focal/main amd64 libllvm10 amd64 1:10.0.0-4ubuntu1 [15.3 MB]
Get:17 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-15 amd64 15.10-1.pgdg20.04+1 [16.5 MB]
Get:18 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libsensors-config all 1:3.6.0-2ubuntu1.1 [6,052 B]
Get:19 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libsensors5 amd64 1:3.6.0-2ubuntu1.1 [27.2 kB]
Get:20 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 libxslt1.1 amd64 1.1.34-4ubuntu0.20.04.1 [151 kB]
Get:21 http://mirror.yandex.ru/ubuntu focal-updates/main amd64 sysstat amd64 12.2.0-2ubuntu0.3 [448 kB]
Fetched 41.9 MB in 1s (53.1 MB/s)                                    
Preconfiguring packages ...
Selecting previously unselected package perl-modules-5.30.
(Reading database ... 102701 files and directories currently installed.)
Preparing to unpack .../00-perl-modules-5.30_5.30.0-9ubuntu0.5_all.deb ...
Unpacking perl-modules-5.30 (5.30.0-9ubuntu0.5) ...
Selecting previously unselected package libgdbm-compat4:amd64.
Preparing to unpack .../01-libgdbm-compat4_1.18.1-5_amd64.deb ...
Unpacking libgdbm-compat4:amd64 (1.18.1-5) ...
Selecting previously unselected package libperl5.30:amd64.
Preparing to unpack .../02-libperl5.30_5.30.0-9ubuntu0.5_amd64.deb ...
Unpacking libperl5.30:amd64 (5.30.0-9ubuntu0.5) ...
Selecting previously unselected package perl.
Preparing to unpack .../03-perl_5.30.0-9ubuntu0.5_amd64.deb ...
Unpacking perl (5.30.0-9ubuntu0.5) ...
Selecting previously unselected package libjson-perl.
Preparing to unpack .../04-libjson-perl_4.02000-2_all.deb ...
Unpacking libjson-perl (4.02000-2) ...
Selecting previously unselected package libio-pty-perl.
Preparing to unpack .../05-libio-pty-perl_1%3a1.12-1_amd64.deb ...
Unpacking libio-pty-perl (1:1.12-1) ...
Selecting previously unselected package libipc-run-perl.
Preparing to unpack .../06-libipc-run-perl_20180523.0-2_all.deb ...
Unpacking libipc-run-perl (20180523.0-2) ...
Selecting previously unselected package postgresql-client-common.
Preparing to unpack .../07-postgresql-client-common_267.pgdg20.04+1_all.deb ...
Unpacking postgresql-client-common (267.pgdg20.04+1) ...
Selecting previously unselected package ssl-cert.
Preparing to unpack .../08-ssl-cert_1.0.39_all.deb ...
Unpacking ssl-cert (1.0.39) ...
Selecting previously unselected package postgresql-common.
Preparing to unpack .../09-postgresql-common_267.pgdg20.04+1_all.deb ...
Adding 'diversion of /usr/bin/pg_config to /usr/bin/pg_config.libpq-dev by postgresql-common'
Unpacking postgresql-common (267.pgdg20.04+1) ...
Selecting previously unselected package libcommon-sense-perl.
Preparing to unpack .../10-libcommon-sense-perl_3.74-2build6_amd64.deb ...
Unpacking libcommon-sense-perl (3.74-2build6) ...
Selecting previously unselected package libtypes-serialiser-perl.
Preparing to unpack .../11-libtypes-serialiser-perl_1.0-1_all.deb ...
Unpacking libtypes-serialiser-perl (1.0-1) ...
Selecting previously unselected package libjson-xs-perl.
Preparing to unpack .../12-libjson-xs-perl_4.020-1build1_amd64.deb ...
Unpacking libjson-xs-perl (4.020-1build1) ...
Selecting previously unselected package libllvm10:amd64.
Preparing to unpack .../13-libllvm10_1%3a10.0.0-4ubuntu1_amd64.deb ...
Unpacking libllvm10:amd64 (1:10.0.0-4ubuntu1) ...
Selecting previously unselected package libpq5:amd64.
Preparing to unpack .../14-libpq5_17.2-1.pgdg20.04+1_amd64.deb ...
Unpacking libpq5:amd64 (17.2-1.pgdg20.04+1) ...
Selecting previously unselected package libsensors-config.
Preparing to unpack .../15-libsensors-config_1%3a3.6.0-2ubuntu1.1_all.deb ...
Unpacking libsensors-config (1:3.6.0-2ubuntu1.1) ...
Selecting previously unselected package libsensors5:amd64.
Preparing to unpack .../16-libsensors5_1%3a3.6.0-2ubuntu1.1_amd64.deb ...
Unpacking libsensors5:amd64 (1:3.6.0-2ubuntu1.1) ...
Selecting previously unselected package libxslt1.1:amd64.
Preparing to unpack .../17-libxslt1.1_1.1.34-4ubuntu0.20.04.1_amd64.deb ...
Unpacking libxslt1.1:amd64 (1.1.34-4ubuntu0.20.04.1) ...
Selecting previously unselected package postgresql-client-15.
Preparing to unpack .../18-postgresql-client-15_15.10-1.pgdg20.04+1_amd64.deb ...
Unpacking postgresql-client-15 (15.10-1.pgdg20.04+1) ...
Selecting previously unselected package postgresql-15.
Preparing to unpack .../19-postgresql-15_15.10-1.pgdg20.04+1_amd64.deb ...
Unpacking postgresql-15 (15.10-1.pgdg20.04+1) ...
Selecting previously unselected package sysstat.
Preparing to unpack .../20-sysstat_12.2.0-2ubuntu0.3_amd64.deb ...
Unpacking sysstat (12.2.0-2ubuntu0.3) ...
Setting up perl-modules-5.30 (5.30.0-9ubuntu0.5) ...
Setting up libsensors-config (1:3.6.0-2ubuntu1.1) ...
Setting up libpq5:amd64 (17.2-1.pgdg20.04+1) ...
Setting up libllvm10:amd64 (1:10.0.0-4ubuntu1) ...
Setting up ssl-cert (1.0.39) ...
Setting up libgdbm-compat4:amd64 (1.18.1-5) ...
Setting up libsensors5:amd64 (1:3.6.0-2ubuntu1.1) ...
Setting up libxslt1.1:amd64 (1.1.34-4ubuntu0.20.04.1) ...
Setting up libperl5.30:amd64 (5.30.0-9ubuntu0.5) ...
Setting up sysstat (12.2.0-2ubuntu0.3) ...

Creating config file /etc/default/sysstat with new version
update-alternatives: using /usr/bin/sar.sysstat to provide /usr/bin/sar (sar) in auto mode
Created symlink /etc/systemd/system/multi-user.target.wants/sysstat.service → /lib/systemd/system/sysstat.service.
Setting up perl (5.30.0-9ubuntu0.5) ...
Setting up libjson-perl (4.02000-2) ...
Setting up libio-pty-perl (1:1.12-1) ...
Setting up libcommon-sense-perl (3.74-2build6) ...
Setting up libipc-run-perl (20180523.0-2) ...
Setting up libtypes-serialiser-perl (1.0-1) ...
Setting up postgresql-client-common (267.pgdg20.04+1) ...
Setting up libjson-xs-perl (4.020-1build1) ...
Setting up postgresql-client-15 (15.10-1.pgdg20.04+1) ...
update-alternatives: using /usr/share/postgresql/15/man/man1/psql.1.gz to provide /usr/share/man/man1/psql.1.gz (psql.1.gz) in auto mode
Setting up postgresql-common (267.pgdg20.04+1) ...
Adding user postgres to group ssl-cert

Creating config file /etc/postgresql-common/createcluster.conf with new version
Building PostgreSQL dictionaries from installed myspell/hunspell packages...
Removing obsolete dictionary files:
'/etc/apt/trusted.gpg.d/apt.postgresql.org.gpg' -> '/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg'
Created symlink /etc/systemd/system/multi-user.target.wants/postgresql.service → /lib/systemd/system/postgresql.service.
Setting up postgresql-15 (15.10-1.pgdg20.04+1) ...
Creating new PostgreSQL cluster 15/main ...
/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/main --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/15/main ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Processing triggers for systemd (245.4-4ubuntu3.24) ...
Processing triggers for man-db (2.9.1-1) ...
Processing triggers for libc-bin (2.31-0ubuntu9.16) ...
```

### **Останавливаем postgres на VM db2**
```
yc-user@db2:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
yc-user@db2:~$ 
yc-user@db2:~$ sudo -u postgres pg_ctlcluster 15 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@15-main
```

### **Монтируем диск "data" в директорию "/var/lib/postgresql/"**
```
yc-user@db2:~$ sudo bash
root@db2:/home/yc-user# lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda    252:0    0  10G  0 disk 
├─vda1 252:1    0   1M  0 part 
└─vda2 252:2    0  10G  0 part /
vdb    252:16   0  10G  0 disk 
root@db2:/home/yc-user# blkid 
/dev/vda2: UUID="be2c7c06-cc2b-4d4b-96c6-e3700932b129" TYPE="ext4" PARTUUID="634e05c7-9520-4e9b-bcdb-3329603f1b2c"
/dev/vda1: PARTUUID="c111767e-981d-4e57-85a0-ac66da561517"
/dev/vdb: UUID="b9e73052-c876-45b1-b682-f30dd70bda22" TYPE="ext4"

root@db2:/home/yc-user# vim /etc/fstab 
root@db2:/home/yc-user# grep b9e73052-c876-45b1-b682-f30dd70bda22 /etc/fstab 
UUID="b9e73052-c876-45b1-b682-f30dd70bda22"  /var/lib/postgresql/  ext4    defaults  0  0
root@db2:/home/yc-user# mount /var/lib/postgresql/
root@db2:/home/yc-user# ls -al /var/lib/postgresql/
total 28
drwxr-xr-x  4 postgres postgres  4096 Dec  8 20:31 .
drwxr-xr-x 37 root     root      4096 Dec  8 20:45 ..
drwxr-xr-x  3 postgres postgres  4096 Dec  8 20:12 15
drwx------  2 postgres postgres 16384 Dec  8 20:24 lost+found
```

### **Стартуем postgres и проверяем доступность данных в таблице "test"**
```
root@db2:/home/yc-user# sudo -u postgres pg_ctlcluster 15 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@15-main
root@db2:/home/yc-user# sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@db2:/home/yc-user# 
root@db2:/home/yc-user# sudo -u psql
sudo: unknown user: psql
sudo: unable to initialize policy plugin
root@db2:/home/yc-user# sudo -u postgres psql
psql (15.10 (Ubuntu 15.10-1.pgdg20.04+1))
Type "help" for help.

postgres=# \c db_otus_hw5
You are now connected to database "db_otus_hw5" as user "postgres".
db_otus_hw5=# \dt
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | test | table | postgres
(1 row)

db_otus_hw5=# select * from public.test
db_otus_hw5-# ;
 c1 
----
 1
 2
 3
(3 rows)

db_otus_hw5=#
```
Данные доступны 


### **Удаляем из ЯО все созданные ранее ресурсы**
```
[root@test2 hw-5]# yc compute instance delete --name db1
done (52s)
[root@test2 hw-5]# yc compute instance delete --name db2
done (52s)
[root@test2 hw-5]# yc compute disk delete --name data
done (17s)
[root@test2 hw-5]# yc vpc subnet delete --name otus-subnet
done (2s)
[root@test2 hw-5]# yc vpc network delete --name "otus-net"
```
