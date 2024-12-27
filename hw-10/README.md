# **HW-10 | Развернуть HA кластер



## **Цель:**
развернуть высокодоступный кластер PostgeSQL собственными силами
развернуть высокодоступный сервис на базе PostgeSQL на базе одного из 3-ки ведущих облачных провайдеров - AWS, GCP и Azure



## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Выбрать один из вариантов и развернуть кластер. Описать что и как делали и с какими проблемами столкнулись  
- Вариант 1 How to Deploy PostgreSQL for High Availability  
- Вариант 2 Introducing pg_auto_failover: Open source extension for automated failover and high-availability in PostgreSQL  

Для гурманов  
Настройка Active/Passive PostgreSQL Cluster с использованием Pacemaker, Corosync, и DRBD (CentOS 5,5) 

Задание повышенной сложности:  
Создать два кластера GKE в разных регионах   
Установить на первом Patroni HA кластер.  
Установить на втором Patroni Standby кластер  
Настроить TCP LB между регионами  
Сделать в каждом регионе по клиентской ВМ  
Проверить как ходит трафик с клиентской ВМ  
Описать что и как делали и с какими проблемами столкнулись



## **Выполнение ДЗ**
### **Выбранный план**
- создадим виртуалку в zone-a
- создадим кластера managed-k8s в zone-a
- установка кластера postgres в managed-k8s в zone-a
- проверка работы postgres с виртуалки в zone-a
 - создаем тестовую таблицу
 - проверяем переключение лидера кластера при перезагрузке подов
 - проверяем ручной switchover
- создадим кластера managed-k8s в zone-b
- установка standby кластера postgres в managed-k8s в zone-b
- создание в k8s сервисов типа loadbalancer для доступа к лидеру patroni в обоих зонах
- создание TCP loadbalancer
- тестирование конфигурации
 - отключаем кластер patroni в zone-a
 - переключаем кластер patroni в zone-b из standby в primary
 - проверяем доступность данных



### **Создаем VM в zone-a**

**Создаем директорию для ДЗ**
```
[root@test2 hw-10]# yc resource folder create otus-hw
done (1s)
id: b1gidntdt0mi4p0gpkh5
cloud_id: b1gd4g###############
created_at: "2024-12-26T17:19:38Z"
name: otus-hw
status: ACTIVE

[root@test2 hw-10]# yc config set folder-id b1gidntdt0mi4p0gpkh5

[root@test2 hw-10]# yc config list
token: y0_AgAA#############################################
cloud-id: b1gd4g###############
folder-id: b1gidntdt0mi4p0gpkh5
compute-default-zone: ru-central1-a
```

**Создаем сетевые ресурсы**
```
[root@test2 hw-10]# yc vpc network create --name "otus-net" --description "otus-net"
id: enpp8ckss7v07c9aea9i
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-26T17:26:26Z"
name: otus-net
description: otus-net
default_security_group_id: enp77t5n6nrfgl8294k9

[root@test2 hw-10]# yc vpc subnet create --name otus-subnet-a --range 10.95.101.0/24 --network-name otus-net --description "otus-subnet-a"
id: e9b0s006hf6j7l86k01a
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-26T17:45:07Z"
name: otus-subnet-a
description: otus-subnet-a
network_id: enpp8ckss7v07c9aea9i
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.95.101.0/24
```

**Создаем VM в зоне ru-central1-a**
```
[root@test2 hw-10]# yc compute instance create --name vm-a --hostname vm-a --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=almalinux-8 --preemptible --network-interface subnet-name=otus-subnet-a,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub
done (41s)
id: fhmat0g8egp2oil25bvd
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T06:37:36Z"
name: vm-a
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
  device_name: fhm122863ipo1fahc3r0
  auto_delete: true
  disk_id: fhm122863ipo1fahc3r0
network_interfaces:
  - index: "0"
    mac_address: d0:0d:ae:82:08:74
    subnet_id: e9b0s006hf6j7l86k01a
    primary_v4_address:
      address: 10.95.101.13
      one_to_one_nat:
        address: 89.169.128.66
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: vm-a.ru-central1.internal
scheduling_policy:
  preemptible: true
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1
```

### **Создадим managed K8S кластер в зоне ru-central1-a**
**Создаем сервисный аккаунт для K8S**
```
[root@test2 hw-10]# FOLDER_ID=$(yc config get folder-id)

[root@test2 hw-10]# yc iam service-account create --name sa-k8s-pg1
done (1s)
id: ajeccrfd9ev3mllbp346
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-26T17:37:54.661533239Z"
name: sa-k8s-pg1


[root@test2 hw-10]# SA_ID=$(yc iam service-account get --name sa-k8s-pg1 --format json | jq .id -r)


[root@test2 hw-10]# yc resource-manager folder add-access-binding --id $FOLDER_ID --role admin --subject serviceAccount:$SA_ID
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: admin
      subject:
        id: ajeccrfd9ev3mllbp346
        type: serviceAccount

[root@test2 hw-10]# yc iam service-account list
+----------------------+------------+--------+---------------------+-----------------------+
|          ID          |    NAME    | LABELS |     CREATED AT      | LAST AUTHENTICATED AT |
+----------------------+------------+--------+---------------------+-----------------------+
| ajeccrfd9ev3mllbp346 | sa-k8s-pg1 |        | 2024-12-26 17:37:54 |                       |
+----------------------+------------+--------+---------------------+-----------------------+
```

**Запускаем создаем master узлы**
```
[root@test2 hw-10]# yc managed-kubernetes cluster create --name k8s-pg1 --network-name otus-net --zone ru-central1-a --subnet-name otus-subnet-a --service-account-id ${SA_ID} --node-service-account-id ${SA_ID} --async
id: catu6gv9m6p3jrj9h44b
description: Create cluster
created_at: "2024-12-26T21:04:15.468618291Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-26T21:04:15.468618291Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.k8s.v1.CreateClusterMetadata
  cluster_id: cate9afnebuikl5mhao1
```
**дожидаемся статуса RUNNING**
```
[root@test2 hw-10]# yc managed-kubernetes cluster list
+----------------------+---------+---------------------+---------+---------+-------------------+----------------------+
|          ID          |  NAME   |     CREATED AT      | HEALTH  | STATUS  | EXTERNAL ENDPOINT |  INTERNAL ENDPOINT   |
+----------------------+---------+---------------------+---------+---------+-------------------+----------------------+
| cate9afnebuikl5mhao1 | k8s-pg1 | 2024-12-26 21:04:15 | HEALTHY | RUNNING |                   | https://10.95.101.16 |
+----------------------+---------+---------------------+---------+---------+-------------------+----------------------+
```
**Запускаем создаем воркер узлов**
```
[root@test2 hw-10]# yc managed-kubernetes node-group create --name k8s-pg1-worker --cluster-name k8s-pg1 --platform-id standard-v2 --preemptible --cores 2 --memory 4 --core-fraction 20 --disk-type network-hdd --disk-size=80G --fixed-size 3 --location subnet-name=otus-subnet-a,zone=ru-central1-a --async
id: catq2csuujt2bu1voaq6
description: Create node group
created_at: "2024-12-27T06:28:59.389830526Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-27T06:28:59.389830526Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.k8s.v1.CreateNodeGroupMetadata
  node_group_id: cat9rl25vdaeqr2vmdoj
```
**дожидаемся статуса RUNNING**
```
[root@test2 hw-10]# yc managed-kubernetes node-group list
+----------------------+----------------------+----------------+----------------------+---------------------+---------+------+
|          ID          |      CLUSTER ID      |      NAME      |  INSTANCE GROUP ID   |     CREATED AT      | STATUS  | SIZE |
+----------------------+----------------------+----------------+----------------------+---------------------+---------+------+
| cat9rl25vdaeqr2vmdoj | cate9afnebuikl5mhao1 | k8s-pg1-worker | cl1kmcbbctic30f4ju60 | 2024-12-27 06:28:59 | RUNNING |    3 |
+----------------------+----------------------+----------------+----------------------+---------------------+---------+------+
```
**Формируем конфиг для подключения к кластеру через внутренний IP**
```
[root@test2 hw-10]# yc managed-kubernetes cluster get-credentials k8s-pg1 --internal --kubeconfig=./config

Context 'yc-k8s-pg1' was added as default to kubeconfig './config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig ./config'.

Note, that authentication depends on 'yc' and its config profile 'default'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
```
**Копируем конфиг на VM-A**
```
[root@test2 hw-10]# scp ./config  yc-user@89.169.128.66:~/

[root@test2 hw-10]# ssh yc-user@89.169.128.66
[yc-user@vm-a ~]$ mkdir $HOME/.kube
[yc-user@vm-a ~]$ mv config $HOME/.kube
```

