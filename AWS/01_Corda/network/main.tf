provider "aws" {
  region = "us-east-1"
}

locals {
    edmz_cidr    = "10.1.0.0/16"
    edmz_subnet1 = "10.1.1.0/24"
    edmz_subnet2 = "10.1.2.0/24"
    edmz_subnet3 = "10.1.3.0/24"

    idmz_cidr    = "10.2.0.0/16"
    idmz_subnet1 = "10.2.1.0/24"
    idmz_subnet2 = "10.2.2.0/24"
    idmz_subnet3 = "10.2.3.0/24"
}

module "edmz" {
  source = "./modules/services/edmz"
  env    = "dev"
  app    = "contour"
}

module "idmz" {
  source      = "./modules/services/idmz"
  env         = "dev"
  app         = "contour"
}
