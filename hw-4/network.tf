### Network
resource "yandex_vpc_network" "this" {
  count = var.create_vpc ? 1 : 0
  name = "vpc-otus-hw-4"
  description = "VPC vpc-otus-hw-4"
  folder_id = local.folder_id
}

resource "yandex_vpc_subnet" "subnet" {
  count = var.create_subnet ? 1 : 0
  name = "subnet-otus-hw-4"
  description = "Subnet subnet-otus-hw-4"
  v4_cidr_blocks = [var.subnet_v4_cidr_block]
  zone = var.default_zone
  network_id = local.vpc_id
  folder_id = local.folder_id
}

resource "yandex_vpc_security_group" "security_group" {
  count = var.create_sg ? 1 : 0
  name        = "securtiy-group-otus-hw-4"
  description = "Securtiy group securtiy-group-otus-hw-4"
  folder_id = local.folder_id
  network_id  = local.vpc_id

  ingress {
    protocol       = "ICMP"
    description    = "icmp"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "postgresql"
    v4_cidr_blocks = ["78.85.16.136/32"]
    port           = 6432
  }

  egress {
    protocol       = "ANY"
    description    = "Allow any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