**Скачиваем и инициализируем cli для подключения к ЯО**
```
[yc-user@vm-a ~]$ curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
[yc-user@vm-a ~]$ . /home/yc-user/.bashrc
[yc-user@vm-a ~]$ yc init

[yc-user@vm-a ~]$ yc config list
token: y0_AgAAAAAV###############################
cloud-id: b1gd4g######################
folder-id: b1gidntdt0mi4p0gpkh5
compute-default-zone: ru-central1-a
```



### **Установка пакетов для управления кластером на VM-A**
```
[root@test2 hw-10]# ssh yc-user@89.169.128.66
[yc-user@vm-a ~]$ sudo bash
[root@vm-a yc-user]# curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
[root@vm-a yc-user]# install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
[root@vm-a yc-user]# ln -s /usr/local/bin/kubectl /usr/bin/kubectl

[root@vm-a yc-user]# kubectl version --client
Client Version: v1.28.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```
**проверяем доступность воркер нод кластера**
```
[yc-user@vm-a ~]$ kubectl get nodes -o wide
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1kmcbbctic30f4ju60-agul   Ready    <none>   19m   v1.28.9   10.95.101.17   <none>        Ubuntu 20.04.6 LTS   5.4.0-196-generic   containerd://1.6.28
cl1kmcbbctic30f4ju60-irod   Ready    <none>   19m   v1.28.9   10.95.101.8    <none>        Ubuntu 20.04.6 LTS   5.4.0-196-generic   containerd://1.6.28
cl1kmcbbctic30f4ju60-ofuw   Ready    <none>   19m   v1.28.9   10.95.101.5    <none>        Ubuntu 20.04.6 LTS   5.4.0-196-generic   containerd://1.6.28
```
**устанавливаем helm**
```
[root@vm-a yc-user]# curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
[root@vm-a yc-user]# ln -s /usr/local/bin/helm /usr/bin/helm
[root@vm-a yc-user]# exit
[yc-user@vm-a ~]$ helm version
version.BuildInfo{Version:"v3.16.4", GitCommit:"7877b45b63f95635153b29a42c0c2f4273ec45ca", GitTreeState:"clean", GoVersion:"go1.22.7"}
```



### **Установка кластера postgres в managed-k8s в ru-central1-a**
```
[yc-user@vm-a ~]$ helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
"postgres-operator-charts" has been added to your repositories
[yc-user@vm-a ~]$ 
[yc-user@vm-a ~]$ helm install postgres-operator postgres-operator-charts/postgres-operator
NAME: postgres-operator
LAST DEPLOYED: Fri Dec 27 07:27:19 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that postgres-operator has started, run:

  kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"
```
**проверяем и видим, что образ не может скачаться**
```
[yc-user@vm-a ~]$ 
[yc-user@vm-a ~]$ kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"
NAME                                 READY   STATUS              RESTARTS   AGE
postgres-operator-5f587dbd7f-t7q6v   0/1     ContainerCreating   0          29s
[yc-user@vm-a ~]$ 
[yc-user@vm-a ~]$ kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"
NAME                                 READY   STATUS             RESTARTS   AGE
postgres-operator-5f587dbd7f-t7q6v   0/1     ImagePullBackOff   0          48s
```
**смотрим статус и видим причину, нет сетового доступа**
```
[yc-user@vm-a ~]$ kubectl describe pod postgres-operator-5f587dbd7f-t7q6v | grep Failed
  Warning  Failed     69s                  kubelet            Failed to pull image "ghcr.io/zalando/postgres-operator:v1.14.0": rpc error: code = DeadlineExceeded desc = failed to pull and unpack image "ghcr.io/zalando/postgres-operator:v1.14.0": failed to resolve reference "ghcr.io/zalando/postgres-operator:v1.14.0": failed to do request: Head "https://ghcr.io/v2/zalando/postgres-operator/manifests/v1.14.0": dial tcp 140.82.121.33:443: i/o timeout
  Warning  Failed     54s (x2 over 113s)   kubelet            Error: ImagePullBackOff
  Warning  Failed     10s (x2 over 114s)   kubelet            Failed to pull image "ghcr.io/zalando/postgres-operator:v1.14.0": rpc error: code = DeadlineExceeded desc = failed to pull and unpack image "ghcr.io/zalando/postgres-operator:v1.14.0": failed to resolve reference "ghcr.io/zalando/postgres-operator:v1.14.0": failed to do request: Head "https://ghcr.io/v2/zalando/postgres-operator/manifests/v1.14.0": dial tcp 140.82.121.34:443: i/o timeout
  Warning  Failed     10s (x3 over 114s)   kubelet            Error: ErrImagePull
```
**используя доку создаем маршрут по умолчанию**
https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway
```
[root@test2 hw-10]# yc vpc gateway create --name ext-gateway
id: enpkq1ncvtg2n8nhnlfo
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T07:32:56Z"
name: ext-gateway
shared_egress_gateway: {}

[root@test2 hw-10]# yc vpc gateway list
+----------------------+-------------+-------------+
|          ID          |    NAME     | DESCRIPTION |
+----------------------+-------------+-------------+
| enpkq1ncvtg2n8nhnlfo | ext-gateway |             |
+----------------------+-------------+-------------+

[root@test2 hw-10]# yc vpc route-table create --name=ext-route-table --network-name=otus-net --route destination=0.0.0.0/0,gateway-id=enpkq1ncvtg2n8nhnlfo
id: enpm2fqidc7klkd65psr
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T07:33:24Z"
name: ext-route-table
network_id: enpp8ckss7v07c9aea9i
static_routes:
  - destination_prefix: 0.0.0.0/0
    gateway_id: enpkq1ncvtg2n8nhnlfo

[root@test2 hw-10]# yc vpc subnet update otus-subnet-a --route-table-name=ext-route-table
done (2s)
id: e9b0s006hf6j7l86k01a
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-26T17:45:07Z"
name: otus-subnet-a
description: otus-subnet-a
network_id: enpp8ckss7v07c9aea9i
zone_id: ru-central1-a
v4_cidr_blocks:
  - 10.95.101.0/24
route_table_id: enpm2fqidc7klkd65psr
dhcp_options: {}
```
**проверяем, что pod успешно стартанул**
```
[yc-user@vm-a ~]$ kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"
NAME                                 READY   STATUS    RESTARTS   AGE
postgres-operator-5f587dbd7f-t7q6v   1/1     Running   0          14m
```

