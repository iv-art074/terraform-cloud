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
Результат:  
```
iv_art@Pappa-wsl:~/terraform-cloud/15-4$ yc managed-mysql cluster list
+----------------------+---------------+---------------------+--------+---------+
|          ID          |     NAME      |     CREATED AT      | HEALTH | STATUS  |
+----------------------+---------------+---------------------+--------+---------+
| c9qfp05re2t5qjeqgrh2 | cluster-mysql | 2022-09-07 13:18:37 | ALIVE  | RUNNING |
+----------------------+---------------+---------------------+--------+---------+

iv_art@Pappa-wsl:~/terraform-cloud/15-4$ yc managed-mysql hosts list --cluster-name cluster-mysql
+-------------------------------------------+----------------------+---------+--------+---------------+-----------+--------------------+----------+-----------------+
|                   NAME                    |      CLUSTER ID      |  ROLE   | HEALTH |    ZONE ID    | PUBLIC IP | REPLICATION SOURCE | PRIORITY | BACKUP PRIORITY |
+-------------------------------------------+----------------------+---------+--------+---------------+-----------+--------------------+----------+-----------------+
| rc1a-vu07j0hjq6fx7dyv.mdb.yandexcloud.net | c9qfp05re2t5qjeqgrh2 | MASTER  | ALIVE  | ru-central1-a | false     |                    |        0 |               0 |
| rc1b-g4dlmnxeti922qzr.mdb.yandexcloud.net | c9qfp05re2t5qjeqgrh2 | REPLICA | ALIVE  | ru-central1-b | false     |                    |        0 |               0 |
+-------------------------------------------+----------------------+---------+--------+---------------+-----------+--------------------+----------+-----------------+

iv_art@Pappa-wsl:~/terraform-cloud/15-4$ yc managed-mysql user list --cluster-name cluster-mysql
+---------+-------------+
|  NAME   | PERMISSIONS |
+---------+-------------+
| db_user | netology_db |
+---------+-------------+

iv_art@Pappa-wsl:~/terraform-cloud/15-4$ yc managed-mysql database list --cluster-name cluster-mysql
+-------------+----------------------+
|    NAME     |      CLUSTER ID      |
+-------------+----------------------+
| netology_db | c9qfp05re2t5qjeqgrh2 |
+-------------+----------------------+
```
![image](https://user-images.githubusercontent.com/87374285/188891891-36eca1ff-ebbe-4eee-adef-54a7fb15195d.png)  



