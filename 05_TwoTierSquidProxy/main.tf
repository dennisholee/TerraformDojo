#terraform {
#  required_version = ">= 0.12.7"
#}

provider "google" {
  project = "${var.project}"
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

module "global" {
  source = "./modules/global/"

  region = "${var.region}"
}


#-------------------------------------------------------------------------------
# Internal
#-------------------------------------------------------------------------------

module "internal-squid" {
  source = "./modules/services/squid/"

  squid_server-name             = "internal-squid"
  squid_server-zone             = "${var.zone}"
  squid_server-primary_subnet   = "${module.global.my-internal-subnet}"
  squid_server-secondary_subnet = "${module.global.my-idmz-subnet}"
  squid_server-tags             = ["fw-internal-ssh-ingress", "fw-internal-proxy-ingress"]
  squid_server-gw               = "192.168.2.1"
  squid_server-nic              = "eth1"
#  depends_on                    = ["idmz-squid.squid_server"]
}

module "fw-internal-ssh-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-internal-ssh-ingress"
  firewall-network       = "${module.global.my-idmz-subnet}"
  firewall-direction     = "INGRESS"
  firewall-protocol      = "TCP"
  firewall-ports         = ["22"]
  firewall-source_range  = ["0.0.0.0/0"]
  firewall-target_tags   = ["fw-internal-ssh-ingress"]
}

module "fw-internal-proxy-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-internal-proxy-ingress"
  firewall-network       = "${module.global.my-internal-subnet}"
  firewall-direction     = "INGRESS"
  firewall-protocol      = "TCP"
  firewall-ports         = ["3128"]
  firewall-target_tags   = ["fw-internal-proxy-ingress"]
}

#-------------------------------------------------------------------------------
# iDMZ
#-------------------------------------------------------------------------------

module "idmz-squid" {
  source = "./modules/services/squid/"

  squid_server-name             = "idmz-squid"
  squid_server-zone             = "${var.zone}"
  squid_server-primary_subnet   = "${module.global.my-idmz-subnet}"
  squid_server-secondary_subnet = "${module.global.my-edmz-subnet}"
  squid_server-tags             = ["fw-idmz-ssh-ingress", "fw-idmz-proxy-ingress"]
  squid_server-gw               = "192.168.3.1"
  squid_server-nic              = "eth1"
#  depends_on                    = ["nat"]
}

module "fw-idmz-ssh-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-idmz-ssh-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "INGRESS"
  firewall-protocol      = "TCP"
  firewall-ports         = ["22"]
  firewall-source_range  = ["0.0.0.0/0"]
  firewall-target_tags   = ["fw-idmz-ssh-ingress"]
}

module "fw-idmz-proxy-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-edmz-proxy-ingress"
  firewall-network       = "${module.global.my-idmz-subnet}"
  firewall-direction     = "INGRESS"
  firewall-protocol      = "TCP"
  firewall-ports         = ["3128"]
  firewall-target_tags   = ["fw-idmz-proxy-ingress"]
}

#-------------------------------------------------------------------------------
# eDMZ
#-------------------------------------------------------------------------------

module "bastion-svr" {
  source = "./modules/services/bastion/"

  bastion_server-zone   = "${var.zone}"
  bastion_server-subnet = "${module.global.my-edmz-subnet}"

  bastion_server-tags   = ["fw-ssh-ingress"]
}

module "nat" {
  source = "./modules/network/nat/"

  nat-name    = "edmz-nat"
  nat-region  = "${var.region}"
  nat-network = "${module.global.my-edmz-network}"
}

module "fw-ssh-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-ssh-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "INGRESS"
  firewall-protocol      = "TCP"
  firewall-ports         = ["22"]
  firewall-source_range  = ["0.0.0.0/0"]
  firewall-target_tags   = ["fw-ssh-ingress"]
}