**Формируем манифест, для создания кластера postgres**
```
kind: "postgresql"
apiVersion: "acid.zalan.do/v1"
metadata:
  name: "pg1"
  namespace: "default"
  labels:
    team: otus
spec:
  teamId: "otus"
  numberOfInstances: 3
  users:
    useradmin:
    - superuser
    - createdb
    userotus: []
  enableMasterLoadBalancer: true
  allowedSourceRanges: null
  databases:
    otus: userotus
  masterServiceAnnotations:
    yandex.cloud/load-balancer-type: internal
    yandex.cloud/subnet-id: e9b0s006hf6j7l86k01a
  maintenanceWindows:
  volume:
    size: "10Gi"
  resources:
    requests:
      cpu: 1000m
      memory: 1000Mi
    limits:
      cpu: 2000m
      memory: 3000Mi
  postgresql:
    version: "16"
    parameters:
      wal_log_hints: "true"
      log_statement: "all"
      # Memory Configuration
      shared_buffers: "768MB"
      effective_cache_size: "2GB"
      work_mem: "8MB"
      maintenance_work_mem: "154MB"
      # Checkpoint Related Configuration
      min_wal_size: "2GB"
      max_wal_size: "3GB"
      checkpoint_completion_target: "0.9"
      wal_buffers: "-1"
      # Network Related Configuration
      listen_addresses: '*'
      max_connections: "100"
      # Storage Configuration
      random_page_cost: "4.0"
      effective_io_concurrency: "2"
      # Worker Processes Configuration
      max_worker_processes: "8"
      max_parallel_workers_per_gather: "2"
      max_parallel_workers: "2"
  patroni:
    failsafe_mode: false
    initdb:
      encoding: "UTF8"
      locale: "en_US.UTF-8"
      data-checksums: "true"
```
, где
- в аннотации укажем нушу подсеть, для IP сервиса loadbalancer
- в секции postgresql укажем версию и параметры тюнинга для постгрес
- в секции patroni укажем параметры для инициализации бд

**создаем кластер pg1**
```
[yc-user@vm-a ~]$ kubectl create -f pg1.yaml 
postgresql.acid.zalan.do/pg1 created
```
**проверяем статус подов**
```
[yc-user@vm-a ~]$ kubectl get pods -l cluster-name=pg1
NAME    READY   STATUS    RESTARTS   AGE
pg1-0   1/1     Running   0          7m11s
pg1-1   1/1     Running   0          6m11s
pg1-2   1/1     Running   0          5m14s
```
**проверяем статус сервиса LoadBalancer и видим, что статус pending**
```
[yc-user@vm-a ~]$ kubectl get svc pg1
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
pg1                 LoadBalancer   10.96.137.134   <pending>     5432:31609/TCP   109s
```
**смотрим events, видим причину**
```
[yc-user@vm-a ~]$ kubectl get events | grep Error
108s        Warning   SyncLoadBalancerFailed   service/pg1                               Error syncing load balancer: failed to ensure load balancer: incorrect loadbalancer specification: loadbalancerSourceRanges are unsupported
```
**удаляем параметр loadbalancerSourceRanges из манифеста сервиса**
```
[yc-user@vm-a ~]$ kubectl edit svc pg1
service/pg1 edited
```
**проверяем статус сервиса LoadBalancer, на этот раз адрес получен успешно***
```
[yc-user@vm-a ~]$ kubectl get svc pg1
NAME   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
pg1    LoadBalancer   10.96.137.134   10.95.101.29   5432:31609/TCP   6m11s
```



### **Проверка работы postgres с виртуалки в zone-a**
**устанавливаем клиента postgres**
```
[yc-user@vm-a ~]$ sudo bash
[root@vm-a yc-user]# dnf update -y
[root@vm-a yc-user]# dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@vm-a yc-user]# dnf -qy module disable postgresql
[root@vm-a yc-user]# dnf install postgresql16
[root@vm-a yc-user]# psql -V
psql (PostgreSQL) 16.6
```
**проверяем подключение к БД и создаем тестовую табличку**
```
[yc-user@vm-a ~]$ export PGPASSWORD="$(kubectl get secrets useradmin.pg1.credentials.postgresql.acid.zalan.do -o jsonpath='{.data.password}' | base64 -d)"
[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus
psql (16.6)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

otus=# \l
                                                       List of databases
   Name    |  Owner   | Encoding | Locale Provider |   Collate   |    Ctype    | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+-------------+-------------+------------+-----------+-----------------------
 otus      | userotus | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | 
 postgres  | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | 
 template0 | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |             |             |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |             |             |            |           | postgres=CTc/postgres
(4 rows)

otus=#
otus=# create table persons(id serial, first_name text, second_name text);
CREATE TABLE
otus=# insert into persons(first_name, second_name) values('ivan', 'ivanov');
INSERT 0 1
otus=# insert into persons(first_name, second_name) values('petr', 'petrov');
INSERT 0 1
```
**Проверка статуса нод**
```
[yc-user@vm-a ~]$ kubectl exec pg1-0 -- patronictl list
+ Cluster: pg1 (7452997215842893884) ---------+----+-----------+
| Member | Host         | Role    | State     | TL | Lag in MB |
+--------+--------------+---------+-----------+----+-----------+
| pg1-0  | 10.112.129.5 | Leader  | running   |  1 |           |
| pg1-1  | 10.112.128.5 | Replica | streaming |  1 |         0 |
| pg1-2  | 10.112.130.5 | Replica | streaming |  1 |         0 |
+--------+--------------+---------+-----------+----+-----------+
```
**Удаляем под pg1-0, чтобы произошло переключение**
```
[yc-user@vm-a ~]$ kubectl delete pod pg1-0 --wait=false
pod "pg1-0" deleted
[yc-user@vm-a ~]$ 
[yc-user@vm-a ~]$ kubectl exec pg1-1 -- patronictl list
+ Cluster: pg1 (7452997215842893884) ---------+----+-----------+
| Member | Host         | Role    | State     | TL | Lag in MB |
+--------+--------------+---------+-----------+----+-----------+
| pg1-0  |              | Replica |           |    |   unknown |
| pg1-1  | 10.112.128.5 | Leader  | running   |  2 |           |
| pg1-2  | 10.112.130.5 | Replica | streaming |  2 |         0 |
+--------+--------------+---------+-----------+----+-----------+
```
**Проверяем переключение лидера**
```
[yc-user@vm-a ~]$ kubectl exec pg1-1 -- patronictl list
+ Cluster: pg1 (7452997215842893884) ---------+----+-----------+
| Member | Host         | Role    | State     | TL | Lag in MB |
+--------+--------------+---------+-----------+----+-----------+
| pg1-0  | 10.112.129.6 | Replica | streaming |  2 |         0 |
| pg1-1  | 10.112.128.5 | Leader  | running   |  2 |           |
| pg1-2  | 10.112.130.5 | Replica | streaming |  2 |         0 |
+--------+--------------+---------+-----------+----+-----------+
```
**Проверяем доступность данных в тестовой табличке**
```
[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus -c 'SELECT * FROM persons'
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
**Проверяем ручной switchover лидера**
```
[yc-user@vm-a ~]$ kubectl exec -it pg1-1 -- patronictl switchover
Current cluster topology
+ Cluster: pg1 (7452997215842893884) ---------+----+-----------+
| Member | Host         | Role    | State     | TL | Lag in MB |
+--------+--------------+---------+-----------+----+-----------+
| pg1-0  | 10.112.129.6 | Replica | streaming |  2 |         0 |
| pg1-1  | 10.112.128.5 | Leader  | running   |  2 |           |
| pg1-2  | 10.112.130.5 | Replica | streaming |  2 |         0 |
+--------+--------------+---------+-----------+----+-----------+
Primary [pg1-1]: 
Candidate ['pg1-0', 'pg1-2'] []: pg1-0
When should the switchover take place (e.g. 2024-12-27T10:09 )  [now]: 
Are you sure you want to switchover cluster pg1, demoting current leader pg1-1? [y/N]: y
2024-12-27 09:09:58.58332 Successfully switched over to "pg1-0"
+ Cluster: pg1 (7452997215842893884) ---------+----+-----------+
| Member | Host         | Role    | State     | TL | Lag in MB |
+--------+--------------+---------+-----------+----+-----------+
| pg1-0  | 10.112.129.6 | Leader  | running   |  2 |           |
| pg1-1  | 10.112.128.5 | Replica | stopped   |    |   unknown |
| pg1-2  | 10.112.130.5 | Replica | streaming |  2 |         0 |
+--------+--------------+---------+-----------+----+-----------+
```
**Проверяем статус нод**
```
[yc-user@vm-a ~]$ kubectl exec pg1-1 -- patronictl list
+ Cluster: pg1 (7452997215842893884) ---------+----+-----------+
| Member | Host         | Role    | State     | TL | Lag in MB |
+--------+--------------+---------+-----------+----+-----------+
| pg1-0  | 10.112.129.6 | Leader  | running   |  3 |           |
| pg1-1  | 10.112.128.5 | Replica | streaming |  3 |         0 |
| pg1-2  | 10.112.130.5 | Replica | streaming |  3 |         0 |
+--------+--------------+---------+-----------+----+-----------+
```

**Для истории сохраним состояния элементов кластера pg1 в кластера k8s**
```
[yc-user@vm-a ~]$ kubectl get all -l cluster-name=pg1 -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP             NODE                        NOMINATED NODE   READINESS GATES
pod/pg1-0   1/1     Running   0          30m   10.112.129.6   cl1kmcbbctic30f4ju60-ofuw   <none>           <none>
pod/pg1-1   1/1     Running   0          68m   10.112.128.5   cl1kmcbbctic30f4ju60-irod   <none>           <none>
pod/pg1-2   1/1     Running   0          67m   10.112.130.5   cl1kmcbbctic30f4ju60-agul   <none>           <none>

NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE   SELECTOR
service/pg1          LoadBalancer   10.96.137.134   10.95.101.29   5432:31609/TCP   69m   <none>
service/pg1-config   ClusterIP      None            <none>         <none>           68m   <none>
service/pg1-repl     ClusterIP      10.96.172.143   <none>         5432/TCP         69m   application=spilo,cluster-name=pg1,spilo-role=replica

NAME                   READY   AGE   CONTAINERS   IMAGES
statefulset.apps/pg1   3/3     69m   postgres     ghcr.io/zalando/spilo-17:4.0-p2


[yc-user@vm-a ~]$ kubectl get secret -l cluster-name=pg1
NAME                                                 TYPE     DATA   AGE
postgres.pg1.credentials.postgresql.acid.zalan.do    Opaque   2      45m
standby.pg1.credentials.postgresql.acid.zalan.do     Opaque   2      45m
useradmin.pg1.credentials.postgresql.acid.zalan.do   Opaque   2      45m
userotus.pg1.credentials.postgresql.acid.zalan.do    Opaque   2      45m


[yc-user@vm-a ~]$ kubectl get pvc -l cluster-name=pg1
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
pgdata-pg1-0   Bound    pvc-6d04cf93-55fb-4899-8757-18b989e362f9   10Gi       RWO            yc-network-hdd   47m
pgdata-pg1-1   Bound    pvc-c187e3f7-aad4-4c8f-8875-c89338524aab   10Gi       RWO            yc-network-hdd   46m
pgdata-pg1-2   Bound    pvc-3c2ec10d-2c24-447c-a923-a35103a75335   10Gi       RWO            yc-network-hdd   45m
```

**На этом этапе у нас настроен postgresql кластер в зоне A**




###**Поднимаем кластер K8S в зоне B**
**Создаем подсеть для зоны otus-subnet-b**
```
[root@test2 hw-10]# yc vpc subnet create --name otus-subnet-b --zone ru-central1-b --range 10.95.102.0/24 --network-name otus-net --description "otus-subnet-b"
id: e2l9lt9futtcq8u77l50
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T09:41:04Z"
name: otus-subnet-b
description: otus-subnet-b
network_id: enpp8ckss7v07c9aea9i
zone_id: ru-central1-b
v4_cidr_blocks:
  - 10.95.102.0/24
```
**Создаем виртуальную машину VM-b**
```
[root@test2 hw-10]# yc compute instance create --name vm-b --hostname vm-b --zone ru-central1-b --cores 2 --memory 2 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=almalinux-8 --preemptible --network-interface subnet-name=otus-subnet-b,nat-ip-version=ipv4 --ssh-key /home/voronov/.ssh/id_rsa.pub
done (46s)
id: epdvu1f6kifpqhbdlhpu
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T09:42:19Z"
name: vm-b
zone_id: ru-central1-b
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
  device_name: epdk9o6ea6ihlic6fk0k
  auto_delete: true
  disk_id: epdk9o6ea6ihlic6fk0k
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1f:f0:5e:6a
    subnet_id: e2l9lt9futtcq8u77l50
    primary_v4_address:
      address: 10.95.102.13
      one_to_one_nat:
        address: 158.160.4.111
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: vm-b.ru-central1.internal
scheduling_policy:
  preemptible: true
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1
```

**Создаем сервисный аккаунт для кластера K8S**
```
[root@test2 hw-10]# FOLDER_ID=$(yc config get folder-id)
[root@test2 hw-10]# 
[root@test2 hw-10]# yc iam service-account create --name sa-k8s-pg2
done (1s)
id: ajel8hula3dces15jg51
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T09:44:20.140464872Z"
name: sa-k8s-pg2

[root@test2 hw-10]# SA_ID=$(yc iam service-account get --name sa-k8s-pg2 --format json | jq .id -r)
[root@test2 hw-10]# 
[root@test2 hw-10]# yc resource-manager folder add-access-binding --id $FOLDER_ID --role admin --subject serviceAccount:$SA_ID
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: admin
      subject:
        id: ajel8hula3dces15jg51
        type: serviceAccount

[root@test2 hw-10]# yc iam service-account list
+----------------------+------------+--------+---------------------+-----------------------+
|          ID          |    NAME    | LABELS |     CREATED AT      | LAST AUTHENTICATED AT |
+----------------------+------------+--------+---------------------+-----------------------+
| ajeccrfd9ev3mllbp346 | sa-k8s-pg1 |        | 2024-12-26 17:37:54 | 2024-12-27 09:30:00   |
| ajel8hula3dces15jg51 | sa-k8s-pg2 |        | 2024-12-27 09:44:20 |                       |
+----------------------+------------+--------+---------------------+-----------------------+
```

**Создаем кластер K8S в зоне ru-central1-b**
```
[root@test2 hw-10]# yc managed-kubernetes cluster create --name k8s-pg2 --network-name otus-net --zone ru-central1-b --subnet-name otus-subnet-b --service-account-id ${SA_ID} --node-service-account-id ${SA_ID} --cluster-ipv4-range 10.113.0.0/16 --service-ipv4-range 10.97.0.0/16
done (8m56s)
id: catkdo843inab3gs3q8e
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T10:11:57Z"
name: k8s-pg2
status: RUNNING
health: HEALTHY
network_id: enpp8ckss7v07c9aea9i
master:
  zonal_master:
    zone_id: ru-central1-b
    internal_v4_address: 10.95.102.12
  locations:
    - zone_id: ru-central1-b
      subnet_id: e2l9lt9futtcq8u77l50
  etcd_cluster_size: "1"
  version: "1.28"
  endpoints:
    internal_v4_endpoint: https://10.95.102.12
  master_auth:
    cluster_ca_certificate: |
      -----BEGIN CERTIFICATE-----
      MIIC5zCCAc+gAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
      cm5ldGVzMB4XDTI0MTIyNzEwMTE1OVoXDTM0MTIyNTEwMTE1OVowFTETMBEGA1UE
      AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALzQ
      tyc3rcw8sBoe6CP3jDTVXeykdQ8tBD4OIR2juUWhkBX+69ozz8RL2XxGs1TKdL0q
      07lzz+PS40G58rRMXdlWrUmnh07XVHVe1U6iNEU/fP4mwIb4cjU8D9WPph9pcskc
      1y7XCXVXCB7XYXnYQjlJfW9W9JqGqj//6bCam4xVWkQlvcBE1jZi+MowzcuQrIv5
      EYChDD0WAau2SG1THprwg5TI2XM6I+zpIjInjMqp58jK+EEpC+uzRtDTt0DRx3o8
      0p6H5UtUsvmbZOhKJQvx0ar/+AyNkIo7JPOXlhIbLwW5eNQx7vLVrkWxZNBYZ+jQ
      YvbCPSiJ/lvrwnYODgsCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
      /wQFMAMBAf8wHQYDVR0OBBYEFBzd/w8zwNpagVV7hjyE7jb2CvZyMA0GCSqGSIb3
      DQEBCwUAA4IBAQC5r0E/yvXkZOWKekSHuAqptM1XKjAzmqcrCy18RBAQCxHPQrXD
      SAByBpBYDTEBYWu8qm/n+dULj+3yTHMo3MPYHfvADYkZucltjiMWz9rtLu1wCaBs
      dfaIB8H9ZnGPEQ8bRPE4oLwsaOs6/lDcpmVi/C/c4SJXXMes+BNQrl2HYa9tyMQN
      xNWjnYHOuEUFd1QmyhR25SurKnOJg4ztMcyFGL6NpNfqRFVIRwNZtK/Br9JbFwTM
      1S25haybSFVJfnhzKDQzWpQ9fM4Ty3tipW3IrDITDT4aBcsWR1GKDZ7DSWei2OoS
      HwhqmWj4aJ9Txxo8aNdjivt1SNzDCvogyjRl
      -----END CERTIFICATE-----
  version_info:
    current_version: "1.28"
  maintenance_policy:
    auto_upgrade: true
    maintenance_window:
      anytime: {}
