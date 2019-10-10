#terraform {
#  required_version = ">= 0.12.7"
#}

provider "google" {
  project = "${var.project_id}"
}

locals {
  app           = "dns"
  terraform     = "terraform"
  zone          = "asia-east2-a"
  region        = "asia-east2"
  ip_cidr_range = "192.168.0.0/24"

  domain        = "${var.domain}"
}


# -------------------------------------------------------------------------------
# Service account
# -------------------------------------------------------------------------------

resource "google_service_account" "sa" {
  account_id = "${local.app}-sa"
}

resource "google_project_iam_binding" "sa-networkviewer-iam" {
  role   = "roles/compute.networkViewer"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}

# -------------------------------------------------------------------------------
# Network
# -------------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = "${local.app}-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${local.app}-subnet"
  region                   = "${local.region}"
  ip_cidr_range            = "${local.ip_cidr_range}"
  network                  = "${google_compute_network.vpc.self_link}"
  private_ip_google_access = true
}

# -------------------------------------------------------------------------------
# Public IP Address
# -------------------------------------------------------------------------------

resource "google_compute_address" "external-address" {
  name         = "${local.app}-external-address"
#  subnetwork   = "${google_compute_subnetwork.subnet.self_link}"
#  address_type = "EXTERNAL"
  region       = "${local.region}"
#  depends_on   = ["google_compute_subnetwork.subnet"]
}

# -------------------------------------------------------------------------------
# Firewall
# -------------------------------------------------------------------------------

resource "google_compute_firewall" "firewall" {
  name          = "fw-${local.app}-ssh"
  network       = "${google_compute_network.vpc.self_link}"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  target_tags = ["fw-${local.app}-ssh"]
}

# -------------------------------------------------------------------------------
# Compute Engine
# -------------------------------------------------------------------------------

resource "google_compute_instance" "server" {
  name                      = "${local.app}-server"
  machine_type              = "n1-standard-2"
  zone                      = "${local.zone}"
  count                     = 1
  
  metadata = {
    sshKeys  = "dennislee:${file("${var.public_key}")}"
  }

  service_account {
    email   = "${google_service_account.sa.email}"
    scopes  = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    access_config {
        nat_ip = "${google_compute_address.external-address.address}"
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata_startup_script = <<SCRIPT
sudo apt-get update
sudo apt-get install -y bind9 bind9utils bind9-doc dnsutils

# Bind IP4
sudo sed 's/-u bind/-u bind -4/' bind9

# Add new domain

cat <<EOF >/etc/bind/named.conf.options
options {
	directory "/var/cache/bind";

	dnssec-validation auto;

	auth-nxdomain no;    # conform to RFC1035
        listen-on port 53 { any; };
	listen-on-v6 { any; };
};
EOF

cat <<EOF >>/etc/bind/named.conf.local
zone "${local.domain}" {
    type master;
    file "/etc/bind/db.${local.domain}";
};
EOF
# TODO: Fix $TTL
cat <<EOF >/etc/bind/db.${local.domain}
; ${local.domain}
$$TTL    604800
@       IN      SOA     ns1.${local.domain}. root.${local.domain}. (
                     2006020201 ; Serial
                         604800 ; Refresh
                          86400 ; Retry
                        2419200 ; Expire
                         604800); Negative Cache TTL
;
@       IN      NS      ns1
ns1     IN      A       ${google_compute_address.external-address.address}
openam  IN      A       34.92.255.14
EOF
SCRIPT

  tags = ["${google_compute_firewall.firewall.name}"] 
}

