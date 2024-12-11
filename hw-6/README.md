# **HW-6 | Бэкапы Постгреса**


## **Цель:**
Используем современные решения для бэкапов


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
- Делаем бэкап Постгреса используя WAL-G или pg_probackup и восстанавливаемся на другом кластере
- Задание повышенной сложности*  
  под нагрузкой*  
  бэкап снимаем с реплики**  


## **Выполнение ДЗ**
    
### **Поднимаем виртуальные машины**

  В качестве инструмента виртуализации будем использовать **vagrant**.  
  Создаем **Vagrantfile**, где опишем параметры VM, а также опишем скрипт для установки postgres-14
```
[root@test2 hw-6]# vagrant up ^C

[root@test2 hw-6]# vagrant status
Current machine states:

pgsql1                    running (virtualbox)
pgsql2                    running (virtualbox)
```
в итоге получили две VM c IP адресами 192.168.60.51 и 192.168.60.52

### **Проверяем, что postgres установлен на обоих нодах**
```
[root@test2 hw-6]# vagrant ssh pgsql1 -- sudo pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
[root@test2 hw-6]# 

[root@test2 hw-6]# vagrant ssh pgsql2 -- sudo pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```

Вторую ноду мы будем использовать для хранения бекапа, а также для поднятия реплики, поэтому на тек. момент   
стопаем инстанс postgres на ней:
```
[root@test2 hw-6]# vagrant ssh pgsql2 -- sudo pg_ctlcluster 14 main stop

[root@test2 hw-6]# vagrant ssh pgsql2 -- sudo pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 down   postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```

### **На обоих нодах устанавливаем pg-probackup**
```
vagrant@pgsql1:~$ wget -O - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP | sudo apt-key add -
vagrant@pgsql1:~$ sudo sh -c 'echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ $(lsb_release -cs) main-$(lsb_release -cs)" > /etc/apt/sources.list.d/pg_probackup.list'
vagrant@pgsql1:~$ sudo apt-get update && sudo apt-get install pg-probackup-14
vagrant@pgsql2:~$ sudo ln -s /usr/bin/pg_probackup-14 /usr/bin/pg_probackup
```

Проверяем установку pg_probackup
```
[root@test2 hw-6]# vagrant ssh pgsql1 -- pg_probackup --version
pg_probackup 2.5.15 (PostgreSQL 14.11)
[root@test2 hw-6]# vagrant ssh pgsql2 -- pg_probackup --version
pg_probackup 2.5.15 (PostgreSQL 14.11)
```

### **Конфигурируем интерконнект между нашими двумя нодами по протоколу ssh**  
Для этого, с помощью **ssh-keygen**, генерируем на каждой ноде ssh ключ и затем публичную часть ключа сохраняем   
в файле **/var/lib/postgresql/.ssh/authorized_keys** на ноде соседе

Проверка интерконнекта
```
[root@test2 hw-6]# vagrant ssh pgsql1 -- sudo -u postgres ssh 192.168.60.52 hostname
pgsql2
[root@test2 hw-6]# vagrant ssh pgsql2 -- sudo -u postgres ssh 192.168.60.51 hostname
pgsql1
```

### **Конфигурируем postgres**
В настройки postgres на VM pgsql1 добавляем опции
```
listen_addresses = '0.0.0.0'
wal_level = replica
```

Затем рестартуем кластер и проверяем настройки
```
root@pgsql1:/home/vagrant# pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
 
root@pgsql1:/home/vagrant# pg_ctlcluster 14  main restart
 
root@pgsql1:/home/vagrant# su - postgres
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# show wal_l
wal_level      wal_log_hints  
postgres=# show wal_level ;
 wal_level 
-----------
 replica
(1 row)

postgres=# show listen_addresses ;
 listen_addresses 
------------------
 0.0.0.0
(1 row)
```

Добавляем пользователя под которым будем создавать backup в pg_hba.conf
```
host    replication     backup          192.168.60.0/24         scram-sha-256
host    all             all             192.168.60.0/24         scram-sha-256
```

и после этого релоадим postgres
```
root@pgsql1:/home/vagrant# pg_ctlcluster 14  main reload
```

