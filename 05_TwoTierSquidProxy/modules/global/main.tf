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
  name         = "peering-edmz-to-idmz"
  network      = "${google_compute_network.my-edmz-network.self_link}"
  peer_network = "${google_compute_network.my-idmz-network.self_link}"
}

resource "google_compute_network_peering" "peering-idmz-to-edmz" {
  name         = "peering-idmz-to-edmz"
  network      = "${google_compute_network.my-idmz-network.self_link}"
  peer_network = "${google_compute_network.my-edmz-network.self_link}"
  depends_on   = ["google_compute_network_peering.peering-edmz-to-idmz"]
}

resource "google_compute_network_peering" "peering-idmz-to-internal" {
  name         = "peering-idmz-to-internal"
  network      = "${google_compute_network.my-idmz-network.self_link}"
  peer_network = "${google_compute_network.my-internal-network.self_link}"
  depends_on   = ["google_compute_network_peering.peering-idmz-to-edmz"]
}

resource "google_compute_network_peering" "peering-internal-to-idmz" {
  name         = "peering-internal-to-idmz"
  network      = "${google_compute_network.my-internal-network.self_link}"
  peer_network = "${google_compute_network.my-idmz-network.self_link}"
  depends_on   = ["google_compute_network_peering.peering-internal-to-idmz"]
}

# -------------------------------------------------------------------------------
# Subnetwork
# -------------------------------------------------------------------------------

resource "google_compute_subnetwork" "my-internal-subnet" {
  name                     = "${var.internal-name}"
  region                   = "${var.region}"
  ip_cidr_range            = "${var.internal-ip_range}"
  network                  = "${google_compute_network.my-internal-network.self_link}"
  private_ip_google_access = "${var.internal-private_google_access}"
}

resource "google_compute_subnetwork" "my-idmz-subnet" {
  name                     = "${var.idmz-name}"
  region                   = "${var.region}"
  ip_cidr_range            = "${var.idmz-ip_range}"
  network                  = "${google_compute_network.my-idmz-network.self_link}"
  private_ip_google_access = "${var.idmz-private_google_access}"
}

resource "google_compute_subnetwork" "my-edmz-subnet" {
  name                     = "${var.edmz-name}"
  region                   = "${var.region}"
  ip_cidr_range            = "${var.edmz-ip_range}"
  network                  = "${google_compute_network.my-edmz-network.self_link}"
  private_ip_google_access = "${var.edmz-private_google_access}"
}
