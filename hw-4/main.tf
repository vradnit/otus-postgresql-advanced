resource "yandex_mdb_postgresql_cluster" "pg_cluster_1" {
  name        = "otushw4"
  environment = "PRESTABLE"
  network_id  = local.vpc_id
  security_group_ids = local.sg_id
  folder_id = local.folder_id
  config {
    version = 14
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-hdd"
      disk_size          = 20
    }
    postgresql_config = {
      max_connections                   = 100
      enable_parallel_hash              = true
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries          = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 1
  }

  host {
    zone  = var.default_zone
    subnet_id = local.subnet_id
    assign_public_ip = true
    name = "db-master"
  }
}

resource "yandex_mdb_postgresql_user" "user_owner" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster_1.id
  name       = var.user_owner_username
  password   = var.user_owner_passwd
}

resource "yandex_mdb_postgresql_database" "db1" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster_1.id
  name       = var.db_name
  owner      = yandex_mdb_postgresql_user.user_owner.name
  lc_collate = "ru_RU.UTF-8"
  lc_type    = "ru_RU.UTF-8"
  extension {
    name = "amcheck"
  }
}

provider "postgresql" {
  host            = yandex_mdb_postgresql_cluster.pg_cluster_1.host[0].fqdn
  port            = 6432
  database        = yandex_mdb_postgresql_database.db1.name
  username        = yandex_mdb_postgresql_user.user_owner.name
  password        = yandex_mdb_postgresql_user.user_owner.password
  sslmode         = "require"
  connect_timeout = 20
}

resource "null_resource" "restore_database" {
  depends_on = [ yandex_mdb_postgresql_database.db1, yandex_mdb_postgresql_user.user_owner ]
  provisioner "local-exec" {
    command = "psql -f otus.sql"
    environment = {
      PGHOST = yandex_mdb_postgresql_cluster.pg_cluster_1.host[0].fqdn
      PGPORT = 6432
      PGDATABASE = yandex_mdb_postgresql_database.db1.name
      PGUSER = yandex_mdb_postgresql_user.user_owner.name
      PGPASSWORD = yandex_mdb_postgresql_user.user_owner.password
    }
  }
}
