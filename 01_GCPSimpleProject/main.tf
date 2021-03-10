provider "google" {
  credentials = "${file("/Users/dennislee/.config/gcloud/foo789-terraform-admin.json")}"
  project = "foo789-terraform-admin"
}

module "vpc" {
  source = "./modules/global"
  
#   
#   var_vpc-name                         = "${var.var_vpc-name}"
#   var_vpc-auto_create_subnet           = "${var.var_vpc-auto_create_subnet}"
#   
#   var_vpc_subnet-name                  = "${var.var_vpc_subnet-name}"
#   var_vpc_subnet-region                = "${var.var_vpc_subnet-region}"
#   var_vpc_subnet-ip_range              = "${var.var_vpc_subnet-ip_range}"
#   var_vpc_subnet-private_google_access = "${var.var_vpc_subnet-private_google_access}"
}

module "compute" {
  source  = "./modules/internal"

  my-vpc-internal = "${module.vpc.my-vpc-internal}"
  my-vpc-dmz      = "${module.vpc.my-vpc-dmz}"
}

module "kms" {
  source = "./modules/kms"
}
