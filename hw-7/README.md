# **HW-7 | Кластер Patroni**


## **Цель:**
Развернуть HA кластер


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Создаем 3 ВМ для etcd + 3 ВМ для Patroni +1 HA proxy (при проблемах можно на 1 хосте развернуть)
Инициализируем кластер
Проверяем отказоустойчивость
\<*>настраиваем бэкапы через wal-g или pg_probackup


## **Выполнение ДЗ**
Будем использовать Yandex-Cloud


### **Создаем сеть и подсеть 10.95.97.0/24**
```
[root@test2 hw-7]# yc vpc network create --name "otus-net" --description "otus-net"
id: enpukkaqv57tu1on627d
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:24Z"
name: otus-net
description: otus-net
default_security_group_id: enp7glu8ghqn3lppueb4

[root@test2 hw-7]# yc vpc network list
+----------------------+----------+
|          ID          |   NAME   |
+----------------------+----------+
| enpukkaqv57tu1on627d | otus-net |
+----------------------+----------+

[root@test2 hw-7]# yc vpc subnet create --name otus-subnet --range 10.95.97.0/24 --network-name otus-net --description "otus-subnet"
id: e9bk38l415v5el2mmajr
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:50Z"
name: otus-subnet
description: otus-subnet
network_id: enpukkaqv57tu1on627d
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.95.97.0/24

[root@test2 hw-7]# yc vpc subnet list
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
|          ID          |    NAME     |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
| e9bk38l415v5el2mmajr | otus-subnet | enpukkaqv57tu1on627d |                | ru-central1-a | [10.95.97.0/24] |
+----------------------+-------------+----------------------+----------------+---------------+-----------------+
```

### **Создаем инстанс haproxy**
```
[root@test2 hw-7]# yc compute instance create --name lb --hostname lb --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub
done (52s)
id: fhmdm78vtprarf9gki6u
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:27:43Z"
name: lb
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "2147483648"
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
  device_name: fhmc711tn2gu68v4ln7e
  auto_delete: true
  disk_id: fhmc711tn2gu68v4ln7e
network_interfaces:
  - index: "0"
    mac_address: d0:0d:db:1d:1f:ee
    subnet_id: e9bk38l415v5el2mmajr
    primary_v4_address:
      address: 10.95.97.10
      one_to_one_nat:
        address: 89.169.146.244
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: lb.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
```

  Поверяем успешность создания:
```
[root@test2 hw-7]# yc compute instance list
+----------------------+------+---------------+---------+----------------+-------------+
|          ID          | NAME |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+----------------------+------+---------------+---------+----------------+-------------+
| fhmdm78vtprarf9gki6u | lb   | ru-central1-a | RUNNING | 89.169.146.244 | 10.95.97.10 |
+----------------------+------+---------------+---------+----------------+-------------+
```

### **Настройка security group**
  Просмотр списка security group:
```
[root@test2 hw-7]# yc vpc security-group list
+----------------------+---------------------------------+--------------------------------+----------------------+
|          ID          |              NAME               |          DESCRIPTION           |      NETWORK-ID      |
+----------------------+---------------------------------+--------------------------------+----------------------+
| enp7glu8ghqn3lppueb4 | default-sg-enpukkaqv57tu1on627d | Default security group for     | enpukkaqv57tu1on627d |
|                      |                                 | network                        |                      |
+----------------------+---------------------------------+--------------------------------+----------------------+
```

  Просмотр списка сетевых правил:
```
[root@test2 hw-7]# yc vpc security-group get enp7glu8ghqn3lppueb4
id: enp7glu8ghqn3lppueb4
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:26Z"
name: default-sg-enpukkaqv57tu1on627d
description: Default security group for network
network_id: enpukkaqv57tu1on627d
status: ACTIVE
rules:
  - id: enpo5hjq5vbprjidl3ve
    direction: INGRESS
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
  - id: enp2c1f17sq19cc3f28f
    direction: EGRESS
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
default_for_network: true
```

  Удаляем полный доступ через правило id: "enpo5hjq5vbprjidl3ve"
```
# yc vpc security-group update-rules default-sg-enpukkaqv57tu1on627d --delete-rule-id enpo5hjq5vbprjidl3ve
done (3s)
id: enp7glu8ghqn3lppueb4
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:26Z"
name: default-sg-enpukkaqv57tu1on627d
description: Default security group for network
network_id: enpukkaqv57tu1on627d
status: ACTIVE
rules:
  - id: enp2c1f17sq19cc3f28f
    direction: EGRESS
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
default_for_network: true
```
  Добавляем разрешения для внешних подключения по портам TCP/9999 и TCP/22, только для IP 78.85.16.136/32 
```
# yc vpc security-group update-rules --name default-sg-enpukkaqv57tu1on627d --add-rule "direction=ingress,port=9999,protocol=tcp,v4-cidrs=[78.85.16.136/32]"
done (2s)
id: enp7glu8ghqn3lppueb4
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:26Z"
name: default-sg-enpukkaqv57tu1on627d
description: Default security group for network
network_id: enpukkaqv57tu1on627d
status: ACTIVE
rules:
  - id: enp2c1f17sq19cc3f28f
    direction: EGRESS
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
  - id: enph45ka23gssgnosauv
    direction: INGRESS
    ports:
      from_port: "9999"
      to_port: "9999"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32
default_for_network: true

[root@test2 hw-7]# yc vpc security-group update-rules --name default-sg-enpukkaqv57tu1on627d --add-rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=[78.85.16.136/32]"
done (2s)
id: enp7glu8ghqn3lppueb4
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:26Z"
name: default-sg-enpukkaqv57tu1on627d
description: Default security group for network
network_id: enpukkaqv57tu1on627d
status: ACTIVE
rules:
  - id: enp2c1f17sq19cc3f28f
    direction: EGRESS
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
  - id: enph45ka23gssgnosauv
    direction: INGRESS
    ports:
      from_port: "9999"
      to_port: "9999"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32
  - id: enptku5qrkd0289qmuu6
    direction: INGRESS
    ports:
      from_port: "22"
      to_port: "22"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32
default_for_network: true
```

  Проверяем доступность портов:
