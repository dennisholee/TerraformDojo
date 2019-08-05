resource "google_compute_network" "my-vpc" {
  name                    = "${var.var_vpc-name}"
  auto_create_subnetworks = "${var.var_vpc-auto_create_subnet}"
}

resource "google_compute_subnetwork" "my-vpc-subnet" {
  name   = "${var.var_vpc_subnet-name}"
  region = "${var.var_vpc_subnet-region}"
  ip_cidr_range = "${var.var_vpc_subnet-ip_range}"
  network = "${google_compute_network.my-vpc.self_link}"
  private_ip_google_access = "${var.var_vpc_subnet-private_google_access}"
  secondary_ip_range {
      range_name = "service-range"
      ip_cidr_range = "172.28.128.0/18"
  }
  secondary_ip_range {
      range_name = "pod-range"
      ip_cidr_range = "172.28.64.0/18"
  }
}