```
**Текущий список кластеров K8S**
```
[root@test2 hw-10]# yc managed-kubernetes cluster list
+----------------------+---------+---------------------+---------+---------+-------------------+----------------------+
|          ID          |  NAME   |     CREATED AT      | HEALTH  | STATUS  | EXTERNAL ENDPOINT |  INTERNAL ENDPOINT   |
+----------------------+---------+---------------------+---------+---------+-------------------+----------------------+
| cate9afnebuikl5mhao1 | k8s-pg1 | 2024-12-26 21:04:15 | HEALTHY | RUNNING |                   | https://10.95.101.16 |
| catkdo843inab3gs3q8e | k8s-pg2 | 2024-12-27 10:11:57 | HEALTHY | RUNNING |                   | https://10.95.102.12 |
+----------------------+---------+---------------------+---------+---------+-------------------+----------------------+
```
**Создаем воркер ноды**
```
[root@test2 hw-10]# yc managed-kubernetes node-group create --name k8s-pg2-worker --cluster-name k8s-pg2 --platform-id standard-v2 --preemptible --cores 2 --memory 4 --core-fraction 20 --disk-type network-hdd --disk-size=70G --fixed-size 3 --location subnet-name=otus-subnet-b,zone=ru-central1-b --async
id: catd2q8cm20ic3qmf4jr
description: Create node group
created_at: "2024-12-27T10:36:37.235061388Z"
created_by: ajenhnhv8so0beb1jbnf
modified_at: "2024-12-27T10:36:37.235061388Z"
metadata:
  '@type': type.googleapis.com/yandex.cloud.k8s.v1.CreateNodeGroupMetadata
  node_group_id: catmnqkcmgtinl984r32
```
**Проверяем статус нод обоих кластеров**
```
[root@test2 hw-10]# yc managed-kubernetes node-group list
+----------------------+----------------------+----------------+----------------------+---------------------+---------+------+
|          ID          |      CLUSTER ID      |      NAME      |  INSTANCE GROUP ID   |     CREATED AT      | STATUS  | SIZE |
+----------------------+----------------------+----------------+----------------------+---------------------+---------+------+
| cat9rl25vdaeqr2vmdoj | cate9afnebuikl5mhao1 | k8s-pg1-worker | cl1kmcbbctic30f4ju60 | 2024-12-27 06:28:59 | RUNNING |    3 |
| catmnqkcmgtinl984r32 | catkdo843inab3gs3q8e | k8s-pg2-worker | cl1sjc232c5bdi9utit4 | 2024-12-27 10:36:37 | RUNNING |    3 |
+----------------------+----------------------+----------------+----------------------+---------------------+---------+------+
```
**Также как для зоны-А добавляем маршрут по умолчанию для otus-subnet-b**
```
[root@test2 hw-10]# yc vpc subnet update otus-subnet-b --route-table-name=ext-route-table
done (3s)
id: e2l9lt9futtcq8u77l50
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T09:41:04Z"
name: otus-subnet-b
description: otus-subnet-b
network_id: enpp8ckss7v07c9aea9i
zone_id: ru-central1-b
v4_cidr_blocks:
  - 10.95.102.0/24
route_table_id: enpm2fqidc7klkd65psr
dhcp_options: {}
```
**Текущий список подсетей и роутов**
```
[root@test2 hw-10]# yc vpc subnet list
+----------------------+-----------------------------------------------------------+----------------------+----------------------+---------------+------------------+
|          ID          |                           NAME                            |      NETWORK ID      |    ROUTE TABLE ID    |     ZONE      |      RANGE       |
+----------------------+-----------------------------------------------------------+----------------------+----------------------+---------------+------------------+
| e2l9lt9futtcq8u77l50 | otus-subnet-b                                             | enpp8ckss7v07c9aea9i | enpm2fqidc7klkd65psr | ru-central1-b | [10.95.102.0/24] |
| e9b0s006hf6j7l86k01a | otus-subnet-a                                             | enpp8ckss7v07c9aea9i | enpm2fqidc7klkd65psr | ru-central1-a | [10.95.101.0/24] |
| e9ban7jl0k2foa0jltsv | k8s-cluster-cate9afnebuikl5mhao1-pod-cidr-reservation     | enpp8ckss7v07c9aea9i |                      | ru-central1-a | [10.112.0.0/16]  |
| e9bcqvt36ve1cfifbmm2 | k8s-cluster-catkdo843inab3gs3q8e-pod-cidr-reservation     | enpp8ckss7v07c9aea9i |                      | ru-central1-a | [10.113.0.0/16]  |
| e9biak00nqmte2oph30t | k8s-cluster-catkdo843inab3gs3q8e-service-cidr-reservation | enpp8ckss7v07c9aea9i |                      | ru-central1-a | [10.97.0.0/16]   |
| e9bmj842f12hk3r48406 | k8s-cluster-cate9afnebuikl5mhao1-service-cidr-reservation | enpp8ckss7v07c9aea9i |                      | ru-central1-a | [10.96.0.0/16]   |
+----------------------+-----------------------------------------------------------+----------------------+----------------------+---------------+------------------+
```



### **Используя VM-b в зоне ru-central1-b настраиваем инструменты для установки standby кластера postgresql**

**Формируем конфиг kubectl для подключения к кластеру pg2**
```
[root@test2 hw-10]# yc managed-kubernetes cluster get-credentials k8s-pg2 --internal --kubeconfig=./config_pg2
```
**Копируем конфиг на VM-b**
```
[root@test2 hw-10]# scp ./config_pg2   yc-user@158.160.4.111:~/

[root@test2 hw-10]# ssh yc-user@158.160.4.111
[yc-user@vm-b ~]$ mkdir $HOME/.kube
[yc-user@vm-b ~]$ mv config_pg2 $HOME/.kube/config
```
**Устанавливаем и инициализируем утилиту yc на VM-b**
```
[yc-user@vm-b ~]$ curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
[yc-user@vm-b ~]$ . /home/yc-user/.bashrc
[yc-user@vm-b ~]$ yc init

[yc-user@vm-b ~]$ yc config list
token: y0_AgAAAAAVU########################3
cloud-id: b1gd4gg##############
folder-id: b1gidntdt0mi4p0gpkh5
compute-default-zone: ru-central1-b
```
**Устанавливаем утилиту kubectl**
```
[yc-user@vm-b ~]$ curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
[yc-user@vm-b ~]$ sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
[yc-user@vm-b ~]$ sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
[yc-user@vm-b ~]$ kubectl version --client
Client Version: v1.28.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```
**Подправим путь до "yc" в конфиге .kube/config и затем проверяем подключение к кластеру **
```
[yc-user@vm-b ~]$ vi .kube/config 
[yc-user@vm-b ~]$ kubectl cluster-info
Kubernetes control plane is running at https://10.95.102.12
CoreDNS is running at https://10.95.102.12/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[yc-user@vm-b ~]$ kubectl get nodes -o wide 
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1sjc232c5bdi9utit4-alyr   Ready    <none>   16m   v1.28.9   10.95.102.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-196-generic   containerd://1.6.28
cl1sjc232c5bdi9utit4-irih   Ready    <none>   16m   v1.28.9   10.95.102.4    <none>        Ubuntu 20.04.6 LTS   5.4.0-196-generic   containerd://1.6.28
cl1sjc232c5bdi9utit4-yzuw   Ready    <none>   16m   v1.28.9   10.95.102.19   <none>        Ubuntu 20.04.6 LTS   5.4.0-196-generic   containerd://1.6.28
```
**Устанавливаем клиента postgres на VM-b**
```
[root@vm-b yc-user]# dnf update -y
[root@vm-b yc-user]# dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@vm-b yc-user]# dnf -qy module disable postgresql
[root@vm-b yc-user]# dnf install postgresql16

