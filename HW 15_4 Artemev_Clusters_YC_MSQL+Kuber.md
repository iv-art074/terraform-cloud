### Задание 1. Яндекс.Облако (обязательное к выполнению)  
##### 1. Настроить с помощью Terraform кластер баз данных MySQL:  
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

### 2.Настроить с помощью Terraform кластер Kubernetes  
##### Используя настройки VPC с предыдущих ДЗ, добавить дополнительно 2 подсети public в разных зонах, чтобы обеспечить отказоустойчивость  
Создать отдельный сервис-аккаунт с необходимыми правами  
Создать региональный мастер kubernetes с размещением нод в разных 3 подсетях  
Добавить возможность шифрования ключом из KMS, созданного в предыдущем ДЗ  
Создать группу узлов состояющую из 3 машин с автомасштабированием до 6  
Подключиться к кластеру с помощью kubectl  

Создал конфигурацию кластера:  
```
iv_art@Pappa-wsl:~/terraform-cloud/15-4$ cat kuber.tf
resource "yandex_kubernetes_cluster" "yo-k8s" {
  name        = "yo-k8s"
  description = "kubernetes cluster"
//  release_channel = "RAPID"
  network_policy_provider = "CALICO"

  network_id = "${yandex_vpc_network.vpc-network.id}"

/*kms key
  kms_provider {
    key_id = "${yandex_kms_symmetric_key.key-a.id}"
  }*/

  master {
    version   = "1.21"
    public_ip = true

    regional {
      region = "ru-central1"

      location {
        zone      = "${yandex_vpc_subnet.public1.zone}"
        subnet_id = "${yandex_vpc_subnet.public1.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.public2.zone}"
        subnet_id = "${yandex_vpc_subnet.public2.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.public3.zone}"
        subnet_id = "${yandex_vpc_subnet.public3.id}"
      }
    }

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "15:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = "${yandex_iam_service_account.my-k8s-sa.id}"

  node_service_account_id = "${yandex_iam_service_account.my-k8s-sa.id}"

  depends_on              = [
    yandex_resourcemanager_folder_iam_binding.editor,
    yandex_resourcemanager_folder_iam_binding.images-puller,
    yandex_iam_service_account.my-k8s-sa
  ]
}


//Сервис-аккаунт
resource "yandex_iam_service_account" "my-k8s-sa" {
  name        = "k8s-editor"
  description = "service account for access to k8s cluster & registry"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = "${var.yandex_folder_id}"
  role      = "editor"
  members   = [
   "serviceAccount:${yandex_iam_service_account.my-k8s-sa.id}"
  ]
  depends_on = [yandex_iam_service_account.my-k8s-sa]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-puller" {
  folder_id = "${var.yandex_folder_id}"
  role      = "container-registry.images.puller"
  members   = [
   "serviceAccount:${yandex_iam_service_account.my-k8s-sa.id}"
  ]
  depends_on = [yandex_iam_service_account.my-k8s-sa]

}


//Ключ KMS
resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "48h"
  }

// k8s node group
resource "yandex_kubernetes_node_group" "k8s-node-group" {
  cluster_id  = "${yandex_kubernetes_cluster.yo-k8s.id}"
  name        = "node-group"
  description = "kubernetes node group"
  version     = "1.21"

  instance_template {
    platform_id = "standard-v2"

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }

    network_interface {
      nat               = true
      subnet_ids         = ["${yandex_vpc_subnet.public2.id}"]

    }


    resources {
      memory = 2
      cores  = 2
      core_fraction   = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = true
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    auto_scale {
      initial = 3
      max     = 6
      min     = 3
    }
  }

  allocation_policy {
      location {
        zone      = "ru-central1-b" // не смог настроить для разных зон
      }
  }
```
Применил  
```
//Информация по кластеру
iv_art@Pappa-wsl:~/terraform-cloud/15-4$ yc managed-kubernetes cluster list
+----------------------+--------+---------------------+---------+---------+-----------------------+-----------------------+
|          ID          |  NAME  |     CREATED AT      | HEALTH  | STATUS  |   EXTERNAL ENDPOINT   |   INTERNAL ENDPOINT   |
+----------------------+--------+---------------------+---------+---------+-----------------------+-----------------------+
| cati400ogi71rt49k3om | yo-k8s | 2022-09-09 09:42:13 | HEALTHY | RUNNING | https://130.193.49.66 | https://192.168.10.19 |
+----------------------+--------+---------------------+---------+---------+-----------------------+-----------------------+

//Информация о нодах
iv_art@Pappa-wsl:~/terraform-cloud/15-4$ yc managed-kubernetes node-group list-nodes --name node-group
+--------------------------------+---------------------------+--------------------------------+-------------+--------+
|         CLOUD INSTANCE         |      KUBERNETES NODE      |           RESOURCES            |    DISK     | STATUS |
+--------------------------------+---------------------------+--------------------------------+-------------+--------+
| epdknln5kc151m9nvpee           | cl13p294qh460b65lv9l-aqyb | 2 20% core(s), 2.0 GB of       | 64.0 GB hdd | READY  |
| RUNNING_ACTUAL                 |                           | memory                         |
|        |
| epdcmgdidi6cfk1thkgr           | cl13p294qh460b65lv9l-uwiq | 2 20% core(s), 2.0 GB of       | 64.0 GB hdd | READY  |
| RUNNING_ACTUAL                 |                           | memory                         |
|        |
| epd09fc8qaniv3kqg04q           | cl13p294qh460b65lv9l-yqus | 2 20% core(s), 2.0 GB of       | 64.0 GB hdd | READY  |
| RUNNING_ACTUAL                 |                           | memory                         |
|        |
+--------------------------------+---------------------------+--------------------------------+-------------+--------+
```
Скопировал конфигурацию в /.kube/config  
![image](https://user-images.githubusercontent.com/87374285/189329090-238f381c-95ad-4048-a288-6cbbbbbda6f5.png)  

![image](https://user-images.githubusercontent.com/87374285/189329817-2c07df12-a83f-4bee-bf4c-6bacbe774598.png)  


![image](https://user-images.githubusercontent.com/87374285/189329357-9fb0ab7b-28a1-45ba-b91f-51391df11157.png)  

все ОК  

