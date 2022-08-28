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