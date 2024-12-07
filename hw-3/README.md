# **HW-3 | Использование Managed Service for PostgreSQL**


## **Цель:**
Получить базовые навыки подключения и работы с базой данных через клиентское приложение


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Создайте кластер PostgreSQL с использованием Managed Service for PostgreSQL в Yandex.Cloud.  
Укажите минимально необходимые параметры: версия PostgreSQL, количество ресурсов (например, 1 ядро CPU и 1 ГБ памяти).  
Настройте доступ: разрешите доступ с вашего IP-адреса.  
Подключитесь к базе данных через psql или любой другой клиент.  


## **Выполнение ДЗ**

### **Скачиваем и устанавливаем утилиту _yc_ **
```
[root@test2 hw-3]# curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
Downloading yc 0.140.0
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 94.7M  100 94.7M    0     0   9.7M      0  0:00:09  0:00:09 --:--:-- 10.1M
Yandex Cloud CLI 0.140.0 linux/amd64

yc PATH has been added to your '/root/.bashrc' profile
yc bash completion has been added to your '/root/.bashrc' profile.
```

### **Инициализируем подключение к yandex cloud**
```
[root@test2 hw-3]# yc init
Welcome! This command will take you through the configuration process.
...
...
...
Which zone do you want to use as a profile default?
 [1] ru-central1-a
 [2] ru-central1-b
 [3] ru-central1-d
 [4] Don't set default zone
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
```

### **Создаем директорию _otus-hw-3_**
```
[root@test2 hw-3]# yc resource folder create otus-hw-3
done (1s)
id: b1g36d17dbqndc7eeob1
cloud_id: b1gd4ggkqe80tpb8tph8
created_at: "2024-12-07T19:14:48Z"
name: otus-hw-3
status: ACTIVE

[root@test2 hw-3]# yc resource folder list
+----------------------+-----------+--------+------------------+
|          ID          |   NAME    | LABELS |      STATUS      |
+----------------------+-----------+--------+------------------+
| b1gkkq0hc73ijf53ge0g | default   |        | ACTIVE           |
| b1g36d17dbqndc7eeob1 | otus-hw-3 |        | ACTIVE           |
+----------------------+-----------+--------+------------------+
```

### **Устанавливаем директорию _otus-hw-3_ в качестве текущей рабочей директории**
```
[root@test2 hw-3]yc config set folder-id b1g36d17dbqndc7eeob1

[root@test2 hw-3]# yc config list 
token: y0_********************
cloud-id: b1gd4ggkqe80tpb8tph8
folder-id: b1g36d17dbqndc7eeob1
compute-default-zone: ru-central1-a
```

### **Создаем сеть _otus_**
```
[root@test2 hw-3]# yc vpc network create --name otus --description "otus" --folder-id b1g36d17dbqndc7eeob1
id: enp8jfq7pbcqo9eb6tv5
folder_id: b1g36d17dbqndc7eeob1
created_at: "2024-12-07T19:46:14Z"
name: otus
description: otus
default_security_group_id: enp0s2658c075r6vs17f
```

### **Создаем подсеть _otus-10-90-90-0_ в сети _otus_**
```
# yc vpc subnet create --name otus-10-90-90-0 --description "otus-10-90-90-0" --network-name otus --zone ru-central1-a --range 10.90.90.0/24
id: e9be2rdmt9ko9m4prc4p
folder_id: b1g36d17dbqndc7eeob1
created_at: "2024-12-07T21:05:48Z"
name: otus-10-90-90-0
description: otus-10-90-90-0
network_id: enp8jfq7pbcqo9eb6tv5
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.90.90.0/24
```

### **Создаем security-group _postgresql_ в сети _otus_ для доступа в _postgres_ из вне yandex cloud**
```
[root@test2 homework]# yc vpc security-group create --name "postgresql" --rule "direction=ingress,port=6432,protocol=tcp,v4-cidrs=[78.85.16.136/32]" --network-name otus
id: enpoostslep4ntj6lm14
folder_id: b1g36d17dbqndc7eeob1
created_at: "2024-12-07T21:23:02Z"
name: postgresql
network_id: enp8jfq7pbcqo9eb6tv5
status: ACTIVE
rules:
  - id: enp8igaf30feci2nld03
    direction: INGRESS
    ports:
      from_port: "6432"
      to_port: "6432"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32

[root@test2 homework]# yc vpc security-group update-rules --name "postgresql" --add-rule "direction=egress,from-port=0,to-port=65535,protocol=any,v4-cidrs=[0.0.0.0/0]"
id: enpoostslep4ntj6lm14
folder_id: b1g36d17dbqndc7eeob1
created_at: "2024-12-07T21:23:02Z"
name: postgresql
network_id: enp8jfq7pbcqo9eb6tv5
status: ACTIVE
rules:
  - id: enp8igaf30feci2nld03
    direction: INGRESS
    ports:
      from_port: "6432"
      to_port: "6432"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32
  - id: enpig9cgqkjbg7hovjfg
    direction: EGRESS
    ports:
      to_port: "65535"
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
```