```
[root@test2 hw-7]# nc -zvw2 -p 9999 89.169.146.244 9999
Ncat: Version 7.93 ( https://nmap.org/ncat )
Ncat: Connected to 89.169.146.244:9999.
Ncat: 0 bytes sent, 0 bytes received in 0.08 seconds.
[root@test2 hw-7]# 
[root@test2 hw-7]# nc -zvw2 -p 9999 89.169.146.244 22
Ncat: Version 7.93 ( https://nmap.org/ncat )
Ncat: Connected to 89.169.146.244:22.
Ncat: 0 bytes sent, 0 bytes received in 0.08 seconds.
[root@test2 hw-7]# 
[root@test2 hw-7]# nc -zvw2 -p 9999 89.169.146.244 1234
Ncat: Version 7.93 ( https://nmap.org/ncat )
Ncat: TIMEOUT.
```

### **Создаем инстансы etcd**
```
[root@test2 hw-7]# for i in {1..3}; do yc compute instance create --name etcd$i --hostname etcd$i --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async & done;
[1] 2345304
[2] 2345305
[3] 2345306
[root@test2 hw-7]# id: fhmrirmas9ur5c8u0ss2
description: Create instance
created_at: "2024-12-11T17:31:25.425932858Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-11T17:31:25.425932858Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.CreateInstanceMetadata
  instance_id: fhm85cs93ncf8de0ajre

id: fhmgjjbdvt86f4uiu55c
description: Create instance
created_at: "2024-12-11T17:31:25.470131249Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-11T17:31:25.470131249Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.CreateInstanceMetadata
  instance_id: fhmrhb28ujoraocs5n7o

id: fhmdd1tndail67tg0stn
description: Create instance
created_at: "2024-12-11T17:31:25.527944294Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-11T17:31:25.527944294Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.CreateInstanceMetadata
  instance_id: fhmle5m275cc2safo3lu


[1]   Done                    yc compute instance create --name etcd$i --hostname etcd$i --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async
[2]-  Done                    yc compute instance create --name etcd$i --hostname etcd$i --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async
[3]+  Done                    yc compute instance create --name etcd$i --hostname etcd$i --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async
```

### **Создаем инстансы pgsql**
```
[root@test2 hw-7]# for i in {1..3}; do yc compute instance create --name pgsql$i --hostname pgsql$i --cores 2 --memory 4 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub --async ; done
id: fhmm91150h37manmo265
description: Create instance
created_at: "2024-12-11T17:33:54.670414496Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-11T17:33:54.670414496Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.CreateInstanceMetadata
  instance_id: fhmrqvg80q8985gf5jo9

id: fhmenopedhbgm7h9kmf0
description: Create instance
created_at: "2024-12-11T17:33:56.093840867Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-11T17:33:56.093840867Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.CreateInstanceMetadata
  instance_id: fhmn4ne68vsmhmkkl72s

id: fhma98n5ettrrrff2cvd
description: Create instance
created_at: "2024-12-11T17:33:57.541060273Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-11T17:33:57.541060273Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.compute.v1.CreateInstanceMetadata
  instance_id: fhmvmh7rjjdord6vd3m8
```

### **Проверка состояния инстансов**
```
[root@test2 hw-7]# yc compute instance list
+----------------------+--------+---------------+---------+----------------+-------------+
|          ID          |  NAME  |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+----------------------+--------+---------------+---------+----------------+-------------+
| fhm85cs93ncf8de0ajre | etcd3  | ru-central1-a | RUNNING | 89.169.138.172 | 10.95.97.25 |
| fhmdm78vtprarf9gki6u | lb     | ru-central1-a | RUNNING | 89.169.146.244 | 10.95.97.10 |
| fhmle5m275cc2safo3lu | etcd1  | ru-central1-a | RUNNING | 158.160.49.210 | 10.95.97.32 |
| fhmn4ne68vsmhmkkl72s | pgsql2 | ru-central1-a | RUNNING | 62.84.114.172  | 10.95.97.31 |
| fhmrhb28ujoraocs5n7o | etcd2  | ru-central1-a | RUNNING | 158.160.46.80  | 10.95.97.37 |
| fhmrqvg80q8985gf5jo9 | pgsql1 | ru-central1-a | RUNNING | 84.201.172.242 | 10.95.97.11 |
| fhmvmh7rjjdord6vd3m8 | pgsql3 | ru-central1-a | RUNNING | 51.250.65.186  | 10.95.97.7  |
+----------------------+--------+---------------+---------+----------------+-------------+
```

### **Конфигурируем файл /etc/hosts на всех нодах**
```
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address <<EOF
sudo bash -c 'cat >> /etc/hosts <<EOL
etcd1 10.95.97.32
etcd2 10.95.97.37
etcd3 10.95.97.25
lb 10.95.97.10
pgsql1 10.95.97.11
pgsql2 10.95.97.31
pgsql3 10.95.97.7
EOL
'
EOF
done;
```

