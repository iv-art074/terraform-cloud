# VPC network
resource "yandex_vpc_network" "vpc-network" {
  name = "vpc"
}

# public subnet
resource "yandex_vpc_subnet" "public" {
  name       = "public"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.vpc-network.id}"
}

