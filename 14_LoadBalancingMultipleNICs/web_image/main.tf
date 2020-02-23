provider "google" {
  project = var.project_id
}

locals {
  app           = "webimage"
  region        = var.region
  zone          = var.zone
  vpc0_cidr     = "192.168.100.0/24"
}

#-------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------

resource "google_compute_network" "vpc0-network" {
  name                    = "${local.app}-vpc0-network"
  auto_create_subnetworks = false
}

# -------------------------------------------------------------------------------
# Subnetwork
# -------------------------------------------------------------------------------

resource "google_compute_subnetwork" "vpc0-subnet" {
  name                     = "${local.app}-vpc0-subnet"
  region                   = local.region
  ip_cidr_range            = local.vpc0_cidr
  network                  = google_compute_network.vpc0-network.self_link
  private_ip_google_access = "false"
}

# -------------------------------------------------------------------------------
# Reserve IP Address 
# -------------------------------------------------------------------------------

resource "google_compute_address" "external-address" {
  name         = "${local.app}-external-address"
  region       = local.region
}

# -------------------------------------------------------------------------------
# Firewall Rules 
# -------------------------------------------------------------------------------

resource "google_compute_firewall" "fw-app-vpc0" {
  name          = "fw-${local.app}-ingress-app-vpc0"
  network       = google_compute_network.vpc0-network.self_link
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "TCP"
    ports    = ["22", "80"]
  }

  target_tags = ["fw-${local.app}-ingress-app-vpc0"]
}

# -------------------------------------------------------------------------------
# Web host 
# -------------------------------------------------------------------------------


resource "google_compute_instance" "web-host" {
  name                      = "${local.app}-web"
  machine_type              = "f1-micro"
  zone                      = local.zone
  allow_stopping_for_update = true
  count                     = 1

  metadata = {
    sshKeys  = "dennislee:${file("${var.public_key}")}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc0-subnet.self_link
    access_config {
        nat_ip = google_compute_address.external-address.address
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  tags = ["${google_compute_firewall.fw-app-vpc0.name}"]

metadata_startup_script = <<SCRIPT
sudo apt-update
sudo apt-get install -y nginx
SCRIPT
}