### **Создаем выделенную БД для pg_probackup**
Согласно доке:
```
Хотя pg_probackup можно использовать от имени суперпользователя,   
рекомендуется создать отдельную роль с минимальными правами,   
необходимыми для выбранной стратегии копирования.
Из соображений безопасности для выполнения следующих конфигурационных   
SQL-запросов рекомендуется использовать отдельную базу данных.
```

Создаем отдельную БД backupdb и роль backupdb:
```
postgres=# CREATE DATABASE backupdb;
postgres=# \c backupdb

BEGIN;
CREATE ROLE backup WITH LOGIN;
GRANT USAGE ON SCHEMA pg_catalog TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.current_setting(text) TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.set_config(text, text, boolean) TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_is_in_recovery() TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_start_backup(text, boolean, boolean) TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_stop_backup(boolean, boolean) TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_create_restore_point(text) TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_switch_wal() TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_last_wal_replay_lsn() TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.txid_current() TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.txid_current_snapshot() TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.txid_snapshot_xmax(txid_snapshot) TO backup;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_control_checkpoint() TO backup;
COMMIT;
ALTER USER backup WITH REPLICATION;
alter user backup with password '######';
```

### **Настраиваем беспарольный доступ**
Для беспарольного подключения от pgsql2 до pgsql1 в домашней директории postgres создаем файл:
```
postgres@pgsql1:~$ cat ~/.pgpass
192.168.60.51:*:*:backup:######

postgres@pgsql1:~$ chmod 600 /var/lib/postgresql/.pgpass
```

Проверяем беспарольный доступ
```
postgres@pgsql2:~$ psql -h 192.168.60.51 -U backup backupdb
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

backupdb=> 
```

### **Подготовка и инициализация инстанса pg_probackup**
Создаем отдельную директорию для хранения бекапов, затем инициализируем и конфигурируем pg_probackup.
```
root@pgsql2:/home/vagrant# mkdir -p /data/pg_probackup
root@pgsql2:/home/vagrant# chown postgres:postgres /data/pg_probackup

root@pgsql2:/home/vagrant# su - postgres
postgres@pgsql2:~$ 
postgres@pgsql2:~$ pg_probackup init -B /data/pg_probackup/otus
INFO: Backup catalog '/data/pg_probackup/otus' successfully initialized

postgres@pgsql2:~$ pg_probackup add-instance --instance=db1 -B /data/pg_probackup/otus --remote-host=192.168.60.51 --remote-user=postgres --pgdata=/var/lib/postgresql/14/main
INFO: Instance 'db1' successfully initialized

postgres@pgsql2:~$ pg_probackup set-config --instance=db1 --retention-window=7 --retention-redundancy=2 -B /data/pg_probackup/otus
```

### **Создание FULL бэкапа**
Создаем первый FULL backup
```
postgres@pgsql2:~$ pg_probackup backup -B /data/pg_probackup/otus --instance=db1 -b FULL --stream --remote-host=192.168.60.51 --remote-user=postgres -U backup -d backupdb
INFO: Backup start, pg_probackup version: 2.5.15, instance: db1, backup ID: SOAW6O, backup mode: FULL, wal mode: STREAM, remote: true, compress-algorithm: none, compress-level: 1
WARNING: This PostgreSQL instance was initialized without data block checksums. pg_probackup have no way to detect data block corruption without them. Reinitialize PGDATA with option '--data-checksums'.
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Wait for WAL segment /data/pg_probackup/otus/backups/db1/SOAW6O/database/pg_wal/000000010000000000000002 to be streamed
INFO: PGDATA size: 33MB
INFO: Current Start LSN: 0/2000028, TLI: 1
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 2s
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/2001E88
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 1s
INFO: Validating backup SOAW6O
INFO: Backup SOAW6O data files are valid
INFO: Backup SOAW6O resident size: 50MB
INFO: Backup SOAW6O completed
```

