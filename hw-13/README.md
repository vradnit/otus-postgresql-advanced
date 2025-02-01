# **HW-13 | Постгрес в minikube**


## **Цель:**
Развернуть Постгрес в миникубе


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Устанавливаем minikube
Разворачиваем PostgreSQL 14 через манифест

Задание повышенной сложности*
Разворачиваем PostgreSQL 14 с помощью helm


## **Выполнение ДЗ**

### **Установка minikube**

**Скачиваем minikube**
```
[root@test2 hw-13]# curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube
[root@test2 hw-13]# mv minikube /usr/local/bin/
[root@test2 hw-13]# minikube version
minikube version: v1.35.0
commit: dd5d320e41b5451cdf3c01891bc4e13d189586ed-dirty
```
**Скачиваем kubectl**
```
[root@test2 hw-13]# curl -LO https://dl.k8s.io/release/`curl -LS https://dl.k8s.io/release/stable.txt`/bin/linux/amd64/kubectl
[root@test2 hw-13]# chmod +x ./kubectl
[root@test2 hw-13]# mv ./kubectl /usr/local/bin/kubectl

[root@test2 hw-13]# kubectl version --client
Client Version: v1.32.1
Kustomize Version: v5.5.0
```

**Устанавливаем minikube**
```
[voronov@test2 hw-13]$ minikube start
😄  minikube v1.35.0 on Fedora 41
✨  Automatically selected the docker driver. Other choices: kvm2, qemu2, virtualbox, ssh
❗  docker is currently using the btrfs storage driver, setting preload=false
📌  Using Docker driver with root privileges
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.46 ...
🔥  Creating docker container (CPUs=2, Memory=7900MB) ...
🐳  Preparing Kubernetes v1.32.0 on Docker 27.4.1 ...
    ▪ kubelet.localStorageCapacityIsolation=false
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

**Проверяем подключение к minikube**
```
[voronov@test2 hw-13]$ kubectl get nodes
NAME       STATUS   ROLES           AGE     VERSION
minikube   Ready    control-plane   2m32s   v1.32.0
[voronov@test2 hw-13]$ 
[voronov@test2 hw-13]$ kubectl get pods -A 
NAMESPACE     NAME                               READY   STATUS    RESTARTS       AGE
kube-system   coredns-668d6bf9bc-m2bcs           1/1     Running   0              2m27s
kube-system   etcd-minikube                      1/1     Running   0              2m35s
kube-system   kube-apiserver-minikube            1/1     Running   0              2m35s
kube-system   kube-controller-manager-minikube   1/1     Running   0              2m35s
kube-system   kube-proxy-l4w7k                   1/1     Running   0              2m28s
kube-system   kube-scheduler-minikube            1/1     Running   0              2m35s
kube-system   storage-provisioner                1/1     Running   1 (116s ago)   2m32s
[voronov@test2 hw-13]$ 
[voronov@test2 hw-13]$ kubectl get sc 
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  2m51s
```

### **Вариант создания postgres statefullset через YML манифесты**

**Создаем два ямл манифеста**
```
[voronov@test2 hw-13]$ ll ./manifests/
total 8
-rw-r--r--. 1 voronov voronov 1272 фев  1 15:23 postgres.yaml
-rw-r--r--. 1 voronov voronov  146 янв 26 23:04 secrets.yaml
```
в postgres.yaml описаны манифесты service и statefulset,  
в secrets.yaml описаны секреты для инициализации БД  
в качестве образа будем использовать образ postgres:16.3  
тип сервиса вберем NodePort для того чтобы подключится к БД без "portforward"


**Загружаем манифесты в minikube**
```
[voronov@test2 hw-13]$ kubectl create -f ./manifests/secrets.yaml 
secret/postgres-secrets created
[voronov@test2 hw-13]$ kubectl create -f ./manifests/postgres.yaml 
service/postgres created
statefulset.apps/postgres created
```

