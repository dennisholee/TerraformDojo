provider "aws" {
  region = var.region
}

module "edmz" {
  source            = "./modules/services/edmz"
  region            = var.region
  env               = var.env
  app               = var.app
  edmz_cidr         = var.edmz_cidr
  az_subnet_mapping = var.edmz_az_subnet_mapping
}

module "idmz" {
  source            = "./modules/services/idmz"
  region            = var.region
  env               = var.env
  app               = var.app
  idmz_cidr         = var.idmz_cidr
  az_subnet_mapping = var.idmz_az_subnet_mapping
}
