// Example of creating Nodes MySQL.
resource "yandex_mdb_mysql_cluster" "cluster-mysql" {
  name                = "cluster-mysql"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.vpc-network.id
  version             = "8.0"
  deletion_protection = "false"

  backup_window_start {
    hours   = 23
    minutes = 59
  }
  resources {
    resource_preset_id = "b1.medium" // Intel Broadwell 50%
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  maintenance_window {
    type = "ANYTIME"
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.private1.id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private2.id
  }

}

// Creatin` DB
resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.cluster-mysql.id
  name       = "netology_db"
  depends_on = [yandex_mdb_mysql_cluster.cluster-mysql]
}

// user
resource "yandex_mdb_mysql_user" "db_user" {
  cluster_id = yandex_mdb_mysql_cluster.cluster-mysql.id
  name       = "db_user"
  password   = "password"


  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }


  global_permissions = ["PROCESS"]

  authentication_plugin = "SHA256_PASSWORD"
}

