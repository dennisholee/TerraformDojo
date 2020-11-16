provider "aws" {
  region = "us-east-1"
}

#====================================================================================
# Account Key Pair
#====================================================================================

resource "aws_key_pair" "deployer" {
  key_name   = "ssh-key"
  public_key = file("${var.public_key}")
}

module "vpc" {
  source     = "./vpc"
  app        = "contour"
  env        = "dev"
}

#===============================================================================
# Compute resources
#===============================================================================

#-------------------------------------------------------------------------------
# eDMZ
#-------------------------------------------------------------------------------

module "bastion" {
  source = "./modules/services/bastion"
  app         = "contour"
  env         = "dev"
  vpc_id      = module.vpc.edmz_vpc_id
  subnet_name = "edmz"
  subnet_ids  = module.vpc.edmz_subnet_ids 

  key_pair    = aws_key_pair.deployer.id
}

module "float" {
  source = "./modules/services/float"
  app         = "contour"
  env         = "dev"
  vpc_id      = module.vpc.edmz_vpc_id
  subnet_name = "edmz"
  subnet_ids  = module.vpc.edmz_subnet_ids 

  key_pair    = aws_key_pair.deployer.id
}

module "socks" {
  source = "./modules/services/socks"
  app         = "contour"
  env         = "dev"
  vpc_id      = module.vpc.edmz_vpc_id
  subnet_name = "edmz"
  subnet_ids  = module.vpc.edmz_subnet_ids

  key_pair    = aws_key_pair.deployer.id
}

module "bridge_vpce" {
  
  source      = "./modules/services/service_endpoint"
  app         = "contour"
  env         = "dev"
  
  vpc_id      = module.vpc.edmz_vpc_id
  subnet_name = "idmz"
  subnet_ids  = module.vpc.idmz_subnet_ids 

  service_name = module.bridge.service_name
}

##-------------------------------------------------------------------------------
## iDMZ
##-------------------------------------------------------------------------------

module "bridge" {
  source      = "./modules/services/bridge"
  app         = "contour"
  env         = "dev"

  vpc_id      = module.vpc.idmz_vpc_id
  subnet_name = "idmz"
  subnet_ids  = module.vpc.idmz_subnet_ids 

  key_pair    = aws_key_pair.deployer.id
}


module "corda" {
  source      = "./modules/services/corda"
  app         = "contour"
  env         = "dev"

  vpc_id      = module.vpc.idmz_vpc_id
  subnet_name = "idmz"
  subnet_ids  = module.vpc.idmz_subnet_ids 

  key_pair    = aws_key_pair.deployer.id
}

