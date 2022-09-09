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

}