**Проверяем, что все создалось**
```
[voronov@test2 hw-13]$ oc get statefulset -o wide 
NAME       READY   AGE     CONTAINERS   IMAGES
postgres   1/1     5d16h   postgres     postgres:16.3
 
[voronov@test2 hw-13]$ oc get pods -o wide 
NAME         READY   STATUS    RESTARTS        AGE    IP           NODE       NOMINATED NODE   READINESS GATES
postgres-0   1/1     Running   1 (3d21h ago)   5d6h   10.244.0.7   minikube   <none>           <none>
 
[voronov@test2 hw-13]$ oc get service 
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          5d16h
postgres     NodePort    10.110.231.196   <none>        5432:30432/TCP   5d16h
 
[voronov@test2 hw-13]$ oc get pvc
NAME                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
postgres-data-postgres-0   Bound    pvc-d1dff19b-038e-4991-b685-72c227831bdf   1Gi        RWO            standard       <unset>                 5d6h
 
[voronov@test2 hw-13]$ oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                              STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-d1dff19b-038e-4991-b685-72c227831bdf   1Gi        RWO            Delete           Bound    default/postgres-data-postgres-0   standard       <unset>                          5d6h

[voronov@test2 hw-13]$ oc get secrets
NAME               TYPE     DATA   AGE
postgres-secrets   Opaque   2      5d16h

[voronov@test2 hw-13]$ oc get nodes -o wide 
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION            CONTAINER-RUNTIME
minikube   Ready    control-plane   5d16h   v1.32.0   192.168.49.2   <none>        Ubuntu 22.04.5 LTS   6.12.10-200.fc41.x86_64   docker://27.4.1
```

**Используя IP ноды [192.168.49.2] и порт на ноде [30432] подключаемся к БД и создаем тестовую таблицу**
```
[voronov@test2 hw-13]$ export PGPASSWORD="$(oc get secret postgres-secrets -o jsonpath='{ .data.POSTGRES_PASSWORD }' | base64 -d)"
[voronov@test2 hw-13]$ PGUSER="$(oc get secret postgres-secrets -o jsonpath='{ .data.POSTGRES_USER }' | base64 -d)"
[voronov@test2 hw-13]$ psql -h 192.168.49.2 -p 30432 -U $PGUSER postgres postgres
psql: warning: extra command-line argument "postgres" ignored
psql (16.3)
Type "help" for help.

postgres=# CREATE DATABASE otus;
CREATE DATABASE
postgres=# \c otus 
You are now connected to database "otus" as user "postgres".
otus=# create table persons(id serial, first_name text, second_name text);
CREATE TABLE
otus=# insert into persons(first_name, second_name) values('ivan', 'ivanov');
INSERT 0 1
otus=# insert into persons(first_name, second_name) values('petr', 'petrov');
INSERT 0 1
otus=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)

otus=# 
```