[root@vm-b yc-user]# psql -V
psql (PostgreSQL) 16.6
```

**Устанавливаем helm на VM-b**
```
[yc-user@vm-b ~]$ curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
[yc-user@vm-b ~]$ sudo ln -s /usr/local/bin/helm /usr/bin/helm
[yc-user@vm-b ~]$ helm version
version.BuildInfo{Version:"v3.16.4", GitCommit:"7877b45b63f95635153b29a42c0c2f4273ec45ca", GitTreeState:"clean", GoVersion:"go1.22.7"}
```
**Установка postgres оператора в managed-k8s в ru-central1-b**
```
[yc-user@vm-b ~]$ helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
"postgres-operator-charts" has been added to your repositories
[yc-user@vm-b ~]$ helm install postgres-operator postgres-operator-charts/postgres-operator
NAME: postgres-operator
LAST DEPLOYED: Fri Dec 27 11:28:41 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that postgres-operator has started, run:

  kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"

[yc-user@vm-b ~]$ kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"
NAME                                 READY   STATUS    RESTARTS   AGE
postgres-operator-5f587dbd7f-9j24x   1/1     Running   0          22s
```
**Создаем манифест для создания standby кластера в зоне B**
```
[yc-user@vm-b ~]$ cat pg2-standby.yaml 
kind: "postgresql"
apiVersion: "acid.zalan.do/v1"
metadata:
  name: "pg2"
  namespace: "default"
  labels:
    team: otus
spec:
  env:
  - name: STANDBY_PRIMARY_SLOT_NAME
    value: patroni
  teamId: "otus"
  enableMasterLoadBalancer: true
  databases:
    otus: userotus
  masterServiceAnnotations:
    yandex.cloud/load-balancer-type: internal
    yandex.cloud/subnet-id: e2l9lt9futtcq8u77l50
  postgresql:
    version: "16"
    parameters:
      wal_log_hints: "true"
      log_statement: "all"
      # Memory Configuration
      shared_buffers: "768MB"
      effective_cache_size: "2GB"
      work_mem: "8MB"
      maintenance_work_mem: "154MB"
      # Checkpoint Related Configuration
      min_wal_size: "2GB"
      max_wal_size: "3GB"
      checkpoint_completion_target: "0.9"
      wal_buffers: "-1"
      # Network Related Configuration
      listen_addresses: '*'
      max_connections: "100"
      # Storage Configuration
      random_page_cost: "4.0"
      effective_io_concurrency: "2"
      # Worker Processes Configuration
      max_worker_processes: "8"
      max_parallel_workers_per_gather: "2"
      max_parallel_workers: "2"
  numberOfInstances: 3
  volume:
    size: "5Gi"
  standby:
    standby_host: "10.95.101.29"
    standby_port: "5432"
  resources:
    requests:
      cpu: 1000m
      memory: 1000Mi
    limits:
      cpu: 2000m
      memory: 3000Mi
```
**Запускаем создаение standby кластера**
```
[yc-user@vm-b ~]$ kubectl create -f pg2-standby.yaml
```

**Видим ошибку создания PVC**
```
0s          Warning   ProvisioningFailed              persistentvolumeclaim/pgdata-pg2-0        failed to provision volume with StorageClass "yc-network-hdd": rpc error: code = ResourceExhausted desc = Disk creation (name:"pvc-02c382bd-7cb1-47da-86b9-e3cd0731af8d" capacity_range:<required_bytes:10737418240 > volume_capabilities:<mount:<fs_type:"ext4" > access_mode:<mode:SINGLE_NODE_WRITER > > parameters:<key:"type" value:"network-hdd" > accessibility_requirements:<requisite:<segments:<key:"failure-domain.beta.kubernetes.io/zone" value:"ru-central1-b" > > preferred:<segments:<key:"failure-domain.beta.kubernetes.io/zone" value:"ru-central1-b" > > > ) failed: request-id = b3f11e47-2cf9-4dcd-b1ae-70b0c598a9a8 rpc error: code = ResourceExhausted desc = The limit on total size of network-hdd disks has exceeded.
```
**Изменяем дефолтный SC на yc-network-ssd**
```
[yc-user@vm-b ~]$ kubectl get sc
NAME                           PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
yc-network-hdd                 disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   87m
yc-network-nvme                disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   87m
yc-network-ssd (default)       disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   87m
yc-network-ssd-io-m3           disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   87m
yc-network-ssd-nonreplicated   disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   87m
```
**Удаляем предыдущий манифест и загружаем его снова, на этот раз поды поднялись**
```
[yc-user@vm-b ~]$ kubectl get pods -l cluster-name=pg2 -o wide 
NAME    READY   STATUS    RESTARTS   AGE     IP             NODE                        NOMINATED NODE   READINESS GATES
pg2-0   1/1     Running   0          7m40s   10.113.130.5   cl1sjc232c5bdi9utit4-alyr   <none>           <none>
pg2-1   1/1     Running   0          5m30s   10.113.132.6   cl1sjc232c5bdi9utit4-yzuw   <none>           <none>
pg2-2   1/1     Running   0          4m24s   10.113.131.5   cl1sjc232c5bdi9utit4-irih   <none>           <none>
```
**Но реплика не подключается с мастер кластеру**
```
[yc-user@vm-b ~]$ kubectl logs pg2-0 | grep FATAL | head -n 3
pg_basebackup: error: connection to server at "10.95.101.29", port 5432 failed: FATAL:  password authentication failed for user "standby"
connection to server at "10.95.101.29", port 5432 failed: FATAL:  no pg_hba.conf entry for replication connection from host "10.95.101.17", user "standby", no encryption
pg_basebackup: error: connection to server at "10.95.101.29", port 5432 failed: FATAL:  password authentication failed for user "standby"
```
**Перенесем реквизиты подключения из секретов кластера pg1 в кластер pg2**
```
[yc-user@vm-b ~]$ kubectl get secrets -l cluster-name=pg2
NAME                                                TYPE     DATA   AGE
postgres.pg2.credentials.postgresql.acid.zalan.do   Opaque   2      15m
standby.pg2.credentials.postgresql.acid.zalan.do    Opaque   2      15m
```
```
[yc-user@vm-b ~]$ kubectl edit secrets postgres.pg2.credentials.postgresql.acid.zalan.do
[yc-user@vm-b ~]$ kubectl edit secrets standby.pg2.credentials.postgresql.acid.zalan.do
```
**Удаляем поды, чтобы они пересоздались**
```
[yc-user@vm-b ~]$ kubectl delete pods pg2-0 --wait=false
pod "pg2-0" deleted
[yc-user@vm-b ~]$ kubectl delete pods pg2-1 --wait=false
pod "pg2-1" deleted
[yc-user@vm-b ~]$ kubectl delete pods pg2-2 --wait=false
pod "pg2-2" deleted
```
**Проверяем статус нод, видим что пострес в статусе starting**
```
[yc-user@vm-b ~]$ kubectl exec pg2-0 -- patronictl list
+ Cluster: pg2 (7452997215842893884) ----+------------------+----+-----------+
| Member | Host         | Role           | State            | TL | Lag in MB |
+--------+--------------+----------------+------------------+----+-----------+
| pg2-0  | 10.113.130.6 | Standby Leader | starting         |    |           |
| pg2-1  | 10.113.131.6 | Replica        | creating replica |    |   unknown |
| pg2-2  | 10.113.132.7 | Replica        | creating replica |    |   unknown |
+--------+--------------+----------------+------------------+----+-----------+
```
**Проверяем логи, видим, что мы забыли создать слот патрони в мастер сластере**
```
[yc-user@vm-b ~]$ kubectl exec -it pg2-0 -- grep FATAL /home/postgres/pgdata/pgroot/pg_log/postgresql-5.csv | tail -n 2
2024-12-27 12:05:55.788 UTC,"postgres","postgres",960,"[local]",676e9823.3c0,2,"",2024-12-27 12:05:55 UTC,,0,FATAL,57P03,"the database system is starting up",,,,,,,,,"","client backend",,0
2024-12-27 12:05:56.201 UTC,,,961,,676e9824.3c1,1,,2024-12-27 12:05:56 UTC,,0,FATAL,08P01,"could not start WAL streaming: ERROR:  replication slot ""patroni"" does not exist",,,,,,,,,"","walreceiver",,0
```
**Добавляем слот patroni в кластер pg1**
```
[root@test2 hw-10]# ssh yc-user@89.169.128.66
[yc-user@vm-a ~]$ kubectl exec -it pg1-0 -- patronictl edit-config
E1187: Failed to source defaults.vim
Press ENTER or type command to continue
--- 
+++ 
@@ -44,3 +44,6 @@
   use_slots: true
 retry_timeout: 10
 ttl: 30
