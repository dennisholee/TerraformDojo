resource "google_compute_firewall" "firewall" {
  name          = "${var.firewall-name}"
  network       = "${var.firewall-network}"
  direction     = "${var.firewall-direction}"
  source_ranges = var.firewall-source_range
  
  allow {
    protocol = "${var.firewall-protocol}"
    ports    = var.firewall-ports
  }

  target_tags = var.firewall-target_tags
}
