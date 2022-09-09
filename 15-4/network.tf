# VPC network
resource "yandex_vpc_network" "vpc-network" {
  name = "vpc"
}

# public subnet - 1
resource "yandex_vpc_subnet" "public1" {
  name       = "public1"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.vpc-network.id}"
}

# public subnet - 2
resource "yandex_vpc_subnet" "public2" {
  name       = "public2"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone       = "ru-central1-b"
  network_id = "${yandex_vpc_network.vpc-network.id}"
}

# public subnet - 3
resource "yandex_vpc_subnet" "public3" {
  name       = "public3"
  v4_cidr_blocks = ["192.168.30.0/24"]
  zone       = "ru-central1-c"
  network_id = "${yandex_vpc_network.vpc-network.id}"
}


# private subnet - 1
resource "yandex_vpc_subnet" "private1" {
  name       = "private1"
  v4_cidr_blocks = ["192.168.40.0/24"]
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.vpc-network.id}"
//  route_table_id = "${yandex_vpc_route_table.routing-table-private.id}"
}

# private subnet - 2
resource "yandex_vpc_subnet" "private2" {
  name       = "private2"
  v4_cidr_blocks = ["192.168.50.0/24"]
  zone       = "ru-central1-b"
  network_id = "${yandex_vpc_network.vpc-network.id}"
//  route_table_id = "${yandex_vpc_route_table.routing-table-private.id}"
}


# routing table for private subnet
/* resource "yandex_vpc_route_table" "routing-table-private" {
  network_id = "${yandex_vpc_network.vpc-network.id}"
  name       = "rt-private"

  static_route {
    destination_prefix = "0.0.0.0/0" 
    next_hop_address   = yandex_compute_instance.nat-public.network_interface.0.ip_address 
  }
}
*/
