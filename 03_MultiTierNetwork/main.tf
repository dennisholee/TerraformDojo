provider "google" {
  project = "foo789-terraform-admin"
}

# ------------------------------------------------------------------------------
# Adding SSH Public Key in Project Meta Data
# ------------------------------------------------------------------------------

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "${file("${var.public_key}")}"
}

module "global" {
  source = "./modules/global/"
}

# ------------------------------------------------------------------------------
# Management subnetwork
# ------------------------------------------------------------------------------

module "mgnt-svr" {
  source = "./modules/services/mgnt/"

  mgnt_server-zone   = "europe-west2-a"
  mgnt_server-subnet = "${module.global.my-mgnt-subnet}"
}

# ------------------------------------------------------------------------------
# Internal subnetwork
# ------------------------------------------------------------------------------

module "internal-testbox-svr" {
  source = "./modules/services/testbox/"

  testbox_server-name   = "internal-testbox-svr"
  testbox_server-zone   = "europe-west2-a"
  testbox_server-subnet = "${module.global.my-internal-subnet}"

  testbox_server-tags   = ["fw-ssh-ingress"]
}

# ------------------------------------------------------------------------------
# iDMZ subnetwork
# ------------------------------------------------------------------------------
module "web-svr" {
  source = "./modules/services/web/"

  web_server-zone   = "europe-west2-a"
  web_server-subnet = "${module.global.my-idmz-subnet}"

  web_server-tags   = ["fw-idmz-ssh-ingress"]
}

module "squid-svr" {
  source = "./modules/services/squid/"

  squid_server-zone   = "europe-west2-a"
  squid_server-subnet = "${module.global.my-idmz-subnet}"

  squid_server-tags   = ["fw-idmz-ssh-ingress", "fw-idmz-proxy-ingress"]
}

module "fw-idmz-ssh-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-idmz-ssh-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["22"]
  firewall-source_range  = ["0.0.0.0/0"]
  firewall-target_tags   = ["fw-idmz-ssh-ingress"] 
}

module "fw-idmz-proxy-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-idmz-proxy-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["3128"]
  firewall-target_tags   = ["fw-idmz-proxy-ingress"] 
}

module "fw-idmz-http-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-idmz-http-ingress"
  firewall-network       = "${module.global.my-idmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["80"]
  firewall-target_tags   = ["fw-idmz-http-ingress"] 
}

module "fw-idmz-https-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-idmz-https-ingress"
  firewall-network       = "${module.global.my-idmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["443"]
  firewall-target_tags   = ["fw-idmz-https-ingress"] 
}

# ------------------------------------------------------------------------------
# eDMZ subnetwork
# ------------------------------------------------------------------------------

module "nat" {
  source = "./modules/network/nat/"

  router-name    = "edmz-nat"
  router-network = "${module.global.my-edmz-network}"
}

module "bastion-svr" {
  source = "./modules/services/bastion/"

  bastion_server-zone   = "europe-west2-a"
  bastion_server-subnet = "${module.global.my-edmz-subnet}"

  bastion_server-tags   = ["fw-ssh-ingress"]
}

module "idmz-edmz-router" {
  source = "./modules/services/router"

  router_server-name             = "idmz-edmz-router"
  router_server-primary_subnet   = "${module.global.my-edmz-subnet}"
  router_server-secondary_subnet = "${module.global.my-idmz-subnet}"
  router_server-zone             = "europe-west2-a"
  router_server-tags             = ["fw-edmz-ssh-ingress", "fw-edmz-http-ingress", "fw-edmz-https-ingress"]
}

module "edmz-testbox-svr" {
  source = "./modules/services/testbox/"

  testbox_server-name   = "edmz-testbox-svr"
  testbox_server-zone   = "europe-west2-a"
  testbox_server-subnet = "${module.global.my-edmz-subnet}"

  testbox_server-tags   = ["fw-ssh-ingress"]
}

module "fw-ssh-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-ssh-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["22"]
  firewall-source_range  = ["0.0.0.0/0"]
  firewall-target_tags   = ["fw-ssh-ingress"] 
}

module "fw-edmz-http-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-edmz-http-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["80"]
  firewall-target_tags   = ["fw-edmz-http-ingress"] 
}

module "fw-edmz-https-ingress" {
  source = "./modules/firewalls/"

  firewall-name          = "fw-edmz-https-ingress"
  firewall-network       = "${module.global.my-edmz-subnet}"
  firewall-direction     = "ingress"
  firewall-protocol      = "TCP"
  firewall-ports         = ["443"]
  firewall-target_tags   = ["fw-edmz-https-ingress"] 
}