```
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name etcd$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address <<EOF
sudo bash -c 'cat >> /etc/hosts <<EOL
etcd1 10.95.97.32
etcd2 10.95.97.37
etcd3 10.95.97.25
lb 10.95.97.10
pgsql1 10.95.97.11
pgsql2 10.95.97.31
pgsql3 10.95.97.7
EOL
'
EOF
done;
```

```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name lb | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address <<EOF
> sudo bash -c 'cat >> /etc/hosts <<EOL
etcd1 10.95.97.32
etcd2 10.95.97.37
etcd3 10.95.97.25
lb 10.95.97.10
pgsql1 10.95.97.11
pgsql2 10.95.97.31
pgsql3 10.95.97.7
EOL
'
EOF
```


### **Устанавливаем и конфигурируем etcd**
  Установка:
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name etcd$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'sudo apt update && sudo apt upgrade -y && sudo apt install -y etcd' & done;
```
  Предконфигурация:
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name etcd$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'sudo systemctl stop etcd && systemctl is-enabled etcd && systemctl status etcd' & done;
```
  Конфигурация:
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name etcd$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address <<EOF
sudo bash -c 'cat >> /etc/default/etcd <<EOL
ETCD_NAME="etcd$i"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://etcd$i:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://etcd$i:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_claster"
ETCD_INITIAL_CLUSTER="etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ENABLE_V2="true"
ETCDCRL_API=2
EOL
'
EOF
done;
```
  Запуск кластера etcd:
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name etcd$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'sudo systemctl start etcd' & done;
```

  Но кластер etcd не запускается, в логах видим таймауты
```
Dec 11 18:24:39 etcd3 etcd[8204]: health check for peer 25d0bfa2dcffa2d7 could not connect: dial tcp 10.95.97.32:2380: i/o timeout (prober "ROUND_TRIPPER_RAFT_MESSAGE")
Dec 11 18:24:39 etcd3 etcd[8204]: health check for peer 25d0bfa2dcffa2d7 could not connect: dial tcp 10.95.97.32:2380: i/o timeout (prober "ROUND_TRIPPER_SNAPSHOT")
Dec 11 18:24:39 etcd3 etcd[8204]: health check for peer 875a9230d9ea0259 could not connect: dial tcp 10.95.97.37:2380: i/o timeout (prober "ROUND_TRIPPER_RAFT_MESSAGE")
Dec 11 18:24:39 etcd3 etcd[8204]: health check for peer 875a9230d9ea0259 could not connect: dial tcp 10.95.97.37:2380: i/o timeout (prober "ROUND_TRIPPER_SNAPSHOT")
```
  Как оказалось **security-group** не пропускает трафик от сети "10.0.0.0/8" 

### **Добавляем дополнительное правило, разрешающее все из сети "10.0.0.0/8"**
```
[root@test2 hw-7]# yc vpc security-group update-rules --name default-sg-enpukkaqv57tu1on627d --add-rule "direction=ingress,port=ANY,protocol=tcp,v4-cidrs=[10.0.0.0/8]"
done (2s)
id: enp7glu8ghqn3lppueb4
folder_id: b1g3p5h57m7n0qsc9u5a
created_at: "2024-12-11T16:25:26Z"
name: default-sg-enpukkaqv57tu1on627d
description: Default security group for network
network_id: enpukkaqv57tu1on627d
status: ACTIVE
rules:
  - id: enp2c1f17sq19cc3f28f
    direction: EGRESS
    protocol_name: ANY
    protocol_number: "-1"
    cidr_blocks:
      v4_cidr_blocks:
        - 0.0.0.0/0
  - id: enph45ka23gssgnosauv
    direction: INGRESS
    ports:
      from_port: "9999"
      to_port: "9999"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32
  - id: enptku5qrkd0289qmuu6
    direction: INGRESS
    ports:
      from_port: "22"
      to_port: "22"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 78.85.16.136/32
  - id: enptarfce4toml28p7j6
    direction: INGRESS
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 10.0.0.0/8
default_for_network: true
```

### **Проверка статуса нод кластера etcd**
```
[root@test2 hw-7]# ssh yc-user@89.169.138.172 -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa
yc-user@etcd3:~$ sudo bash
root@etcd3:/home/yc-user# nc -zvw2 10.95.97.37 2380
Connection to 10.95.97.37 2380 port [tcp/*] succeeded!

root@etcd3:/home/yc-user# etcdctl member list
25d0bfa2dcffa2d7: name=etcd1 peerURLs=http://etcd1:2380 clientURLs=http://etcd1:2379 isLeader=false
875a9230d9ea0259: name=etcd2 peerURLs=http://etcd2:2380 clientURLs=http://etcd2:2379 isLeader=false
df0d680875ee2e00: name=etcd3 peerURLs=http://etcd3:2380 clientURLs=http://etcd3:2379 isLeader=true
root@etcd3:/home/yc-user# etcdctl cluster-health
member 25d0bfa2dcffa2d7 is healthy: got healthy result from http://etcd1:2379
member 875a9230d9ea0259 is healthy: got healthy result from http://etcd2:2379
member df0d680875ee2e00 is healthy: got healthy result from http://etcd3:2379
cluster is healthy
```

  Также проверяем, что метрики etcd также доступны:
```
root@etcd3:/home/yc-user# curl -L http://localhost:2379/metrics| grep fsync 
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0# HELP etcd_disk_wal_fsync_duration_seconds The latency distributions of fsync called by wal.
# TYPE etcd_disk_wal_fsync_duration_seconds histogram
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.001"} 13
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.002"} 28
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.004"} 40
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.008"} 61
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.016"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.032"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.064"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.128"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.256"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.512"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="1.024"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="2.048"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="4.096"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="8.192"} 71
etcd_disk_wal_fsync_duration_seconds_bucket{le="+Inf"} 71
etcd_disk_wal_fsync_duration_seconds_sum 0.29285970899999986
etcd_disk_wal_fsync_duration_seconds_count 71
# HELP etcd_snap_db_fsync_duration_seconds The latency distributions of fsyncing .snap.db file
# TYPE etcd_snap_db_fsync_duration_seconds histogram
etcd_snap_db_fsync_duration_seconds_bucket{le="0.001"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.002"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.004"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.008"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.016"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.032"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.064"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.128"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.256"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="0.512"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="1.024"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="2.048"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="4.096"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="8.192"} 0
etcd_snap_db_fsync_duration_seconds_bucket{le="+Inf"} 0
etcd_snap_db_fsync_duration_seconds_sum 0
etcd_snap_db_fsync_duration_seconds_count 0
```


### **Устанавливаем postgres** 
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'sudo apt update && sudo apt upgrade -y -q && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14' & done;
```
  Проверяем, что инстансы postgres запустились:
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'hostname; pg_lsclusters' & done;
[16] 2349129
[17] 2349130
[18] 2349132
[root@test2 hw-7]# Warning: Permanently added '84.201.172.242' (ED25519) to the list of known hosts.
Warning: Permanently added '62.84.114.172' (ED25519) to the list of known hosts.
Warning: Permanently added '51.250.65.186' (ED25519) to the list of known hosts.
pgsql1
pgsql2
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
pgsql3
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

[16]   Done                    vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'hostname; pg_lsclusters'
[17]   Done                    vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'hostname; pg_lsclusters'
[18]   Done                    vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'hostname; pg_lsclusters'
```