**Для теста удалим под и проверим, что данные сохранились**
```
[voronov@test2 hw-13]$ oc get pods 
NAME         READY   STATUS    RESTARTS        AGE
postgres-0   1/1     Running   1 (3d21h ago)   5d6h

[voronov@test2 hw-13]$ oc delete pod postgres-0
pod "postgres-0" deleted
 
[voronov@test2 hw-13]$ oc get pods 
NAME         READY   STATUS    RESTARTS   AGE
postgres-0   1/1     Running   0          3s

[voronov@test2 hw-13]$ psql -h 192.168.49.2 -p 30432 -U $PGUSER otus -c 'select * from persons'
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
Все ОК, данные на месте



### **Вариант создания postgres statefulset HELM чартом**

**Создаем темплейт helm чарта**
```
[voronov@test2 hw-13]$ helm create otus-postgres
```

**Используя полученный темплейт и используя наработки из предыдущего варианта получаем чарт**
```
tree ./otus-postgres/
./otus-postgres/
├── Chart.yaml
├── templates
│   ├── _helpers.tpl
│   ├── NOTES.txt
│   ├── secrets.yaml
│   ├── service.yaml
│   └── statefulset.yaml
└── values.yaml
```
в values.yaml вынесем кастомизируемые параметры:
- имя образа и тег
- переменные секрета
- имя storageclass
- размер pvc
- праметры сервиса
- и стандартные параметры ( ресуры, аффинити и т.д. ) 


**Устанавливаем helm chart**
```
[voronov@test2 hw-13]$ helm install db -n otus ./otus-postgres/
NAME: db
LAST DEPLOYED: Sat Feb  1 19:27:22 2025
NAMESPACE: otus
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
export NODE_PORT=$(kubectl get --namespace otus -o jsonpath="{.spec.ports[0].nodePort}" services db-otus-postgres)
  export NODE_IP=$(kubectl get nodes --namespace otus -o jsonpath="{.items[0].status.addresses[0].address}")
  export PGPASSWORD="$(oc get secret --namespace otus db-otus-postgres-secrets -o jsonpath='{ .data.POSTGRES_PASSWORD }' | base64 -d)"
  export PGUSER="$(oc get secret --namespace otus db-otus-postgres-secrets -o jsonpath='{ .data.POSTGRES_USER }' | base64 -d)"
  psql -h $NODE_IP -p $NODE_PORT -U $PGUSER postgres
```
**Используя комманды из выводы, проверяем коннект до базы**
```
[voronov@test2 hw-13]$ export NODE_PORT=$(kubectl get --namespace otus -o jsonpath="{.spec.ports[0].nodePort}" services db-otus-postgres)
  export NODE_IP=$(kubectl get nodes --namespace otus -o jsonpath="{.items[0].status.addresses[0].address}")
  export PGPASSWORD="$(oc get secret --namespace otus db-otus-postgres-secrets -o jsonpath='{ .data.POSTGRES_PASSWORD }' | base64 -d)"
  export PGUSER="$(oc get secret --namespace otus db-otus-postgres-secrets -o jsonpath='{ .data.POSTGRES_USER }' | base64 -d)"
  psql -h $NODE_IP -p $NODE_PORT -U $PGUSER postgres
psql (16.3)
Type "help" for help.

postgres=# \l
                                                      List of databases
   Name    |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+------------+------------+------------+-----------+-----------------------
 postgres  | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | 
 template0 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/postgres          +
           |          |          |                 |            |            |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/postgres          +
           |          |          |                 |            |            |            |           | postgres=CTc/postgres
(3 rows)

postgres=# CREATE DATABASE otus ;
CREATE DATABASE
```
Все ОК, база доступна


**Проверяем сущности, созданные при инсталяции через helm**
```
[voronov@test2 hw-13]$ helm list -n otus 
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART             	APP VERSION
db  	otus     	1       	2025-02-01 19:27:22.597431496 +0300 MSK	deployed	otus-postgres-16.3	16.3       
 

[voronov@test2 hw-13]$ kubectl get statefulset -n otus -o wide 
NAME               READY   AGE     CONTAINERS      IMAGES
db-otus-postgres   1/1     3m41s   otus-postgres   postgres:16.3

[voronov@test2 hw-13]$ kubectl get svc -n otus -o wide 
NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE     SELECTOR
db-otus-postgres   NodePort   10.109.39.165   <none>        5432:30432/TCP   3m47s   app.kubernetes.io/instance=db,app.kubernetes.io/name=otus-postgres
 
[voronov@test2 hw-13]$ kubectl get pods -n otus -o wide 
NAME                 READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
db-otus-postgres-0   1/1     Running   0          3m52s   10.244.0.25   minikube   <none>           <none>
 
[voronov@test2 hw-13]$ kubectl get secrets -n otus -o wide 
NAME                       TYPE                 DATA   AGE
db-otus-postgres-secrets   Opaque               2      4m4s
sh.helm.release.v1.db.v1   helm.sh/release.v1   1      4m4s
```
Как видно все сущности на месте.