Проверяем что бекап успешно создался:
```
postgres@pgsql2:~$ pg_probackup show -B /data/pg_probackup/otus

BACKUP INSTANCE 'db1'
================================================================================================================================
 Instance  Version  ID      Recovery Time           Mode  WAL Mode  TLI  Time  Data   WAL  Zratio  Start LSN  Stop LSN   Status 
================================================================================================================================
 db1       14       SOAW6O  2024-12-10 23:06:27+00  FULL  STREAM    1/0   11s  34MB  16MB    1.00  0/2000028  0/2001E88  OK   
```


### **Создание тестовой таблицы для проверки бэкапа**
Для тестирования восстановления из бэкапа, создадим тестовую таблицу:
```
root@pgsql1:/home/vagrant# su - postgres
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# create table persons(id serial, first_name text, second_name text);
CREATE TABLE
postgres=# insert into persons(first_name, second_name) values('ivan', 'ivanov');
INSERT 0 1
postgres=# insert into persons(first_name, second_name) values('petr', 'petrov');
INSERT 0 1
postgres=# insert into persons(first_name, second_name) values('alex', 'vtorov');
INSERT 0 1
postgres=#
```

### **Создаем DELTA бэкап**
После этого на создадим DELTA бэкеп:
```
postgres@pgsql2:~$ pg_probackup backup -B /data/pg_probackup/otus --instance=db1 -b DELTA --stream --remote-host=192.168.60.51 --remote-user=postgres -U backup -d backupdb
INFO: Backup start, pg_probackup version: 2.5.15, instance: db1, backup ID: SOAWOG, backup mode: DELTA, wal mode: STREAM, remote: true, compress-algorithm: none, compress-level: 1
WARNING: This PostgreSQL instance was initialized without data block checksums. pg_probackup have no way to detect data block corruption without them. Reinitialize PGDATA with option '--data-checksums'.
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Parent backup: SOAW6O
INFO: Wait for WAL segment /data/pg_probackup/otus/backups/db1/SOAWOG/database/pg_wal/000000010000000000000004 to be streamed
INFO: PGDATA size: 42MB
INFO: Current Start LSN: 0/4000028, TLI: 1
INFO: Parent Start LSN: 0/2000028, TLI: 1
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 2s
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/40001A0
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 0
INFO: Validating backup SOAWOG
INFO: Backup SOAWOG data files are valid
INFO: Backup SOAWOG resident size: 25MB
INFO: Backup SOAWOG completed
postgres@pgsql2:~$ 
postgres@pgsql2:~$ pg_probackup show -B /data/pg_probackup/otus

BACKUP INSTANCE 'db1'
===================================================================================================================================
 Instance  Version  ID      Recovery Time           Mode   WAL Mode  TLI  Time    Data   WAL  Zratio  Start LSN  Stop LSN   Status 
===================================================================================================================================
 db1       14       SOAWOG  2024-12-10 23:17:08+00  DELTA  STREAM    1/1   11s  8979kB  16MB    1.00  0/4000028  0/40001A0  OK     
 db1       14       SOAW6O  2024-12-10 23:06:27+00  FULL   STREAM    1/0   11s    34MB  16MB    1.00  0/2000028  0/2001E88  OK   
```

### **Проверка восстановление из бэкапа**
Останавливаем кластер postgres на pgsql1 и удаляем содержимое директории "/var/lib/postgresql/14/main/":
```
root@pgsql1:/home/vagrant# pg_ctlcluster 14  main stop
root@pgsql1:/home/vagrant# pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 down   postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

root@pgsql1:/home/vagrant# rm -rf /var/lib/postgresql/14/main/*
```

Восстанавливаем удаленную БД на pgsql1, использую последний DELTA бэкап:
```
postgres@pgsql2:~$ pg_probackup restore --instance=db1 -i SOAWOG -B /data/pg_probackup/otus --remote-host=192.168.60.51 --remote-user=postgres --pgdata=/var/lib/postgresql/14/main
INFO: Validating parents for backup SOAWOG
INFO: Validating backup SOAW6O
INFO: Backup SOAW6O data files are valid
INFO: Validating backup SOAWOG
INFO: Backup SOAWOG data files are valid
INFO: Backup SOAWOG WAL segments are valid
INFO: Backup SOAWOG is valid.
INFO: Restoring the database from backup SOAWOG on 192.168.60.51
INFO: Start restoring backup files. PGDATA size: 58MB
INFO: Backup files are restored. Transfered bytes: 58MB, time elapsed: 3s
INFO: Restore incremental ratio (less is better): 100% (58MB/58MB)
INFO: Syncing restored files to disk
INFO: Restored backup files are synced, time elapsed: 5s
INFO: Restore of backup SOAWOG completed.
```

