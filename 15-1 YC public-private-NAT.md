#### Задание 1. Яндекс.Облако (обязательное к выполнению)
Создать VPC.  
Создать пустую VPC. Выбрать зону.  
##### Публичная подсеть.  
Создать в vpc subnet с названием public, сетью 192.168.10.0/24.  
Создать в этой подсети NAT-инстанс, присвоив ему адрес 192.168.10.254. В качестве image_id использовать fd80mrhj8fl2oe87o4e1  
Создать в этой публичной подсети виртуалку с публичным IP и подключиться к ней, убедиться что есть доступ к интернету.  
##### Приватная подсеть.  
Создать в vpc subnet с названием private, сетью 192.168.20.0/24.  
Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс  
Создать в этой приватной подсети виртуалку с внутренним IP, подключиться к ней через виртуалку, созданную ранее и убедиться что есть доступ к интернету    

Файлы:  
- instances.tf - виртуалки  
- network.tf   - сеть  
- provider.tf  - ЯО  
- variables.tf - описание переменных  

```
iv_art@Pappa-wsl:~/terraform-cloud/15-1$ cat variables.tf
# ID облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_cloud_id" {
  default = "b1gbsrdfp0uc2rpo4smq"
}

# Folder облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_folder_id" {
  default = "b1gngdmp3o039dgvg8r5"
}

# ID образа
variable "centos-7-base" {
  default = "fd80rnhvc47031anomed"
}

variable "token" {
  default = "AQA.................qbrfU"
}
```  



Конфигурация провайдера  
```
iv_art@Pappa-wsl:~/terraform-cloud/15-1$ cat provider.tf
# Provider
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">=0.13"
}

provider "yandex" {
#  service_account_key_file = "key.json"
  cloud_id  = "${var.yandex_cloud_id}"
  folder_id = "${var.yandex_folder_id}"
  token = "${var.token}"
}

# Конфигурация сети  

iv_art@Pappa-wsl:~/terraform-cloud/15-1$ cat network.tf
# VPC network
resource "yandex_vpc_network" "vpc-network" {
  name = "vpc"
}

# public subnet
resource "yandex_vpc_subnet" "public" {
  name       = "public"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.vpc-network.id}"
}

# private subnet
resource "yandex_vpc_subnet" "private" {
  name       = "private"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.vpc-network.id}"
  route_table_id = "${yandex_vpc_route_table.routing-table-private.id}"
}

# routing table for private subnet
resource "yandex_vpc_route_table" "routing-table-private" {
  network_id = "${yandex_vpc_network.vpc-network.id}"
  name       = "rt-private"

  static_route {
    destination_prefix = "0.0.0.0/0" 
    next_hop_address   = yandex_compute_instance.nat-public.network_interface.0.ip_address 
  }
}

# NAT instance

resource "yandex_compute_instance" "nat-public" {
  platform_id = "standard-v1"
  name = "nat-public"
  zone = "ru-central1-a"

  resources {
    cores = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1" # nat-instance
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.public.id}"
    ip_address = "192.168.10.254"
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
iv_art@Pappa-wsl:~/terraform-cloud/15-1$
```
Создаем машины  
```
iv_art@Pappa-wsl:~/terraform-cloud/15-1$ cat instances.tf
# VM in public subnet
resource "yandex_compute_instance" "vm-public" {
  platform_id = "standard-v1"
  allow_stopping_for_update = true
  name = "vm-public"
  zone = "ru-central1-a"

  resources {
    cores = 2
    memory = 4
  }

  boot_disk {
#    initialize_params {
      #image_id = "fd8mfc6omiki5govl68h" # Ubuntu-20.04
    initialize_params {
      image_id    = "${var.centos-7-base}"
      name        = "root-vm-public"
      type        = "network-nvme"
      size        = "10"

    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.public.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# VM in private subnet
resource "yandex_compute_instance" "vm-private" {
  platform_id = "standard-v1"
  allow_stopping_for_update = true
  name = "vm-private"
  zone = "ru-central1-a"

  resources {
    cores = 2
    memory = 4
  }

  boot_disk {
#    initialize_params {
#      image_id = "fd8mfc6omiki5govl68h" # Ubuntu-20.04
    initialize_params {
      image_id    = "${var.centos-7-base}"
      name        = "root-vm-private"
      type        = "network-nvme"
      size        = "10"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.private.id}"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
iv_art@Pappa-wsl:~/terraform-cloud/15-1$
```

Итого получаем  

![image](https://user-images.githubusercontent.com/87374285/187068072-a98b53f2-ce12-41bf-b259-9c8ecfaf103d.png)  

Подключиться к ней через виртуалку, созданную ранее и убедиться, что есть доступ к интернету  
```
#Прокидываем ключ
iv_art@Pappa-wsl:~/terraform-cloud/15-1$ scp /home/iv_art/.ssh/id_rsa centos@51.250.77.217:/home/centos/.ssh/id_rsa
#заходим в виртуалку public
iv_art@Pappa-wsl:~/terraform-cloud/15-1$ ssh centos@51.250.77.217
[centos@fhmjb2t396q2go0fqnsi ~]$ ls ~/.ssh
authorized_keys  id_rsa
#заходим в виртуалку private
[centos@fhmjb2t396q2go0fqnsi ~]$ ssh centos@192.168.20.26

#Проверяем внешний адрес
[centos@fhmgpo7g6la0v0dnhlgd ~]$ curl ifconfig.me/ip
51.250.79.77
[centos@fhmgpo7g6la0v0dnhlgd ~]$
```
Получили адрес NAT.



