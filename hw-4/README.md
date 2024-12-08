# **HW-4 | PostgreSQL и VKcloud, GCP, AWS, ЯО, Sbercloud**


## **Цель:**
Научиться пользоваться PostgreSQL based и like сервисами в VKcloud, GCP, AWS, ЯО, Sbercloud


## **Описание/Пошаговая инструкция выполнения домашнего задания:**
Воспользоваться PostgreSQL based и like сервисами в Одном или Более облаков.  
Описать что и как делали и с какими проблемами столкнулись  

## Выполнение ДЗ

### Развернем Posgtres Managed инстанс в ЯО использую terraform 

### Подготовка конфигурации для использования terraform
  Используя доку с https://yandex.cloud/ru/docs/ydb/terraform/install устанавливаем terraform
```
# terraform -version | head -n1
Terraform v1.9.8
```

  Используя доку и примеры:
```
https://github.com/comol/YCMDBScripts/blob/master/Terraform/ProdPostgres/main.tf
https://habr.com/ru/companies/nixys/articles/721404/
```
  Подготавливаем конфиги для terraform
```
# tree 
.
├── locals.tf
├── main.tf
├── network.tf
├── otus.sql
├── outputs.tf
├── terraform.tf
└── variables.tf
```
, предназначение файлов следующее:
terraform.tf - описывает конфигурацию провайдера yandex-cloud  
main.tf - описывает основную конфигурацию postgres кластера   
network.tf - описывает настройки vpc network и security_group  
locals.tf и variables.tf- описывают используемые переменные  
outputs.tf - используется для вывода имени хоста ( для внешнего подключения)  
otus.sql - дамп базы с тестовыми данными, т.е. после создания кластера,  
ожидаем, что в БД "otus" появится таблица "persons" с тестовыми данными

В файлах конфигурации пропишем:
- использовать окружение "PRESTABLE"
- исподьзовать версию postgres 14
- disk_size 20G
- disk_type_id "network-hdd"
- тип VM "s2.micro"
- разрешим подключение c IP "78.85.16.136"
- установим расширение "amcheck"
( остальную конфигурацию будем передавать через переменные окружения )


### Создаем выделенную директорию "otus-hw-4"
```
[root@test2 hw-4]# yc resource folder create otus-hw-4
done (1s)
id: b1g3p5h57m7n0qsc9u5a
cloud_id: b1gd4ggkqe80tpb8tph8
created_at: "2024-12-08T14:07:46Z"
name: otus-hw-4
status: ACTIVE

[root@test2 hw-4]# yc config set folder-id b1g3p5h57m7n0qsc9u5a

[root@test2 hw-4]# yc config list
token: y0_###################################################
cloud-id: b1gd4ggkqe80tpb8tph8
folder-id: b1g3p5h57m7n0qsc9u5a
compute-default-zone: ru-central1-a
```

### Экспортируем переменные окружения
( как видно, они транслируются в переменные terraform )
```
[root@test2 hw-4]# export YC_TOKEN=$(yc iam create-token)
[root@test2 hw-4]# export TF_VAR_cloud_id=$(yc config get cloud-id)
[root@test2 hw-4]# export TF_VAR_folder_id=$(yc config get folder-id)

[root@test2 hw-4]# export TF_VAR_user_owner_username='otus'
[root@test2 hw-4]# export TF_VAR_user_owner_passwd='########'
[root@test2 hw-4]# export TF_VAR_db_name='otus'
```