### **Устанавливаем и конфигурируем patroni**
```
[root@test2 hw-7]# for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'sudo apt install -y python3 python3-pip git mc && sudo pip3 install psycopg2-binary && sudo systemctl stop postgresql@14-main && sudo -u postgres pg_dropcluster 14 main && sudo pip3 install patroni[etcd] && sudo ln -s /usr/local/bin/patroni /bin/patroni' & done;
```
  Проверка установленной версии patroni:
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name pgsql1 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@pgsql1:~$ /usr/local/bin/patroni --version
patroni 4.0.4
```
  Конфигурация systemd юнита:
```
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'cat > temp.cfg << EOF 
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target
[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no
[Install]
WantedBy=multi-user.target
EOF
cat temp.cfg | sudo tee -a /etc/systemd/system/patroni.service
' & done;
```
  
  Предконфигурация patroni:
```
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'sudo systemctl daemon-reload && sudo apt install etcd-client && sudo mkdir /mnt/patroni && sudo chown postgres:postgres /mnt/patroni && sudo chmod 700 /mnt/patroni' & done;
```

  Разливаем конфигурационный файл на все ноды:
```
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name pgsql$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address 'cat > temp2.cfg << EOF 
scope: patroni
name: $(hostname)
restapi:
  listen: $(hostname -I | tr -d " "):8008
  connect_address: $(hostname -I | tr -d " "):8008
etcd:
  hosts: etcd1:2379,etcd2:2379,etcd3:2379
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
  - host replication replicator 10.95.97.0/24 md5
  - host all all 10.95.97.0/24 md5
  users:
    admin:
      password: ######
      options:
        - createrole
        - createdb
postgresql:
  listen: 127.0.0.1, $(hostname -I | tr -d " "):5432
  connect_address: $(hostname -I | tr -d " "):5432
  data_dir: /var/lib/postgresql/14/main
  bin_dir: /usr/lib/postgresql/14/bin
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
EOF
cat temp2.cfg | sudo tee -a /etc/patroni.yml
' & done;
```

### **Понодный запуск патрони и проверка запуска**
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name pgsql1 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@pgsql1:~$ sudo systemctl enable patroni && sudo systemctl start patroni
Created symlink /etc/systemd/system/multi-user.target.wants/patroni.service → /etc/systemd/system/patroni.service.
yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) -+----+-----------+
| Member | Host        | Role   | State   | TL | Lag in MB |
+--------+-------------+--------+---------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader | running |  1 |           |
+--------+-------------+--------+---------+----+-----------+


[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name pgsql2 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@pgsql2:~$ sudo systemctl enable patroni && sudo systemctl start patroni
Created symlink /etc/systemd/system/multi-user.target.wants/patroni.service → /etc/systemd/system/patroni.service.
yc-user@pgsql2:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) --+----+-----------+
| Member | Host        | Role    | State   | TL | Lag in MB |
+--------+-------------+---------+---------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running |  1 |           |
| pgsql2 | 10.95.97.31 | Replica | stopped |    |   unknown |
+--------+-------------+---------+---------+----+-----------+

[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name pgsql3 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@pgsql3:~$ sudo systemctl enable patroni && sudo systemctl start patroni
Created symlink /etc/systemd/system/multi-user.target.wants/patroni.service → /etc/systemd/system/patroni.service.
yc-user@pgsql3:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) --+----+-----------+
| Member | Host        | Role    | State   | TL | Lag in MB |
+--------+-------------+---------+---------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running |  1 |           |
| pgsql2 | 10.95.97.31 | Replica | stopped |    |   unknown |
| pgsql3 | 10.95.97.7  | Replica | stopped |    |   unknown |
+--------+-------------+---------+---------+----+-----------+

yc-user@pgsql3:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) --+----+-----------+
| Member | Host        | Role    | State   | TL | Lag in MB |
+--------+-------------+---------+---------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running |  1 |           |
| pgsql2 | 10.95.97.31 | Replica | stopped |    |   unknown |
| pgsql3 | 10.95.97.7  | Replica | stopped |    |   unknown |
+--------+-------------+---------+---------+----+-----------+
```
  Как видим реплики патрони на стартуют.
  В логах видим ошибки:
```
root@pgsql2:/home/yc-user# journalctl -f
-- Logs begin at Wed 2024-12-11 17:34:44 UTC. --
Dec 11 19:03:47 pgsql2 patroni[18418]: 2024-12-11 19:03:47,554 ERROR: Error when fetching backup: pg_basebackup exited with code=1
Dec 11 19:03:47 pgsql2 patroni[18418]: 2024-12-11 19:03:47,554 ERROR: failed to bootstrap from leader 'pgsql1'
Dec 11 19:03:47 pgsql2 patroni[18418]: 2024-12-11 19:03:47,554 INFO: Removing data directory: /var/lib/postgresql/14/main
Dec 11 19:03:48 pgsql2 sudo[18521]:  yc-user : TTY=pts/0 ; PWD=/home/yc-user ; USER=root ; COMMAND=/usr/bin/bash
Dec 11 19:03:48 pgsql2 sudo[18521]: pam_unix(sudo:session): session opened for user root by yc-user(uid=0)
Dec 11 19:03:52 pgsql2 patroni[18418]: 2024-12-11 19:03:52,517 INFO: Lock owner: pgsql1; I am pgsql2
Dec 11 19:03:52 pgsql2 patroni[18418]: 2024-12-11 19:03:52,522 INFO: trying to bootstrap from leader 'pgsql1'
Dec 11 19:03:52 pgsql2 patroni[18530]: pg_basebackup: error: connection to server at "10.95.97.11", port 5432 failed: FATAL:  no pg_hba.conf entry for replication connection from host "10.95.97.31", user "replicator", no encryption
Dec 11 19:03:52 pgsql2 patroni[18418]: 2024-12-11 19:03:52,536 ERROR: Error when fetching backup: pg_basebackup exited with code=1
Dec 11 19:03:52 pgsql2 patroni[18418]: 2024-12-11 19:03:52,536 WARNING: Trying again in 5 seconds
Dec 11 19:03:57 pgsql2 patroni[18536]: pg_basebackup: error: connection to server at "10.95.97.11", port 5432 failed: FATAL:  no pg_hba.conf entry for replication connection from host "10.95.97.31", user "replicator", no encryption
Dec 11 19:03:57 pgsql2 patroni[18418]: 2024-12-11 19:03:57,553 ERROR: Error when fetching backup: pg_basebackup exited with code=1
Dec 11 19:03:57 pgsql2 patroni[18418]: 2024-12-11 19:03:57,553 ERROR: failed to bootstrap from leader 'pgsql1'
Dec 11 19:03:57 pgsql2 patroni[18418]: 2024-12-11 19:03:57,553 INFO: Removing data directory: /var/lib/postgresql/14/main
```

  Ошибка оказалась в клнфиге patroni с которым он инициализировал кластер, 
в секции pg_hba была указана сеть 10.0.0.0/24, а у нас сеть 10.95.97.0/24.

  Исправляем:
```
root@pgsql1:/home/yc-user# cat /var/lib/postgresql/14/main/pg_hba.conf | tail -n 3

host replication replicator 10.95.97.0/24 md5
host all all 10.95.97.0/24 md5
root@pgsql1:/home/yc-user# psql -h 127.0.0.1 -U postgres
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

postgres=#
```

  После этого кластер patroni успешно запустился:
```
root@pgsql1:/home/yc-user# patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running   |  2 |           |
| pgsql2 | 10.95.97.31 | Replica | streaming |  2 |         0 |
| pgsql3 | 10.95.97.7  | Replica | streaming |  2 |         0 |
+--------+-------------+---------+-----------+----+-----------+
```


### **Конфигурируем haproxy**
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name lb | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@lb:~$ sudo bash
root@lb:/home/yc-user# vi /etc/haproxy/haproxy.cfg
root@lb:/home/yc-user# cat /etc/haproxy/haproxy.cfg
global
  maxconn 4000
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s
  user haproxy
  group haproxy
  daemon

defaults
  log global
  mode tcp
  retries 2
  timeout client 30m
  timeout connect 4s
  timeout server 30m
  timeout check 5s

listen patroni
  bind *:9999
  option httpchk OPTIONS /leader
  http-check expect status 200
  default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
  server pgsql1 10.95.97.11:5432 maxconn 1000 check port 8008
  server pgsql2 10.95.97.31:5432 maxconn 1000 check port 8008
  server pgsql3 10.95.97.7:5432 maxconn 1000 check port 8008
```
  Проверяем конфиг и рестартуем:
``` 
root@lb:/home/yc-user# haproxy -c -f /etc/haproxy/haproxy.cfg
Configuration file is valid

root@lb:/home/yc-user# systemctl restart haproxy
```

  Проверяем статусы бэкендов haproxy:
```
root@lb:/home/yc-user# echo "show stat" | nc -U /run/haproxy/admin.sock
# pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime,agent_status,agent_code,agent_duration,check_desc,agent_desc,check_rise,check_fall,check_health,agent_rise,agent_fall,agent_health,addr,cookie,mode,algo,conn_rate,conn_rate_max,conn_tot,intercepted,dcon,dses,wrew,connect,reuse,cache_lookups,cache_hits,srv_icur,src_ilim,qtime_max,ctime_max,rtime_max,ttime_max,
patroni,FRONTEND,,,0,0,4000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,2,0,,,,0,0,0,0,,,,,,,,,,,0,0,0,,,0,0,0,0,,,,,,,,,,,,,,,,,,,,,tcp,,0,0,0,,0,0,0,,,,,,,,,,,
patroni,pgsql1,0,0,0,0,1000,0,0,0,,0,,0,0,0,0,UP,1,1,0,0,0,103,0,,1,2,1,,0,,2,0,,0,L7OK,200,2,,,,,,,,,,,0,0,,,,,-1,HTTP status check returned code <200>,,0,0,0,0,,,,Layer7 check passed,,2,3,4,,,,10.95.97.11:5432,,tcp,,,,,,,,0,0,0,,,0,,0,0,0,0,
patroni,pgsql2,0,0,0,0,1000,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,1,1,102,102,,1,2,2,,0,,2,0,,0,L7STS,503,2,,,,,,,,,,,0,0,,,,,-1,HTTP status check returned code <503>,,0,0,0,0,,,,Layer7 wrong status,,2,3,0,,,,10.95.97.31:5432,,tcp,,,,,,,,0,0,0,,,0,,0,0,0,0,
patroni,pgsql3,0,0,0,0,1000,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,1,1,101,101,,1,2,3,,0,,2,0,,0,L7STS,503,2,,,,,,,,,,,0,0,,,,,-1,HTTP status check returned code <503>,,0,0,0,0,,,,Layer7 wrong status,,2,3,0,,,,10.95.97.7:5432,,tcp,,,,,,,,0,0,0,,,0,,0,0,0,0,
patroni,BACKEND,0,0,0,0,400,0,0,0,0,0,,0,0,0,0,UP,1,1,0,,0,103,0,,1,2,0,,0,,1,0,,0,,,,,,,,,,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,,,,,,,,,,,,,,tcp,roundrobin,,,,,,,0,0,0,,,,,0,0,0,0,
```
  Как и ожидалось бэкенд pgsql1 в статусе UP, т.к. мастер сейчас находится на pgsql1.


### Проверка подключения из вне Yandex-Cloud:
```
[root@test2 hw-7]# psql -h 89.169.146.244 -U postgres -p 9999 postgres -c 'SELECT version();'
Password for user postgres: 
                                                               version                                                               
-------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 14.15 (Ubuntu 14.15-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit
(1 row)
```

```
[root@test2 hw-7]# psql -h 89.169.146.244 -U postgres -p 9999 postgres
Password for user postgres: 
psql (14.3, server 14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# CREATE DATABASE test;
CREATE DATABASE
postgres=# \c test
psql (14.3, server 14.15 (Ubuntu 14.15-1.pgdg20.04+1))
You are now connected to database "test" as user "postgres".
test=# 
test=# create table persons(id serial, first_name text, second_name text);
CREATE TABLE
test=# insert into persons(first_name, second_name) values('ivan', 'ivanov');
insert into persons(first_name, second_name) values('petr', 'petrov');
INSERT 0 1
INSERT 0 1
test=# 
test=# select * from persons ;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
  Как видим подключение успешно, и база доступна на записью



### **Проверка отказоустойчивости**

  Проверяем текущий статус нод:
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name pgsql1 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running   |  2 |           |
| pgsql2 | 10.95.97.31 | Replica | streaming |  2 |         0 |
| pgsql3 | 10.95.97.7  | Replica | streaming |  2 |         0 |
+--------+-------------+---------+-----------+----+-----------+
```

  Останавливаем patroni на pgsql1:
```
yc-user@pgsql1:~$ sudo systemctl stop patroni 
yc-user@pgsql1:~$ 
yc-user@pgsql1:~$ 
yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Replica | stopped   |    |   unknown |
| pgsql2 | 10.95.97.31 | Leader  | running   |  3 |           |
| pgsql3 | 10.95.97.7  | Replica | streaming |  3 |         0 |
+--------+-------------+---------+-----------+----+-----------+
```
  Как видим мастер успешно переехал на pgsql2  

  Стартуем pgsql1: 
```
yc-user@pgsql1:~$ sudo systemctl start patroni 
yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Replica | streaming |  3 |         0 |
| pgsql2 | 10.95.97.31 | Leader  | running   |  3 |           |
| pgsql3 | 10.95.97.7  | Replica | streaming |  3 |         0 |
+--------+-------------+---------+-----------+----+-----------+
```
  Как видим pgsql1 вернулся в кластер в качестве реплики  

  Проверяем switchover:
```
yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml switchover 
Current cluster topology
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Replica | streaming |  3 |         0 |
| pgsql2 | 10.95.97.31 | Leader  | running   |  3 |           |
| pgsql3 | 10.95.97.7  | Replica | streaming |  3 |         0 |
+--------+-------------+---------+-----------+----+-----------+
Primary [pgsql2]: 
Candidate ['pgsql1', 'pgsql3'] []: pgsql1
When should the switchover take place (e.g. 2024-12-11T20:35 )  [now]: 
Are you sure you want to switchover cluster patroni, demoting current leader pgsql2? [y/N]: y
2024-12-11 19:36:03.21238 Successfully switched over to "pgsql1"
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running   |  3 |           |
| pgsql2 | 10.95.97.31 | Replica | stopped   |    |   unknown |
| pgsql3 | 10.95.97.7  | Replica | streaming |  3 |         0 |
+--------+-------------+---------+-----------+----+-----------+

yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) --+----+-----------+
| Member | Host        | Role    | State   | TL | Lag in MB |
+--------+-------------+---------+---------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running |  4 |           |
| pgsql2 | 10.95.97.31 | Replica | stopped |    |   unknown |
| pgsql3 | 10.95.97.7  | Replica | running |  3 |         0 |
+--------+-------------+---------+---------+----+-----------+

yc-user@pgsql1:~$ sudo patronictl -c /etc/patroni.yml list
+ Cluster: patroni (7447231542716905576) ----+----+-----------+
| Member | Host        | Role    | State     | TL | Lag in MB |
+--------+-------------+---------+-----------+----+-----------+
| pgsql1 | 10.95.97.11 | Leader  | running   |  4 |           |
| pgsql2 | 10.95.97.31 | Replica | streaming |  4 |         0 |
| pgsql3 | 10.95.97.7  | Replica | running   |  3 |         0 |
+--------+-------------+---------+-----------+----+-----------+
```
  Как видим pgsql1 успешно вернул себе статус мастера (Leader)




## **Настройка бэкапирования**
  Для хранения бэкапов будем использовать инстанс haproxy (**lb**)

### **Установка pg_probackup**
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name lb | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@lb:~$ sudo bash
root@lb:/home/yc-user# wget -O - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP | sudo apt-key add -
root@lb:/home/yc-user# echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ $(lsb_release -cs) main-$(lsb_release -cs)" > /etc/apt/sources.list.d/pg_probackup.list
root@lb:/home/yc-user# apt-get update && sudo apt-get install pg-probackup-14
root@lb:/home/yc-user# ln -s /usr/bin/pg_probackup-14 /usr/bin/pg_probackup
root@lb:/home/yc-user# pg_probackup --version
pg_probackup 2.5.15 (PostgreSQL 14.11)
```
### **Создаем выделенного пользователя и директорию для хранения бэкапов:**
```
root@lb:/home/yc-user# useradd postgres
root@lb:/home/yc-user# mkdir -p /data/pg_probackup
root@lb:/home/yc-user# chown postgres:postgres /data/pg_probackup
root@lb:/home/yc-user# usermod -d /data/pg_probackup postgres
```
  Создаем ssh ключ который будем использовать для подключения c pgsql1:
```
root@lb:/home/yc-user# su - postgres
$ ssh-keygen	
Generating public/private rsa key pair.
```

  Переносим публичную часть ssh ключа с lb на pgsql1
```
lb: /data/pg_probackup/.ssh/id_rsa.pub -> pgsql1: ~/.ssh/authorized_keys 
```

  Проверка подключения:
```
postgres@lb:~$ ssh 10.95.97.11 hostname
pgsql1
```

### **Конфигурация доступа к БД**
  Создаем файл паролей для беспарольного доступа к postgres:
```
postgres@lb:~$ cat /data/pg_probackup/.pgpass
pgsql1:*:*:backup:######
postgres@lb:~$ chmod 600 /data/pg_probackup/.pgpass
```
  Также на pgsql1 в pg_hba.conf добавляем запись для пользователя "backup"  
под которым pg_probackup будет подключаться:
```
postgres@pgsql1:~$ grep backup /var/lib/postgresql/14/main/pg_hba.conf
host replication backup 10.95.97.0/24 md5
```

  На pgsql1 создаем выделенную базу backupdb и пользователя backup,  
которые будут использоваться для сбора бэкапов:
```
yc-user@pgsql1:~$ psql -h 127.0.0.1 -U postgres
psql (14.15 (Ubuntu 14.15-1.pgdg20.04+1))
Type "help" for help.

postgres=# CREATE DATABASE backupdb;
CREATE DATABASE
postgres=# \c backupdb
You are now connected to database "backupdb" as user "postgres".
backupdb=# BEGIN;
BEGIN
backupdb=*# CREATE ROLE backup WITH LOGIN;
CREATE ROLE
backupdb=*# GRANT USAGE ON SCHEMA pg_catalog TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.current_setting(text) TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.set_config(text, text, boolean) TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_is_in_recovery() TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_start_backup(text, boolean, boolean) TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_stop_backup(boolean, boolean) TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_create_restore_point(text) TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_switch_wal() TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_last_wal_replay_lsn() TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.txid_current() TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.txid_current_snapshot() TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.txid_snapshot_xmax(txid_snapshot) TO backup;
GRANT
backupdb=*# GRANT EXECUTE ON FUNCTION pg_catalog.pg_control_checkpoint() TO backup;
GRANT
backupdb=*# COMMIT;
COMMIT
backupdb=# ALTER USER backup WITH REPLICATION;
ALTER ROLE
backupdb=# alter user backup with password '######';
ALTER ROLE

backupdb=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

  Проверяем расположение data_directory:
```
yc-user@pgsql1:~$ psql -h 127.0.0.1 -U postgres -c 'SHOW data_directory'
       data_directory        
-----------------------------
 /var/lib/postgresql/14/main
(1 row)
```


### **Инициализация pg_probackup**
```
root@lb:/home/yc-user# su - postgres
$ cd ~
$ pwd
/data/pg_probackup
$ pg_probackup init -B /data/pg_probackup/otus
INFO: Backup catalog '/data/pg_probackup/otus' successfully initialize

### **Конфигурация инстанса для бэкапирования**
postgres@lb:~$ pg_probackup add-instance --instance=pgsql1 -B /data/pg_probackup/otus --remote-host=pgsql1 --remote-user=postgres --pgdata=/var/lib/postgresql/14/main
The authenticity of host 'pgsql1 (10.95.97.11)' can't be established.
ECDSA key fingerprint is SHA256:VeoNBurSOm6VzudxTuAcRRu2eddR2QjMXwshXSlmEmc.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
ERROR: Agent error: bash: pg_probackup: command not found
```
  Возникла ошибка, т.к. я забыл установить pg_probackup на pqsql1.  

### **Установка pg_probackup на pqsql1**
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name pgsql1 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@pgsql1:~$ sudo bash
root@pgsql1:/home/yc-user# wget -O - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP | sudo apt-key add -
root@pgsql1:/home/yc-user# echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ $(lsb_release -cs) main-$(lsb_release -cs)" > /etc/apt/sources.list.d/pg_probackup.list
root@pgsql1:/home/yc-user# apt-get update && sudo apt-get install pg-probackup-14
root@pgsql1:/home/yc-user# pg_probackup --version
pg_probackup 2.5.15 (PostgreSQL 14.11)
```

### **Повторная попытка конфигурации инстанса**
```
[root@test2 hw-7]# vm_ip_address=$(yc compute instance show --name lb | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i /home/voronov/.ssh/id_rsa yc-user@$vm_ip_address
yc-user@lb:~$ sudo bash
root@lb:/home/yc-user# su - postgres
postgres@lb:~$ pg_probackup add-instance --instance=pgsql1 -B /data/pg_probackup/otus --remote-host=pgsql1 --remote-user=postgres --pgdata=/var/lib/postgresql/14/main
INFO: Instance 'pgsql1' successfully initialized
```
Успешно.

### **Запускаем сбор бекапов**
  FULL бэкап:
```
postgres@lb:~$ pg_probackup backup -B /data/pg_probackup/otus --instance=pgsql1 -b FULL --stream --remote-host=pgsql1 --remote-user=postgres -U backup -d backupdb
INFO: Backup start, pg_probackup version: 2.5.15, instance: pgsql1, backup ID: SOCJDG, backup mode: FULL, wal mode: STREAM, remote: true, compress-algorithm: none, compress-level: 1
INFO: This PostgreSQL instance was initialized with data block checksums. Data block corruption will be detected
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Wait for WAL segment /data/pg_probackup/otus/backups/pgsql1/SOCJDG/database/pg_wal/000000040000000000000005 to be streamed
INFO: PGDATA size: 34MB
INFO: Current Start LSN: 0/5000028, TLI: 4
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 1s
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/50115A8
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 13s
INFO: Validating backup SOCJDG
INFO: Backup SOCJDG data files are valid
INFO: Backup SOCJDG resident size: 50MB
INFO: Backup SOCJDG completed
```
  DELTA бэкап: 
``` 
postgres@lb:~$ pg_probackup backup -B /data/pg_probackup/otus --instance=pgsql1 -b DELTA --stream --remote-host=pgsql1 --remote-user=postgres -U backup -d backupdb
INFO: Backup start, pg_probackup version: 2.5.15, instance: pgsql1, backup ID: SOCJEX, backup mode: DELTA, wal mode: STREAM, remote: true, compress-algorithm: none, compress-level: 1
INFO: This PostgreSQL instance was initialized with data block checksums. Data block corruption will be detected
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Parent backup: SOCJDG
INFO: Wait for WAL segment /data/pg_probackup/otus/backups/pgsql1/SOCJEX/database/pg_wal/000000040000000000000007 to be streamed
INFO: PGDATA size: 34MB
INFO: Current Start LSN: 0/7000028, TLI: 4
INFO: Parent Start LSN: 0/5000028, TLI: 4
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 0
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/70001A0
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 0
INFO: Validating backup SOCJEX
INFO: Backup SOCJEX data files are valid
INFO: Backup SOCJEX resident size: 16MB
INFO: Backup SOCJEX completed
```
  Просмотр состояния бекапов:
``` 
postgres@lb:~$ pg_probackup show -B /data/pg_probackup/otus

BACKUP INSTANCE 'pgsql1'
==================================================================================================================================
 Instance  Version  ID      Recovery Time           Mode   WAL Mode  TLI  Time   Data   WAL  Zratio  Start LSN  Stop LSN   Status 
==================================================================================================================================
 pgsql1    14       SOCJEX  2024-12-11 20:25:47+00  DELTA  STREAM    4/4   11s  187kB  16MB    1.00  0/7000028  0/70001A0  OK     
 pgsql1    14       SOCJDG  2024-12-11 20:24:55+00  FULL   STREAM    4/0   24s   34MB  16MB    1.00  0/5000028  0/50115A8  OK     
```
  Все в порядке
