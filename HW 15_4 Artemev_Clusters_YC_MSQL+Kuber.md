### Задание 1. Яндекс.Облако (обязательное к выполнению)  
##### Настроить с помощью Terraform кластер баз данных MySQL:  
Используя настройки VPC с предыдущих ДЗ, добавить дополнительно подсеть private в разных зонах, чтобы обеспечить отказоустойчивость  
Разместить ноды кластера MySQL в разных подсетях  
Необходимо предусмотреть репликацию с произвольным временем технического обслуживания  
Использовать окружение PRESTABLE, платформу Intel Broadwell с производительностью 50% CPU и размером диска 20 Гб  
Задать время начала резервного копирования - 23:59  
Включить защиту кластера от непреднамеренного удаления  
Создать БД с именем netology_db c логином и паролем  

Разбил подсеть private на private1 и private2 и создал конфигурацию:  
```
iv_art@Pappa-wsl:~/terraform-cloud/15-4$ cat cluster_msql.tf
// Example of creating Nodes MySQL.
resource "yandex_mdb_mysql_cluster" "cluster-mysql" {
  name                = "cluster-mysql"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.vpc-network.id
  version             = "8.0"
  deletion_protection = "true"

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.private1.id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private2.id
  }

  resources {
    resource_preset_id = "b1.medium" // Intel Broadwell 50%
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  maintenance_window {
    type = "ANYTIME"
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
```

