#terraform {
#  required_version = ">= 0.12.7"
#}

provider "google" {
  project = "${var.project_id}"
}

locals {
  app           = "kms"
  zone          = "asia-east2-a"
  region        = "asia-east2"
  ip_cidr_range = "192.168.0.0/24"
}

# ------------------------------------------------------------------------------
# Adding SSH Public Key in Project Meta Data
# ------------------------------------------------------------------------------

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "dennislee:${file("${var.public_key}")}"
}

# -------------------------------------------------------------------------------
# Service account
# -------------------------------------------------------------------------------

resource "google_service_account" "sa" {
  account_id = "${local.app}-sa"
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

  target_tags = ["fw-${local.app}-ssh"]
}


# -------------------------------------------------------------------------------
# Compute Engine
# -------------------------------------------------------------------------------

resource "google_compute_instance" "server" {
  name                      = "${local.app}-server"
  machine_type              = "f1-micro"
  zone                      = "${local.zone}"
  count                     = 1
  
  metadata = {
    sshKeys =  "dennislee:${file("${var.public_key}")}"
  }

  service_account {
    email   = "${google_service_account.sa.email}"
    scopes  = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    access_config { }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  tags = ["${google_compute_firewall.firewall.name}"] 
}

# -------------------------------------------------------------------------------
# Encryption key
# -------------------------------------------------------------------------------

resource "google_kms_key_ring" "keyring" {
  name = "${local.app}-keyring"
  location = "${local.region}"
}

resource "google_kms_crypto_key" "secret-key" {
  name            = "${local.app}-secret"
  key_ring        = "${google_kms_key_ring.keyring.self_link}"
}

resource "google_kms_crypto_key_iam_member" "secret-key-iam-member" {
  crypto_key_id = "${google_kms_crypto_key.secret-key.self_link}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.sa.email}"
}