Заходим на ноду pgsql1 и проверяем что файлы БД появились:
```
root@pgsql1:/home/vagrant# ls -al  /var/lib/postgresql/14/main/
total 88
drwx------ 19 postgres postgres 4096 Dec 10 23:26 .
drwxr-xr-x  3 postgres postgres 4096 Dec 10 21:23 ..
-rw-rw-r--  1 postgres postgres  240 Dec 10 23:26 backup_label
drwx------  7 postgres postgres 4096 Dec 10 23:26 base
drwx------  2 postgres postgres 4096 Dec 10 23:26 global
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_commit_ts
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_dynshmem
drwx------  4 postgres postgres 4096 Dec 10 23:26 pg_logical
drwx------  4 postgres postgres 4096 Dec 10 23:26 pg_multixact
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_notify
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_replslot
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_serial
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_snapshots
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_stat
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_stat_tmp
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_subtrans
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_tblspc
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_twophase
-rw-------  1 postgres postgres    3 Dec 10 23:26 PG_VERSION
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_wal
drwx------  2 postgres postgres 4096 Dec 10 23:26 pg_xact
-rw-------  1 postgres postgres  184 Dec 10 23:26 postgresql.auto.conf
```

Затем стартуем БД и проверяем тестовую таблицу:
```
root@pgsql1:/home/vagrant# ls -al  /var/lib/postgresql/14/main/*^C
root@pgsql1:/home/vagrant# pg_ctlcluster 14  main start
root@pgsql1:/home/vagrant# su - postgres
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# \dt
          List of relations
 Schema |  Name   | Type  |  Owner   
--------+---------+-------+----------
 public | persons | table | postgres
(1 row)

postgres=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | alex       | vtorov
(3 rows)

postgres=#
```

Как видим все данные на месте



## **Проверка создания бэкапа под нагрузкой**

### **Создаем отдельную БД для pgbench и инициализируем его в ней**
```
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# CREATE DATABASE bench;
CREATE DATABASE
postgres=# \q

postgres@pgsql1:~$ pgbench -i bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.13 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.46 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.24 s, vacuum 0.11 s, primary keys 0.10 s).
```

### **Запускаем pgbench и в отдельной консоли проверяем что нагрузка на БД появилась**
```
postgres@pgsql1:~$ pgbench bench -c 52 -j 26 -T 600
pgbench (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
starting vacuum...end.
```

Проверка нагрузки
```
root@pgsql1:/home/vagrant# su - postgres
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# select pid as process_id, 
       usename as username, 
       datname as database_name, 
       client_addr as client_address, 
       application_name,
       backend_start,
       state,
       state_change
from pg_stat_activity limit 20;
 process_id | username | database_name | client_address | application_name |         backend_start         |        state        |         state_change          
------------+----------+---------------+----------------+------------------+-------------------------------+---------------------+-------------------------------
      12761 | postgres |               |                |                  | 2024-12-10 23:28:34.094186+00 |                     | 
      12759 |          |               |                |                  | 2024-12-10 23:28:34.094991+00 |                     | 
      13261 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.820852+00 | active              | 2024-12-10 23:47:11.908406+00
      13265 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.821874+00 | active              | 2024-12-10 23:47:11.942345+00
      13263 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.822347+00 | active              | 2024-12-10 23:47:11.940574+00
      13262 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.823284+00 | active              | 2024-12-10 23:47:11.853983+00
      13264 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.823702+00 | active              | 2024-12-10 23:47:11.94563+00
      13267 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.825495+00 | active              | 2024-12-10 23:47:11.90829+00
      13272 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.826899+00 | active              | 2024-12-10 23:47:11.91095+00
      13268 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.826919+00 | active              | 2024-12-10 23:47:11.949286+00
      13269 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.827525+00 | active              | 2024-12-10 23:47:11.94591+00
      13271 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.828619+00 | active              | 2024-12-10 23:47:11.949442+00
      13273 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.831004+00 | active              | 2024-12-10 23:47:11.653772+00
      13274 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.832616+00 | active              | 2024-12-10 23:47:11.936445+00
      13266 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.82657+00  | active              | 2024-12-10 23:47:11.861353+00
      13270 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.834592+00 | active              | 2024-12-10 23:47:11.878034+00
      13280 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.836074+00 | idle in transaction | 2024-12-10 23:47:11.949663+00
      13285 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.837576+00 | active              | 2024-12-10 23:47:11.935716+00
      13290 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.839118+00 | active              | 2024-12-10 23:47:11.883781+00
      13278 | postgres | bench         |                | pgbench          | 2024-12-10 23:43:45.839732+00 | active              | 2024-12-10 23:47:11.945305+00
(20 rows)

postgres=#
```