### Инициализируем компоненты terraform
```
[root@test2 hw-4]# terraform init
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Reusing previous version of cyrilgdn/postgresql from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed yandex-cloud/yandex v0.134.0
- Using previously-installed cyrilgdn/postgresql v1.25.0
- Using previously-installed hashicorp/null v3.2.3
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Проверяем "план"
```
[root@test2 hw-4]# terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.restore_database will be created
  + resource "null_resource" "restore_database" {
      + id = (known after apply)
    }

  # yandex_mdb_postgresql_cluster.pg_cluster_1 will be created
  + resource "yandex_mdb_postgresql_cluster" "pg_cluster_1" {
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + environment         = "PRESTABLE"
      + folder_id           = "b1g3p5h57m7n0qsc9u5a"
      + health              = (known after apply)
      + host_group_ids      = (known after apply)
      + host_master_name    = (known after apply)
      + id                  = (known after apply)
      + labels              = (known after apply)
      + name                = "otushw4"
      + network_id          = (known after apply)
      + security_group_ids  = (known after apply)
      + status              = (known after apply)

      + config {
          + autofailover              = (known after apply)
          + backup_retain_period_days = (known after apply)
          + postgresql_config         = {
              + "default_transaction_isolation" = "TRANSACTION_ISOLATION_READ_COMMITTED"
              + "enable_parallel_hash"          = "true"
              + "max_connections"               = "100"
              + "shared_preload_libraries"      = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
            }
          + version                   = "14"

          + access (known after apply)

          + backup_window_start (known after apply)

          + disk_size_autoscaling (known after apply)

          + performance_diagnostics (known after apply)

          + resources {
              + disk_size          = 20
              + disk_type_id       = "network-hdd"
              + resource_preset_id = "s2.micro"
            }
        }

      + host {
          + assign_public_ip   = true
          + fqdn               = (known after apply)
          + name               = "db-master"
          + replication_source = (known after apply)
          + role               = (known after apply)
          + subnet_id          = (known after apply)
          + zone               = "ru-central1-a"
        }

      + maintenance_window {
          + day  = "SAT"
          + hour = 1
          + type = "WEEKLY"
        }
    }

  # yandex_mdb_postgresql_database.db1 will be created
  + resource "yandex_mdb_postgresql_database" "db1" {
      + cluster_id          = (known after apply)
      + deletion_protection = "unspecified"
      + id                  = (known after apply)
      + lc_collate          = "ru_RU.UTF-8"
      + lc_type             = "ru_RU.UTF-8"
      + name                = "otus"
      + owner               = "otus"

      + extension {
          + name    = "amcheck"
            # (1 unchanged attribute hidden)
        }
    }

  # yandex_mdb_postgresql_user.user_owner will be created
  + resource "yandex_mdb_postgresql_user" "user_owner" {
      + cluster_id          = (known after apply)
      + conn_limit          = (known after apply)
      + deletion_protection = "unspecified"
      + id                  = (known after apply)
      + login               = true
      + name                = "otus"
      + password            = (sensitive value)
    }

  # yandex_vpc_network.this[0] will be created
  + resource "yandex_vpc_network" "this" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "VPC vpc-otus-hw-4"
      + folder_id                 = "b1g3p5h57m7n0qsc9u5a"
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "vpc-otus-hw-4"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_security_group.security_group[0] will be created
  + resource "yandex_vpc_security_group" "security_group" {
      + created_at  = (known after apply)
      + description = "Securtiy group securtiy-group-otus-hw-4"
      + folder_id   = "b1g3p5h57m7n0qsc9u5a"
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "securtiy-group-otus-hw-4"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow any"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "icmp"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ICMP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "postgresql"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 6432
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "78.85.16.136/32",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # yandex_vpc_subnet.subnet[0] will be created
  + resource "yandex_vpc_subnet" "subnet" {
      + created_at     = (known after apply)
      + description    = "Subnet subnet-otus-hw-4"
      + folder_id      = "b1g3p5h57m7n0qsc9u5a"
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-otus-hw-4"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.91.91.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + db_host = (known after apply)

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```


### Запускаем создаение postgres-managed кластера
```
[root@test2 hw-4]# terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.restore_database will be created
  + resource "null_resource" "restore_database" {
      + id = (known after apply)
    }

  # yandex_mdb_postgresql_cluster.pg_cluster_1 will be created
  + resource "yandex_mdb_postgresql_cluster" "pg_cluster_1" {
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + environment         = "PRESTABLE"
      + folder_id           = "b1g3p5h57m7n0qsc9u5a"
      + health              = (known after apply)
      + host_group_ids      = (known after apply)
      + host_master_name    = (known after apply)
      + id                  = (known after apply)
      + labels              = (known after apply)
      + name                = "otushw4"
      + network_id          = (known after apply)
      + security_group_ids  = (known after apply)
      + status              = (known after apply)

      + config {
          + autofailover              = (known after apply)
          + backup_retain_period_days = (known after apply)
          + postgresql_config         = {
              + "default_transaction_isolation" = "TRANSACTION_ISOLATION_READ_COMMITTED"
              + "enable_parallel_hash"          = "true"
              + "max_connections"               = "100"
              + "shared_preload_libraries"      = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
            }
          + version                   = "14"

          + access (known after apply)

          + backup_window_start (known after apply)

          + disk_size_autoscaling (known after apply)

          + performance_diagnostics (known after apply)

          + resources {
              + disk_size          = 20
              + disk_type_id       = "network-hdd"
              + resource_preset_id = "s2.micro"
            }
        }

      + host {
          + assign_public_ip   = true
          + fqdn               = (known after apply)
          + name               = "db-master"
          + replication_source = (known after apply)
          + role               = (known after apply)
          + subnet_id          = (known after apply)
          + zone               = "ru-central1-a"
        }

      + maintenance_window {
          + day  = "SAT"
          + hour = 1
          + type = "WEEKLY"
        }
    }

  # yandex_mdb_postgresql_database.db1 will be created
  + resource "yandex_mdb_postgresql_database" "db1" {
      + cluster_id          = (known after apply)
      + deletion_protection = "unspecified"
      + id                  = (known after apply)
      + lc_collate          = "ru_RU.UTF-8"
      + lc_type             = "ru_RU.UTF-8"
      + name                = "otus"
      + owner               = "otus"

      + extension {
          + name    = "amcheck"
            # (1 unchanged attribute hidden)
        }
    }

  # yandex_mdb_postgresql_user.user_owner will be created
  + resource "yandex_mdb_postgresql_user" "user_owner" {
      + cluster_id          = (known after apply)
      + conn_limit          = (known after apply)
      + deletion_protection = "unspecified"
      + id                  = (known after apply)
      + login               = true
      + name                = "otus"
      + password            = (sensitive value)
    }

  # yandex_vpc_network.this[0] will be created
  + resource "yandex_vpc_network" "this" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "VPC vpc-otus-hw-4"
      + folder_id                 = "b1g3p5h57m7n0qsc9u5a"
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "vpc-otus-hw-4"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_security_group.security_group[0] will be created
  + resource "yandex_vpc_security_group" "security_group" {
      + created_at  = (known after apply)
      + description = "Securtiy group securtiy-group-otus-hw-4"
      + folder_id   = "b1g3p5h57m7n0qsc9u5a"
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "securtiy-group-otus-hw-4"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow any"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "icmp"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ICMP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "postgresql"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 6432
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "78.85.16.136/32",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # yandex_vpc_subnet.subnet[0] will be created
  + resource "yandex_vpc_subnet" "subnet" {
      + created_at     = (known after apply)
      + description    = "Subnet subnet-otus-hw-4"
      + folder_id      = "b1g3p5h57m7n0qsc9u5a"
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-otus-hw-4"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.91.91.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + db_host = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_vpc_network.this[0]: Creating...
yandex_vpc_network.this[0]: Creation complete after 2s [id=enp849p98047n95bgsvi]
yandex_vpc_subnet.subnet[0]: Creating...
yandex_vpc_security_group.security_group[0]: Creating...
yandex_vpc_subnet.subnet[0]: Creation complete after 1s [id=e9bls5mnd5f8fnh5vucu]
yandex_vpc_security_group.security_group[0]: Creation complete after 2s [id=enpoeubmj3mfooiu7731]
yandex_mdb_postgresql_cluster.pg_cluster_1: Creating...
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [1m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [1m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [1m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [1m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [1m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [1m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [2m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [2m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [2m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [2m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [2m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [2m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [3m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [3m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [3m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [3m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [3m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [3m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [4m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [4m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [4m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [4m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [4m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [4m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [5m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [5m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [5m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [5m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [5m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [5m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [6m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [6m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [6m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [6m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [6m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [6m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [7m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [7m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still creating... [7m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Creation complete after 7m26s [id=c9qmak3m3hh92rt53ijq]
yandex_mdb_postgresql_user.user_owner: Creating...
yandex_mdb_postgresql_user.user_owner: Still creating... [10s elapsed]
yandex_mdb_postgresql_user.user_owner: Still creating... [20s elapsed]
yandex_mdb_postgresql_user.user_owner: Creation complete after 24s [id=c9qmak3m3hh92rt53ijq:otus]
yandex_mdb_postgresql_database.db1: Creating...
yandex_mdb_postgresql_database.db1: Still creating... [10s elapsed]
yandex_mdb_postgresql_database.db1: Still creating... [20s elapsed]
yandex_mdb_postgresql_database.db1: Creation complete after 23s [id=c9qmak3m3hh92rt53ijq:otus]
null_resource.restore_database: Creating...
null_resource.restore_database: Provisioning with 'local-exec'...
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database (local-exec): (output suppressed due to sensitive value in config)
null_resource.restore_database: Creation complete after 1s [id=6998830679094962251]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

db_host = "rc1a-mpkahubwh13nk7qp.mdb.yandexcloud.net"
```


### Проверка созданного кластера

Используя вывод имени хоста из предыдущего шага, подключаемся к БД,
и проверяем доступность таблицы "public.persons"
```
[root@test2 hw-4]# psql -h rc1a-mpkahubwh13nk7qp.mdb.yandexcloud.net -p 6432 -U otus -d otus -W
Password: 
psql (14.3, server 14.13 (Ubuntu 14.13-201-yandex.53339.2c27a43bea))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

otus=> \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | otus     | UTF8     | ru_RU.UTF-8 | ru_RU.UTF-8 | =T/otus              +
           |          |          |             |             | otus=CTc/otus        +
           |          |          |             |             | postgres=c/otus      +
           |          |          |             |             | admin=c/otus         +
           |          |          |             |             | mdb_odyssey=c/otus   +
           |          |          |             |             | monitor=c/otus
 postgres  | postgres | UTF8     | C           | C           | 
 template0 | postgres | UTF8     | C           | C           | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | C           | C           | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

otus=> \dt
        List of relations
 Schema |  Name   | Type  | Owner 
--------+---------+-------+-------
 public | persons | table | otus
(1 row)

otus=> select * from public.persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | petrov
  2 | andrey     | vtorov
  3 | alexey     | tretiy
(3 rows)

otus=> INSERT INTO persons(first_name, second_name) values('indiana', 'djons');
INSERT 0 1
otus=> 
otus=> select * from public.persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | petrov
  2 | andrey     | vtorov
  3 | alexey     | tretiy
  4 | indiana    | djons
(4 rows)
```
  заодно проверим версию созданного кластера и список доступных extension:
```
otus=> SELECT version();
                                                                      version                                                                      
---------------------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 14.13 (Ubuntu 14.13-201-yandex.53339.2c27a43bea) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit
(1 row)

otus=> SELECT * FROM pg_extension;
  oid  | extname | extowner | extnamespace | extrelocatable | extversion | extconfig | extcondition 
-------+---------+----------+--------------+----------------+------------+-----------+--------------
 14396 | plpgsql |       10 |           11 | f              | 1.0        |           | 
 16552 | amcheck |       10 |         2200 | t              | 1.3        |           | 
(2 rows)

otus=> \q
```

 Как видим заполненная таблица присутствует и доступна на запись.


### Удаляем инстанс postgres-managed
```
[root@test2 hw-4]# terraform destroy
yandex_vpc_network.this[0]: Refreshing state... [id=enp849p98047n95bgsvi]
yandex_vpc_subnet.subnet[0]: Refreshing state... [id=e9bls5mnd5f8fnh5vucu]
yandex_vpc_security_group.security_group[0]: Refreshing state... [id=enpoeubmj3mfooiu7731]
yandex_mdb_postgresql_cluster.pg_cluster_1: Refreshing state... [id=c9qmak3m3hh92rt53ijq]
yandex_mdb_postgresql_user.user_owner: Refreshing state... [id=c9qmak3m3hh92rt53ijq:otus]
yandex_mdb_postgresql_database.db1: Refreshing state... [id=c9qmak3m3hh92rt53ijq:otus]
null_resource.restore_database: Refreshing state... [id=6998830679094962251]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # null_resource.restore_database will be destroyed
  - resource "null_resource" "restore_database" {
      - id = "6998830679094962251" -> null
    }

  # yandex_mdb_postgresql_cluster.pg_cluster_1 will be destroyed
  - resource "yandex_mdb_postgresql_cluster" "pg_cluster_1" {
      - created_at          = "2024-12-08T14:17:43Z" -> null
      - deletion_protection = false -> null
      - environment         = "PRESTABLE" -> null
      - folder_id           = "b1g3p5h57m7n0qsc9u5a" -> null
      - health              = "ALIVE" -> null
      - host_group_ids      = [] -> null
      - host_master_name    = "db-master" -> null
      - id                  = "c9qmak3m3hh92rt53ijq" -> null
      - labels              = {} -> null
      - name                = "otushw4" -> null
      - network_id          = "enp849p98047n95bgsvi" -> null
      - security_group_ids  = [
          - "enpoeubmj3mfooiu7731",
        ] -> null
      - status              = "RUNNING" -> null
        # (1 unchanged attribute hidden)

      - config {
          - autofailover              = true -> null
          - backup_retain_period_days = 7 -> null
          - postgresql_config         = {
              - "default_transaction_isolation" = "TRANSACTION_ISOLATION_READ_COMMITTED"
              - "enable_parallel_hash"          = "true"
              - "max_connections"               = "100"
              - "password_encryption"           = "1"
              - "shared_preload_libraries"      = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
            } -> null
          - version                   = "14" -> null

          - access {
              - data_lens     = false -> null
              - data_transfer = false -> null
              - serverless    = false -> null
              - web_sql       = false -> null
            }

          - backup_window_start {
              - hours   = 0 -> null
              - minutes = 0 -> null
            }

          - disk_size_autoscaling {
              - disk_size_limit           = 0 -> null
              - emergency_usage_threshold = 0 -> null
              - planned_usage_threshold   = 0 -> null
            }

          - performance_diagnostics {
              - enabled                      = false -> null
              - sessions_sampling_interval   = 60 -> null
              - statements_sampling_interval = 600 -> null
            }

          - resources {
              - disk_size          = 20 -> null
              - disk_type_id       = "network-hdd" -> null
              - resource_preset_id = "s2.micro" -> null
            }
        }

      - host {
          - assign_public_ip        = true -> null
          - fqdn                    = "rc1a-mpkahubwh13nk7qp.mdb.yandexcloud.net" -> null
          - name                    = "db-master" -> null
          - priority                = 0 -> null
          - role                    = "MASTER" -> null
          - subnet_id               = "e9bls5mnd5f8fnh5vucu" -> null
          - zone                    = "ru-central1-a" -> null
            # (2 unchanged attributes hidden)
        }

      - maintenance_window {
          - day  = "SAT" -> null
          - hour = 1 -> null
          - type = "WEEKLY" -> null
        }
    }

  # yandex_mdb_postgresql_database.db1 will be destroyed
  - resource "yandex_mdb_postgresql_database" "db1" {
      - cluster_id          = "c9qmak3m3hh92rt53ijq" -> null
      - deletion_protection = "unspecified" -> null
      - id                  = "c9qmak3m3hh92rt53ijq:otus" -> null
      - lc_collate          = "ru_RU.UTF-8" -> null
      - lc_type             = "ru_RU.UTF-8" -> null
      - name                = "otus" -> null
      - owner               = "otus" -> null
        # (1 unchanged attribute hidden)

      - extension {
          - name    = "amcheck" -> null
            # (1 unchanged attribute hidden)
        }
    }

  # yandex_mdb_postgresql_user.user_owner will be destroyed
  - resource "yandex_mdb_postgresql_user" "user_owner" {
      - cluster_id          = "c9qmak3m3hh92rt53ijq" -> null
      - conn_limit          = 50 -> null
      - deletion_protection = "unspecified" -> null
      - grants              = [] -> null
      - id                  = "c9qmak3m3hh92rt53ijq:otus" -> null
      - login               = true -> null
      - name                = "otus" -> null
      - password            = (sensitive value) -> null
      - settings            = {} -> null
    }

  # yandex_vpc_network.this[0] will be destroyed
  - resource "yandex_vpc_network" "this" {
      - created_at                = "2024-12-08T14:17:40Z" -> null
      - default_security_group_id = "enp24l20v8i6ae10k495" -> null
      - description               = "VPC vpc-otus-hw-4" -> null
      - folder_id                 = "b1g3p5h57m7n0qsc9u5a" -> null
      - id                        = "enp849p98047n95bgsvi" -> null
      - labels                    = {} -> null
      - name                      = "vpc-otus-hw-4" -> null
      - subnet_ids                = [
          - "e9bls5mnd5f8fnh5vucu",
        ] -> null
    }

  # yandex_vpc_security_group.security_group[0] will be destroyed
  - resource "yandex_vpc_security_group" "security_group" {
      - created_at  = "2024-12-08T14:17:43Z" -> null
      - description = "Securtiy group securtiy-group-otus-hw-4" -> null
      - folder_id   = "b1g3p5h57m7n0qsc9u5a" -> null
      - id          = "enpoeubmj3mfooiu7731" -> null
      - labels      = {} -> null
      - name        = "securtiy-group-otus-hw-4" -> null
      - network_id  = "enp849p98047n95bgsvi" -> null
      - status      = "ACTIVE" -> null

      - egress {
          - description       = "Allow any" -> null
          - from_port         = -1 -> null
          - id                = "enp9b1ot79lddv03m14m" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "ANY" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }

      - ingress {
          - description       = "icmp" -> null
          - from_port         = -1 -> null
          - id                = "enp937esv8279g2rnjq0" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "ICMP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "postgresql" -> null
          - from_port         = -1 -> null
          - id                = "enphhups7f1tgjk6eui6" -> null
          - labels            = {} -> null
          - port              = 6432 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "78.85.16.136/32",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
    }

  # yandex_vpc_subnet.subnet[0] will be destroyed
  - resource "yandex_vpc_subnet" "subnet" {
      - created_at     = "2024-12-08T14:17:42Z" -> null
      - description    = "Subnet subnet-otus-hw-4" -> null
      - folder_id      = "b1g3p5h57m7n0qsc9u5a" -> null
      - id             = "e9bls5mnd5f8fnh5vucu" -> null
      - labels         = {} -> null
      - name           = "subnet-otus-hw-4" -> null
      - network_id     = "enp849p98047n95bgsvi" -> null
      - v4_cidr_blocks = [
          - "10.91.91.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-a" -> null
        # (1 unchanged attribute hidden)
    }

Plan: 0 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  - db_host = "rc1a-mpkahubwh13nk7qp.mdb.yandexcloud.net" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

null_resource.restore_database: Destroying... [id=6998830679094962251]
null_resource.restore_database: Destruction complete after 0s
yandex_mdb_postgresql_database.db1: Destroying... [id=c9qmak3m3hh92rt53ijq:otus]
yandex_mdb_postgresql_database.db1: Still destroying... [id=c9qmak3m3hh92rt53ijq:otus, 10s elapsed]
yandex_mdb_postgresql_database.db1: Still destroying... [id=c9qmak3m3hh92rt53ijq:otus, 20s elapsed]
yandex_mdb_postgresql_database.db1: Destruction complete after 25s
yandex_mdb_postgresql_user.user_owner: Destroying... [id=c9qmak3m3hh92rt53ijq:otus]
yandex_mdb_postgresql_user.user_owner: Still destroying... [id=c9qmak3m3hh92rt53ijq:otus, 10s elapsed]
yandex_mdb_postgresql_user.user_owner: Still destroying... [id=c9qmak3m3hh92rt53ijq:otus, 20s elapsed]
yandex_mdb_postgresql_user.user_owner: Destruction complete after 22s
yandex_mdb_postgresql_cluster.pg_cluster_1: Destroying... [id=c9qmak3m3hh92rt53ijq]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 1m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 1m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 1m20s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 1m30s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 1m40s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 1m50s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 2m0s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Still destroying... [id=c9qmak3m3hh92rt53ijq, 2m10s elapsed]
yandex_mdb_postgresql_cluster.pg_cluster_1: Destruction complete after 2m13s
yandex_vpc_subnet.subnet[0]: Destroying... [id=e9bls5mnd5f8fnh5vucu]
yandex_vpc_security_group.security_group[0]: Destroying... [id=enpoeubmj3mfooiu7731]
yandex_vpc_security_group.security_group[0]: Destruction complete after 1s
yandex_vpc_subnet.subnet[0]: Destruction complete after 3s
yandex_vpc_network.this[0]: Destroying... [id=enp849p98047n95bgsvi]
yandex_vpc_network.this[0]: Destruction complete after 2s

Destroy complete! Resources: 7 destroyed.
```