### **Создаем кластер postgres**
```
[root@test2 hw-3]# CLUSTERNAME="otushw3"
[root@test2 hw-3]# USERNAME="otususer"
[root@test2 hw-3]# PASSWORD='#########'
[root@test2 hw-3]# DBNAME="otus"
[root@test2 hw-3]# FOLDER_ID="b1g36d17dbqndc7eeob1"

[root@test2 hw-3]# yc postgres cluster create --name ${CLUSTERNAME} \
--environment=prestable \
--postgresql-version 14 \
--network-name otus \
--resource-preset s2.micro \
--host zone-id=ru-central1-a,subnet-name=otus-10-90-90-0,assign-public-ip=true \
--disk-size 20 \
--disk-type network-hdd \
--user name=${USERNAME},password=${PASSWORD} \
--database name=${DBNAME},owner=${USERNAME},lc-collate=ru_RU.UTF-8,lc-ctype=ru_RU.UTF-8 \
--folder-id=${FOLDER_ID} \
--async

id: c9q7k92pjo3rrl5nrcku
description: Create PostgreSQL cluster
created_at: "2024-12-07T21:08:55.937661Z"
created_by: ajeg4ods6psa4bnd81j3
modified_at: "2024-12-07T21:08:55.937661Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.mdb.postgresql.v1.CreateClusterMetadata
  cluster_id: c9qrg2clld1u66l5chs4
```

### **Проверяем статус кластера**
```
[root@test2 hw-3]# yc postgres cluster list 
+----------------------+---------+---------------------+--------+---------+
|          ID          |  NAME   |     CREATED AT      | HEALTH | STATUS  |
+----------------------+---------+---------------------+--------+---------+
| c9qrg2clld1u66l5chs4 | otushw3 | 2024-12-07 21:08:55 | ALIVE  | RUNNING |
+----------------------+---------+---------------------+--------+---------+
```

### **Получаем доменное имя хоста**
```
[root@test2 hw-3]# yc postgres --cluster-name=otushw3 hosts list
+-------------------------------------------+----------------------+--------+--------+---------------+-----------+--------------------+
|                   NAME                    |      CLUSTER ID      |  ROLE  | HEALTH |    ZONE ID    | PUBLIC IP | REPLICATION SOURCE |
+-------------------------------------------+----------------------+--------+--------+---------------+-----------+--------------------+
| rc1a-hby42xt04f5q7wos.mdb.yandexcloud.net | c9qrg2clld1u66l5chs4 | MASTER | ALIVE  | ru-central1-a | true      |                    |
+-------------------------------------------+----------------------+--------+--------+---------------+-----------+--------------------+
```

### **Подключаемся к postgres и пробуем создать тестовую таблицу _accounts_**
```
[root@test2 hw-3]# psql -h rc1a-hby42xt04f5q7wos.mdb.yandexcloud.net -p 6432 -U otususer -d otus -W
Password: 
psql (14.3, server 14.13 (Ubuntu 14.13-201-yandex.53339.2c27a43bea))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

otus=> \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges    
-----------+----------+----------+-------------+-------------+------------------------
 otus      | otususer | UTF8     | ru_RU.UTF-8 | ru_RU.UTF-8 | =T/otususer           +
           |          |          |             |             | otususer=CTc/otususer +
           |          |          |             |             | postgres=c/otususer   +
           |          |          |             |             | monitor=c/otususer    +
           |          |          |             |             | mdb_odyssey=c/otususer+
           |          |          |             |             | admin=c/otususer
 postgres  | postgres | UTF8     | C           | C           | 
 template0 | postgres | UTF8     | C           | C           | =c/postgres           +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | C           | C           | =c/postgres           +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

otus=> \dt
Did not find any relations.
otus=> CREATE TABLE accounts (user_id SERIAL PRIMARY KEY,username VARCHAR (50) UNIQUE NOT NULL);
CREATE TABLE
otus=> INSERT INTO accounts (username) VALUES ('testuser1');
INSERT 0 1
otus=> INSERT INTO accounts (username) VALUES ('testuser2');
INSERT 0 1
otus=> select * from accounts ;
 user_id | username  
---------+-----------
       1 | testuser1
       2 | testuser2
(2 rows)
```

Как видим кластер доступен и тестовая таблица успешно создана.


### **Удаляем кластер**
```
[root@test2 hw-3]# yc postgres cluster delete --name otushw3 --async
id: c9qr446isd2lifv3c3e3
description: Delete PostgreSQL cluster
created_at: "2024-12-07T22:02:03.593639Z"
created_by: ajeg4ods6psa4bnd81j3
modified_at: "2024-12-07T22:02:03.593639Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.mdb.postgresql.v1.DeleteClusterMetadata
  cluster_id: c9qrg2clld1u66l5chs4
response:
  '@type': type.googleapis.com/google.rpc.Status
  message: OK
```
