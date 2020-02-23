provider "google" {
  project = var.project_id
}

locals {
  app           = "multiniclb"
  region        = var.region
  zone          = var.zone
  vpc0_cidr     = "192.168.0.0/24"
  vpc1_cidr     = "192.168.1.0/24"
}

# ------------------------------------------------------------------------------
# Adding SSH Public Key in Project Meta Data
# ------------------------------------------------------------------------------

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "dennislee:${file("${var.public_key}")}"
}

#-------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------

resource "google_compute_network" "vpc0-network" {
  name                    = "${local.app}-vpc0-network"
  auto_create_subnetworks = false
}

resource "google_compute_network" "vpc1-network" {
  name                    = "${local.app}-vpc1-network"
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

resource "google_compute_subnetwork" "vpc1-subnet" {
  name                     = "${local.app}-vpc1-subnet"
  region                   = local.region
  ip_cidr_range            = local.vpc1_cidr
  network                  = google_compute_network.vpc1-network.self_link
  private_ip_google_access = "false"
}

# -------------------------------------------------------------------------------
# Reserve IP Address 
# -------------------------------------------------------------------------------

resource "google_compute_address" "app-nic0-address" {
  name         = "${local.app}-app-nic0-address"
  subnetwork   = google_compute_subnetwork.vpc0-subnet.self_link
  address_type = "INTERNAL"
  region       = local.region
}

resource "google_compute_address" "app-nic1-address" {
  name         = "${local.app}-app-nic1-address"
  subnetwork   = google_compute_subnetwork.vpc1-subnet.self_link
  address_type = "INTERNAL"
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

resource "google_compute_firewall" "fw-app-vpc1" {
  name          = "fw-${local.app}-ingress-app-vpc1"
  network       = google_compute_network.vpc1-network.self_link
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "TCP"
    ports    = ["22", "80"]
  }

  target_tags = ["fw-${local.app}-ingress-app-vpc1"]
}

# -------------------------------------------------------------------------------
# Multi-homed App host 
# -------------------------------------------------------------------------------

resource "google_compute_instance" "app-host" {
  name                      = "${local.app}-app"
  machine_type              = "f1-micro"
  zone                      = local.zone
  allow_stopping_for_update = true
  count                     = 1

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc0-subnet.self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc1-subnet.self_link
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  tags = ["${google_compute_firewall.fw-app-vpc0.name}", "${google_compute_firewall.fw-app-vpc1.name}"]
}

# -------------------------------------------------------------------------------
# App managed instance group 
# -------------------------------------------------------------------------------

resource "google_compute_instance_template" "app-tmpl" {
  name        = "${local.app}-app-tmpl"

  machine_type         = "f1-micro"
  can_ip_forward       = false

  tags = ["${google_compute_firewall.fw-app-vpc0.name}", "${google_compute_firewall.fw-app-vpc1.name}"]

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "projects/${var.project_id}/global/images/web-image" # "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc0-subnet.self_link
  }
 
  network_interface {
    subnetwork = google_compute_subnetwork.vpc1-subnet.self_link
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<SCRIPT
echo "100 rt-nic1" >> /etc/iproute2/rt_tables
ip rule add pri 32000 from 192.168.1.1/255.255.255.0 table rt-nic1
sleep 1
ip route add 35.191.0.0/16 via 192.168.1.1 dev eth1 table rt-nic1
ip route add 130.211.0.0/22 via 192.168.1.1 dev eth1 table rt-nic1
SCRIPT
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 30
  timeout_sec         = 30
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/"
    port         = "80"
  }
}

resource "google_compute_region_instance_group_manager" "app-igm" {
  name = "${local.app}-app-igm"

  base_instance_name = "app"
  version {
    instance_template  = google_compute_instance_template.app-tmpl.self_link
  }
  region             = local.region

  target_size  = 2


  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.self_link
    initial_delay_sec = 600
  }
}

# -------------------------------------------------------------------------------
# Setup internal load balancer 
# -------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "int-lb-backend-srv" {
  name          = "${local.app}-ilb-backend-srv"
  protocol      = "TCP"
  health_checks = [google_compute_health_check.int-lb-health-check.self_link]
  region        = local.region

  backend {
    group = google_compute_region_instance_group_manager.app-igm.instance_group
  }
}

resource "google_compute_forwarding_rule" "int-lb-fwd-rule" {
  name                  = "${local.app}-ilb-fwd-rule"
  region                = local.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.int-lb-backend-srv.self_link
  all_ports             = true
  network               = google_compute_network.vpc1-network.name
  subnetwork            = google_compute_subnetwork.vpc1-subnet.name
}

resource "google_compute_health_check" "int-lb-health-check" {
  name = "${local.app}-ilb-health-check"
  http_health_check {
    port = "80"
  }
}


# -------------------------------------------------------------------------------
# Dummy host on VPC1 
# -------------------------------------------------------------------------------


resource "google_compute_instance" "vpc1-dummy-host" {
  name                      = "${local.app}-vpc1-dummy-host"
  machine_type              = "f1-micro"
  zone                      = local.zone
  allow_stopping_for_update = true
  count                     = 1

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc1-subnet.self_link
    access_config {
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  tags = ["${google_compute_firewall.fw-app-vpc0.name}", "${google_compute_firewall.fw-app-vpc1.name}"]
}
