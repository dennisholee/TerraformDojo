# -------------------------------------------------------------------------------
# Network
# -------------------------------------------------------------------------------

resource "google_compute_network" "my-vpc" {
  name                    = "${var.vpc-name}"
  auto_create_subnetworks = "${var.vpc-auto_create_subnet}"
}

resource "google_compute_network" "my-internal-network" {
  name                    = "${var.internal_vpc-name}"
  auto_create_subnetworks = "${var.internal_vpc-auto_create_subnet}"
}

resource "google_compute_network" "my-idmz-network" {
  name                    = "${var.idmz_vpc-name}"
  auto_create_subnetworks = "${var.idmz_vpc-auto_create_subnet}"
}

resource "google_compute_network" "my-edmz-network" {
  name                    = "${var.edmz_vpc-name}"
  auto_create_subnetworks = "${var.edmz_vpc-auto_create_subnet}"
}

# -------------------------------------------------------------------------------
# Peering
# -------------------------------------------------------------------------------

resource "google_compute_network_peering" "peering-edmz-to-idmz" {
  name = "peering-edmz-to-idmz"
  network = "${google_compute_network.my-edmz-network.self_link}"
  peer_network = "${google_compute_network.my-idmz-network.self_link}"
}

resource "google_compute_network_peering" "peering-idmz-to-edmz" {
  name = "peering-idmz-to-edmz"
  network = "${google_compute_network.my-idmz-network.self_link}"
  peer_network = "${google_compute_network.my-edmz-network.self_link}"
}

resource "google_compute_network_peering" "peering-idmz-to-internal" {
  name = "peering-idmz-to-internal"
  network = "${google_compute_network.my-idmz-network.self_link}"
  peer_network = "${google_compute_network.my-internal-network.self_link}"
}

resource "google_compute_network_peering" "peering-internal-to-idmz" {
  name = "peering-internal-to-idmz"
  network = "${google_compute_network.my-internal-network.self_link}"
  peer_network = "${google_compute_network.my-idmz-network.self_link}"
}

# -------------------------------------------------------------------------------
# Firewall
# -------------------------------------------------------------------------------

resource "google_compute_firewall" "firewall-edmz-to-idmz" {
  name          = "firewall-edmz-to-dmz"
  network       = "${google_compute_network.my-idmz-network.self_link}"
  direction     = "INGRESS"
  source_ranges = ["${var.edmz-ip_range}"] 

  allow {
    protocol = "TCP"
    ports    = ["22"]
  }
}

# -------------------------------------------------------------------------------
# Subnetwork
# -------------------------------------------------------------------------------

resource "google_compute_subnetwork" "my-pri-subnet" {
  name   = "${var.pri-name}"
  region = "${var.pri-region}"
  ip_cidr_range = "${var.pri-ip_range}"
  network = "${google_compute_network.my-vpc.self_link}"
  private_ip_google_access = "${var.pri-private_google_access}"
  secondary_ip_range {
      range_name = "service-range"
      ip_cidr_range = "${var.pri-pod_ip_range}"
  }
  secondary_ip_range {
      range_name = "pod-range"
      ip_cidr_range = "${var.pri-svc_ip_range}"
  }
}

resource "google_compute_subnetwork" "my-mgnt-subnet" {
  name   = "${var.mgnt-name}"
  region = "${var.mgnt-region}"
  ip_cidr_range = "${var.mgnt-ip_range}"
  network = "${google_compute_network.my-vpc.self_link}"
  private_ip_google_access = "${var.mgnt-private_google_access}"
}

resource "google_compute_subnetwork" "my-internal-subnet" {
  name   = "${var.internal-name}"
  region = "${var.internal-region}"
  ip_cidr_range = "${var.internal-ip_range}"
  network = "${google_compute_network.my-internal-network.self_link}"
  private_ip_google_access = "${var.internal-private_google_access}"
}

resource "google_compute_subnetwork" "my-idmz-subnet" {
  name   = "${var.idmz-name}"
  region = "${var.idmz-region}"
  ip_cidr_range = "${var.idmz-ip_range}"
  network = "${google_compute_network.my-idmz-network.self_link}"
  private_ip_google_access = "${var.idmz-private_google_access}"
}

resource "google_compute_subnetwork" "my-edmz-subnet" {
  name   = "${var.edmz-name}"
  region = "${var.edmz-region}"
  ip_cidr_range = "${var.edmz-ip_range}"
  network = "${google_compute_network.my-edmz-network.self_link}"
  private_ip_google_access = "${var.edmz-private_google_access}"
}