### **Создаем новую запись в таблице persons**
```
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# insert into persons(first_name, second_name) values('bar', 'foo');
INSERT 0 1
postgres=# 
```

### **Пробуем запустить FULL бэкап**
```
postgres@pgsql2:~$ pg_probackup backup -B /data/pg_probackup/otus --instance=db1 -b FULL --stream --remote-host=192.168.60.51 --remote-user=postgres -U backup -d backupdb
INFO: Backup start, pg_probackup version: 2.5.15, instance: db1, backup ID: SOAY7W, backup mode: FULL, wal mode: STREAM, remote: true, compress-algorithm: none, compress-level: 1
WARNING: This PostgreSQL instance was initialized without data block checksums. pg_probackup have no way to detect data block corruption without them. Reinitialize PGDATA with option '--data-checksums'.
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Wait for WAL segment /data/pg_probackup/otus/backups/db1/SOAY7W/database/pg_wal/00000001000000000000001B to be streamed
INFO: PGDATA size: 80MB
INFO: Current Start LSN: 0/1B000130, TLI: 1
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 3s
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/1BC1D4A8
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 2s
INFO: Validating backup SOAY7W
INFO: Backup SOAY7W data files are valid
INFO: Backup SOAY7W resident size: 112MB
INFO: Backup SOAY7W completed

postgres@pgsql2:~$ pg_probackup show -B /data/pg_probackup/otus

BACKUP INSTANCE 'db1'
=====================================================================================================================================
 Instance  Version  ID      Recovery Time           Mode   WAL Mode  TLI  Time    Data   WAL  Zratio  Start LSN   Stop LSN    Status 
=====================================================================================================================================
 db1       14       SOAY7W  2024-12-10 23:50:25+00  FULL   STREAM    1/0    8s    80MB  32MB    1.00  0/1B000130  0/1BC1D4A8  OK     
 db1       14       SOAWOG  2024-12-10 23:17:08+00  DELTA  STREAM    1/1   11s  8979kB  16MB    1.00  0/4000028   0/40001A0   OK     
 db1       14       SOAW6O  2024-12-10 23:06:27+00  FULL   STREAM    1/0   11s    34MB  16MB    1.00  0/2000028   0/2001E88   OK    
```
Бекап собрался успешно ( т.к. мы запускаем с опцией **--stream** )

### **Останавливаем postgres на pgsql1 и удаляем директорию с данными**
```
root@pgsql1:/home/vagrant# pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
 
root@pgsql1:/home/vagrant# pg_ctlcluster 14  main stop

root@pgsql1:/home/vagrant# pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 down   postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

root@pgsql1:/home/vagrant# rm -rf /var/lib/postgresql/14/main/*
root@pgsql1:/home/vagrant# ls -al /var/lib/postgresql/14/main/
total 8
drwx------ 2 postgres postgres 4096 Dec 10 23:53 .
drwxr-xr-x 3 postgres postgres 4096 Dec 10 21:23 ..
root@pgsql1:/home/vagrant#
```