+slots:
+  patroni:
+    type: physical

Apply these changes? [y/N]: y
Configuration changed
```
**Проверяем статус standby кластера, на этот раз все ок**
```
[yc-user@vm-b ~]$ kubectl exec pg2-0 -- patronictl list
+ Cluster: pg2 (7452997215842893884) ----+-----------+----+-----------+
| Member | Host         | Role           | State     | TL | Lag in MB |
+--------+--------------+----------------+-----------+----+-----------+
| pg2-0  | 10.113.130.6 | Standby Leader | streaming |  3 |           |
| pg2-1  | 10.113.131.6 | Replica        | streaming |  3 |         0 |
| pg2-2  | 10.113.132.7 | Replica        | streaming |  3 |         0 |
+--------+--------------+----------------+-----------+----+-----------+
```
**Для истории сохраним список процессов**
```
[yc-user@vm-b ~]$ kubectl exec pg2-0 -- ps -axf
    PID TTY      STAT   TIME COMMAND
   2158 ?        Rs     0:00 ps -axf
      1 ?        Ss     0:00 /usr/bin/dumb-init -c --rewrite 1:0 -- /bin/sh /launch.sh
      7 ?        S      0:00 /bin/sh /launch.sh
     21 ?        S      0:00  \_ /usr/bin/runsvdir -P /etc/service
     22 ?        Ss     0:00      \_ runsv pgqd
     25 ?        S      0:00      |   \_ /bin/bash /scripts/patroni_wait.sh --role primary -- /usr/bin/pgqd /home/postgres/pgq_ticker.ini
   2157 ?        S      0:00      |       \_ sleep 60
     23 ?        Ss     0:00      \_ runsv patroni
     24 ?        Sl     0:02          \_ /usr/bin/python3 /usr/local/bin/patroni /home/postgres/postgres.yml
     70 ?        S      0:00 /usr/lib/postgresql/16/bin/postgres -D /home/postgres/pgdata/pgroot/data --config-file=/home/postgres/pgdata/pgroot/data/postgresql.conf --listen_addresses=* --port=5432 --cluster_name=pg2 --wal_level=replica --hot_standby=on --max_connections=100 --max_wal_senders=10 --max_prepared_transactions=0 --max_locks_per_transaction=64 --track_commit_timestamp=off --max_replication_slots=10 --max_worker_processes=8 --wal_log_hints=true
     72 ?        Ss     0:00  \_ postgres: pg2: logger 
     75 ?        Ss     0:00  \_ postgres: pg2: checkpointer 
     76 ?        Ss     0:00  \_ postgres: pg2: background writer 
     77 ?        Ss     0:00  \_ postgres: pg2: startup recovering 00000003000000000000000A
     78 ?        Ssl    0:02  \_ postgres: pg2: bg_mon 
   2092 ?        Ss     0:00  \_ postgres: pg2: walreceiver streaming 0/A000148
   2098 ?        Ss     0:00  \_ postgres: pg2: postgres postgres [local] idle
   2104 ?        Ss     0:00  \_ postgres: pg2: walsender standby 10.95.102.19(34084) streaming 0/A000148
   2105 ?        Ss     0:00  \_ postgres: pg2: walsender standby 10.95.102.4(50900) streaming 0/A000148
   2108 ?        Ss     0:00  \_ postgres: pg2: postgres postgres [local] idle
