provider "aws" {
  region = "us-east-1"
}


module "vpc" {
  source     = "../vpc"
  app        = "contour"
  env        = "dev"
}

module "corda-efs" {
  source     = "./modules/services/efs"
  app        = "contour"
  env        = "dev"

  name       = "corda"
  subnet_ids = module.vpc.idmz_subnet_ids
}