### **Запускаем восстановление из бекапа**
```
postgres@pgsql2:~$ pg_probackup restore --instance=db1 -i SOAY7W -B /data/pg_probackup/otus --remote-host=192.168.60.51 --remote-user=postgres --pgdata=/var/lib/postgresql/14/main
INFO: Validating backup SOAY7W
INFO: Backup SOAY7W data files are valid
INFO: Backup SOAY7W WAL segments are valid
INFO: Backup SOAY7W is valid.
INFO: Restoring the database from backup SOAY7W on 192.168.60.51
INFO: Start restoring backup files. PGDATA size: 112MB
INFO: Backup files are restored. Transfered bytes: 112MB, time elapsed: 4s
INFO: Restore incremental ratio (less is better): 100% (112MB/112MB)
INFO: Syncing restored files to disk
INFO: Restored backup files are synced, time elapsed: 4s
INFO: Restore of backup SOAY7W completed.
```

### **Запускаем postgres на pgsql1 и проверяем данные**
```
root@pgsql1:/home/vagrant# pg_ctlcluster 14  main start
root@pgsql1:/home/vagrant# pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

root@pgsql1:/home/vagrant# su - postgres
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | alex       | vtorov
  4 | bar        | foo
(4 rows)

postgres=#
```
Данные на месте



## **Снятие бэкапа с реплики**

### **Инициализируем инстанс реплики в pg_probackup**
```
postgres@pgsql2:~$ pg_probackup add-instance --instance=replica -B /data/pg_probackup/otus --remote-host=192.168.60.52 --remote-user=postgres --pgdata=/var/lib/postgresql/14/main
```

### **Добавляем запись для реплики в ~/.pgpass**
```
postgres@pgsql2:~$ cat ~/.pgpass
192.168.60.51:*:*:backup:######
192.168.60.52:*:*:backup:######
```

### **Поднимаем реплику на pgsql2**
```
postgres@pgsql2:~$ rm -rf /var/lib/postgresql/14/main/

postgres@pgsql2:~$ pg_basebackup -h 192.168.60.51 -U backup -X stream -C -S replica1 -v -R -D /var/lib/postgresql/14/main/
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 0/20000028 on timeline 1
pg_basebackup: starting background WAL receiver
pg_basebackup: created replication slot "replica1"
pg_basebackup: write-ahead log end point: 0/20000100
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: syncing data to disk ...
pg_basebackup: renaming backup_manifest.tmp to backup_manifest
pg_basebackup: base backup completed
```

### **Переносим кастомные конфиг postgres.conf и pg_hba.conf из pgsql1 и затем запускаем postgres на реплике** 
( т.к. нагрузки на pgsql1 у нас пока нет, то и wal-ы с мастера нам не требуются, в реальной жизни нужно конфигурировать опцию recovery ) 
```
root@pgsql2:/home/vagrant# pg_ctlcluster 14  main start
root@pgsql2:/home/vagrant# pg_lsclusters 
Ver Cluster Port Status          Owner    Data directory              Log file
14  main    5432 online,recovery postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```

### **Проверяем статус реплики**
```
postgres@pgsql2:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# \x
Expanded display is on.
postgres=# select * from pg_stat_wal_receiver;
-[ RECORD 1 ]---------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pid                   | 12169
status                | streaming
receive_start_lsn     | 0/2C000000
receive_start_tli     | 1
written_lsn           | 0/357E4668
flushed_lsn           | 0/357E4668
received_tli          | 1
last_msg_send_time    | 2024-12-11 08:40:02.22596+00
last_msg_receipt_time | 2024-12-11 08:40:02.224914+00
latest_end_lsn        | 0/357E4668
latest_end_time       | 2024-12-11 08:40:02.22596+00
slot_name             | replica1
sender_host           | 192.168.60.51
sender_port           | 5432
conninfo              | user=backup passfile=/var/lib/postgresql/.pgpass channel_binding=prefer dbname=replication host=192.168.60.51 port=5432 fallback_application_name=14/main sslmode=prefer sslnegotiation=postgres sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable

postgres=# 
postgres=# select * from pg_stat_wal_receiver;
-[ RECORD 1 ]---------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pid                   | 12169
status                | streaming
receive_start_lsn     | 0/2C000000
receive_start_tli     | 1
written_lsn           | 0/358D0000
flushed_lsn           | 0/358D0000
received_tli          | 1
last_msg_send_time    | 2024-12-11 08:40:04.193683+00
last_msg_receipt_time | 2024-12-11 08:40:04.192671+00
latest_end_lsn        | 0/358D0000
latest_end_time       | 2024-12-11 08:40:04.193683+00
slot_name             | replica1
sender_host           | 192.168.60.51
sender_port           | 5432
conninfo              | user=backup passfile=/var/lib/postgresql/.pgpass channel_binding=prefer dbname=replication host=192.168.60.51 port=5432 fallback_application_name=14/main sslmode=prefer sslnegotiation=postgres sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable

postgres=# 
```