```
**Аналогично кластеру pg1 удаляем из манифеста svc/pg1 атрибут loadbalancerSourceRanges, и затем проверяем что IP получен**  
```
[yc-user@vm-b ~]$ kubectl get svc
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes          ClusterIP      10.97.128.1     <none>        443/TCP          114m
pg2                 LoadBalancer   10.97.138.205   10.95.102.7   5432:30182/TCP   35m
pg2-config          ClusterIP      None            <none>        <none>           30m
pg2-repl            ClusterIP      10.97.212.10    <none>        5432/TCP         35m
postgres-operator   ClusterIP      10.97.250.148   <none>        8080/TCP         46m
```

### **Проверка репликации из кластера PG1 в PG2**

**В кластере PG1 добавляем две строчки**
```
[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus -c 'SELECT * FROM persons'
Password for user useradmin: 
[yc-user@vm-a ~]$ export PGPASSWORD="$(kubectl get secrets useradmin.pg1.credentials.postgresql.acid.zalan.do -o jsonpath='{.data.password}' | base64 -d)"
[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus -c 'SELECT * FROM persons'
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)

[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus -c "INSERT INTO persons(first_name, second_name) values('odin', 'odinov');"
INSERT 0 1
[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus -c "INSERT INTO persons(first_name, second_name) values('vtor', 'vtorov');"
INSERT 0 1
[yc-user@vm-a ~]$ psql -h 10.95.101.29 -U useradmin otus -c 'SELECT * FROM persons'
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | odin       | odinov
  4 | vtor       | vtorov
(4 rows)
```
**Для удобства проверки данных в кластере PG2 воспользуемся VM-a**
```
[yc-user@vm-a ~]$ psql -h 10.95.102.7 -U useradmin otus -c 'SELECT * FROM persons'
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | odin       | odinov
  4 | vtor       | vtorov
(4 rows)
```
**Как видим данные успешно среплицировались в кластер PG2**



### **Создание TCP балансира в ЯО для доступа к мастер кластеру**
- создадим дополнительный сервисы типа LoadBalancer в обоих кластерах K8S  
- сервисы кроме порта 5432 будут пробрасывать порт 8008, для контроля состояния patroni
- в TCP балансире ЯО настроим контроль url "/primary"

**Создаем манифесты сервисов LB**
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    yandex.cloud/load-balancer-type: internal
    yandex.cloud/subnet-id: e2l9lt9futtcq8u77l50
  labels:
    team: otus
  name: pg
  namespace: default
spec:
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ports:
  - name: postgresql
    nodePort: 32432
    port: 5432
    protocol: TCP
    targetPort: 5432
  - name: patroni
    nodePort: 32408
    port: 8008
    protocol: TCP
    targetPort: 8008
  sessionAffinity: None
  type: LoadBalancer
  selector:
    application: spilo
    cluster-name: pg2
    spilo-role: master
```

```
apiVersion: v1
kind: Service
metadata:
  annotations:
    yandex.cloud/load-balancer-type: internal
    yandex.cloud/subnet-id: e9b0s006hf6j7l86k01a
  labels:
    team: otus
  name: pg
  namespace: default
spec:
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ports:
  - name: postgresql
    nodePort: 32432
    port: 5432
    protocol: TCP
    targetPort: 5432
  - name: patroni
    nodePort: 32408
    port: 8008
    protocol: TCP
    targetPort: 8008
  sessionAffinity: None
  type: LoadBalancer
  selector:
    application: spilo
    cluster-name: pg1
    spilo-role: master
```
**В эвентах появились ошибки изза ограничения по кол-ву сервисов LoadBalancers**
```
70s         Warning   SyncLoadBalancerFailed   service/pg    Error syncing load balancer: failed to ensure load balancer: failed to ensure cloud loadbalancer: failed to start cloud lb creation: request-id = 1f317249-b9e5-4de1-b63c-f5d494f00e7c rpc error: code = ResourceExhausted desc = Quota limit ylb.networkLoadBalancers.count exceeded
```
**Удаляем использование LoadBalancers в манифестах postgresql и через некоторе время проверяем**
```
[yc-user@vm-a ~]$ kubectl get svc
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                         AGE
kubernetes          ClusterIP      10.96.128.1     <none>         443/TCP                         16h
pg                  LoadBalancer   10.96.153.191   10.95.101.38   5432:32432/TCP,8008:32408/TCP   7s
pg1                 ClusterIP      10.96.137.134   <none>         5432/TCP                        6h10m
pg1-config          ClusterIP      None            <none>         <none>                          6h9m
pg1-repl            ClusterIP      10.96.172.143   <none>         5432/TCP                        6h10m
postgres-operator   ClusterIP      10.96.238.226   <none>         8080/TCP                        6h37m
```
```
[yc-user@vm-b ~]$ kubectl get svc
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                         AGE
kubernetes          ClusterIP      10.97.128.1     <none>         443/TCP                         3h40m
pg                  LoadBalancer   10.97.157.241   10.95.102.38   5432:32432/TCP,8008:32408/TCP   6m17s
pg2                 ClusterIP      10.97.180.46    <none>         5432/TCP                        39s
pg2-config          ClusterIP      None            <none>         <none>                          135m
pg2-repl            ClusterIP      10.97.212.10    <none>         5432/TCP                        141m
postgres-operator   ClusterIP      10.97.250.148   <none>         8080/TCP                        152m
```
**видим, что IP получили**

**Удостоверяемся что по "/primary" мастер отдает 200, а standby 503**
**При этом также проверяем что и мастер и standby по "leader" оба отдают 200**
```
[yc-user@vm-a ~]$ curl -D - http://10.95.101.38:8008/primary; echo ""
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.10.12
Date: Fri, 27 Dec 2024 14:08:39 GMT
Content-Type: application/json

{"state": "running", "postmaster_start_time": "2024-12-27 08:33:48.962687+00:00", "role": "primary", "server_version": 160006, "xlog": {"location": 201326592}, "timeline": 3, "replication": [{"usename": "standby", "application_name": "pg1-2", "client_addr": "10.95.101.17", "state": "streaming", "sync_state": "async", "sync_priority": 0}, {"usename": "standby", "application_name": "pg1-1", "client_addr": "10.95.101.8", "state": "streaming", "sync_state": "async", "sync_priority": 0}], "dcs_last_seen": 1735308514, "database_system_identifier": "7452997215842893884", "patroni": {"version": "4.0.4", "scope": "pg1", "name": "pg1-0"}}


[yc-user@vm-a ~]$ curl -D - http://10.95.101.38:8008/leader; echo ""
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.10.12
Date: Fri, 27 Dec 2024 14:08:45 GMT
Content-Type: application/json

{"state": "running", "postmaster_start_time": "2024-12-27 08:33:48.962687+00:00", "role": "primary", "server_version": 160006, "xlog": {"location": 201326592}, "timeline": 3, "replication": [{"usename": "standby", "application_name": "pg1-2", "client_addr": "10.95.101.17", "state": "streaming", "sync_state": "async", "sync_priority": 0}, {"usename": "standby", "application_name": "pg1-1", "client_addr": "10.95.101.8", "state": "streaming", "sync_state": "async", "sync_priority": 0}], "dcs_last_seen": 1735308524, "database_system_identifier": "7452997215842893884", "patroni": {"version": "4.0.4", "scope": "pg1", "name": "pg1-0"}}


[yc-user@vm-a ~]$ curl -D - http://10.95.102.38:8008/primary; echo ""
HTTP/1.0 503 Service Unavailable
Server: BaseHTTP/0.6 Python/3.10.12
Date: Fri, 27 Dec 2024 14:09:11 GMT
Content-Type: application/json

{"state": "running", "postmaster_start_time": "2024-12-27 12:11:49.654730+00:00", "role": "standby_leader", "server_version": 160006, "xlog": {"received_location": 201326592, "replayed_location": 201326592, "replayed_timestamp": "2024-12-27 12:39:24.894359+00:00", "paused": false}, "timeline": 3, "replication": [{"usename": "standby", "application_name": "pg2-0", "client_addr": "10.95.102.25", "state": "streaming", "sync_state": "async", "sync_priority": 0}, {"usename": "standby", "application_name": "pg2-2", "client_addr": "10.95.102.19", "state": "streaming", "sync_state": "async", "sync_priority": 0}], "dcs_last_seen": 1735308549, "database_system_identifier": "7452997215842893884", "patroni": {"version": "4.0.4", "scope": "pg2", "name": "pg2-1"}}


[yc-user@vm-a ~]$ curl -D - http://10.95.102.38:8008/leader; echo ""
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.10.12
Date: Fri, 27 Dec 2024 14:09:18 GMT
Content-Type: application/json

{"state": "running", "postmaster_start_time": "2024-12-27 12:11:49.654730+00:00", "role": "standby_leader", "server_version": 160006, "xlog": {"received_location": 201326592, "replayed_location": 201326592, "replayed_timestamp": "2024-12-27 12:39:24.894359+00:00", "paused": false}, "timeline": 3, "replication": [{"usename": "standby", "application_name": "pg2-0", "client_addr": "10.95.102.25", "state": "streaming", "sync_state": "async", "sync_priority": 0}, {"usename": "standby", "application_name": "pg2-2", "client_addr": "10.95.102.19", "state": "streaming", "sync_state": "async", "sync_priority": 0}], "dcs_last_seen": 1735308549, "database_system_identifier": "7452997215842893884", "patroni": {"version": "4.0.4", "scope": "pg2", "name": "pg2-1"}}
```

**Создаем целевую группу для TCP балансира ЯО**
```
[root@test2 hw-10]# yc load-balancer target-group create pglb --target subnet-id=e9b0s006hf6j7l86k01a,address=10.95.101.38    --target subnet-id=e2l9lt9futtcq8u77l50,address=10.95.102.38
done (1s)
id: enp3e6dj9dspkfc1f20u
folder_id: b1gidntdt0mi4p0gpkh5
created_at: "2024-12-27T15:04:31Z"
name: pglb
region_id: ru-central1
targets:
  - subnet_id: e2l9lt9futtcq8u77l50
    address: 10.95.102.38
  - subnet_id: e9b0s006hf6j7l86k01a
    address: 10.95.101.38
```
**Создаем TCP балансира "pglb"**
```
[root@test2 hw-10]# yc load-balancer network-load-balancer create pglb  --listener name=pglb,port=5432,target-port=5432,protocol=tcp,external-ip-version=ipv4    --target-group target-group-id=enp3e6dj9dspkfc1f20u,healthcheck-name=pglb,healthcheck-interval=2s,healthcheck-timeout=1s,healthcheck-unhealthythreshold=3,healthcheck-healthythreshold=3,healthcheck-http-port=8008,healthcheck-http-path=/primary
ERROR: rpc error: code = ResourceExhausted desc = Quota limit ylb.networkLoadBalancers.count exceeded
```
**В итоге столкнулнись с ограничениями ЯО**
- по дефолту только два LB, а дополнительные нужно запрашивать через ТП
- TCP балансировку нельзя настроить на "svc/Loadbalancer k8s"   
  ( т.е. можно только на IP VM ) 
  https://yandex.cloud/ru/docs/network-load-balancer/concepts/ 
  ( возможно я ошибаюсь )

**Итоги**
- попробовал postgres-operator от zalando
- попробовал k8s от ЯО
- попытался настроить TCP балансир 
- также изучил рекомендации от патрони   
  https://patroni.readthedocs.io/en/latest/ha_multi_dc.html  
  где описана методика преключения при "multi_dc"

