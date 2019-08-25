resource "google_compute_router" "router" {
  name    = "${var.router-name}"
  region  = "${var.router-region}"
  network = "${var.router-network}"
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "simple-nat" {
  name                               = "nat-1"
  router                             = google_compute_router.router.name
  region                             = "${var.nat-region}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