### **Запускаем на pgsql1 нагрузку, а также создаем новую запись в таблице persons**
```
postgres@pgsql1:~$ pgbench bench -c 50 -j 2 -P 60 -T 300
pgbench (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
starting vacuum...end.
progress: 60.0 s, 942.9 tps, lat 52.879 ms stddev 55.300
progress: 120.0 s, 937.3 tps, lat 53.286 ms stddev 59.204
progress: 180.0 s, 923.0 tps, lat 54.082 ms stddev 62.502
```

```
postgres@pgsql1:~$ psql 
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# insert into persons(first_name, second_name) values('bar2', 'foo2');
INSERT 0 1
postgres=# 
```

### **Запускаем создание бэкапа и проверяем что он создался**
```
postgres@pgsql2:~$ pg_probackup backup -B /data/pg_probackup/otus --instance=replica -b FULL --stream --remote-host=192.168.60.52 --remote-user=postgres -U backup -d backupdb
INFO: Backup start, pg_probackup version: 2.5.15, instance: replica, backup ID: SOBNA2, backup mode: FULL, wal mode: STREAM, remote: true, compress-algorithm: none, compress-level: 1
WARNING: This PostgreSQL instance was initialized without data block checksums. pg_probackup have no way to detect data block corruption without them. Reinitialize PGDATA with option '--data-checksums'.
INFO: Backup SOBNA2 is going to be taken from standby
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Wait for WAL segment /data/pg_probackup/otus/backups/replica/SOBNA2/database/pg_wal/000000010000000000000039 to be streamed
INFO: PGDATA size: 62MB
INFO: Current Start LSN: 0/3968D238, TLI: 1
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 2s
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/3E2EFA78
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 2s
INFO: Validating backup SOBNA2
INFO: Backup SOBNA2 data files are valid
INFO: Backup SOBNA2 resident size: 158MB
INFO: Backup SOBNA2 completed

postgres@pgsql2:~$ pg_probackup show -B /data/pg_probackup/otus

BACKUP INSTANCE 'db1'
=====================================================================================================================================
 Instance  Version  ID      Recovery Time           Mode   WAL Mode  TLI  Time    Data   WAL  Zratio  Start LSN   Stop LSN    Status 
=====================================================================================================================================
 db1       14       SOAY7W  2024-12-10 23:50:25+00  FULL   STREAM    1/0    8s    80MB  32MB    1.00  0/1B000130  0/1BC1D4A8  OK     
 db1       14       SOAWOG  2024-12-10 23:17:08+00  DELTA  STREAM    1/1   11s  8979kB  16MB    1.00  0/4000028   0/40001A0   OK     
 db1       14       SOAW6O  2024-12-10 23:06:27+00  FULL   STREAM    1/0   11s    34MB  16MB    1.00  0/2000028   0/2001E88   OK     

BACKUP INSTANCE 'replica'
==================================================================================================================================
 Instance  Version  ID      Recovery Time           Mode  WAL Mode  TLI  Time  Data   WAL  Zratio  Start LSN   Stop LSN    Status 
==================================================================================================================================
 replica   14       SOBNA2  2024-12-11 08:51:42+00  FULL  STREAM    1/0    8s  62MB  96MB    1.00  0/3968D238  0/3E2EFA78  OK     
```
