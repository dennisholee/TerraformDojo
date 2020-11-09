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
  subnet_id   = module.vpc.edmz_subnet_id 
  igw         = module.vpc.edmz_igw

  key_pair    = aws_key_pair.deployer.id
}

module "float" {
  source = "./modules/services/socks"
  app         = "contour"
  env         = "dev"
  vpc_id      = module.vpc.edmz_vpc_id
  subnet_name = "edmz"
  subnet_id   = module.vpc.edmz_subnet_id 
  igw         = module.vpc.edmz_igw

  key_pair    = aws_key_pair.deployer.id
}

module "socks" {
  source = "./modules/services/socks"
  app         = "contour"
  env         = "dev"
  vpc_id      = module.vpc.edmz_vpc_id
  subnet_name = "edmz"
  subnet_id   = module.vpc.edmz_subnet_id 
  igw         = module.vpc.edmz_igw

  key_pair    = aws_key_pair.deployer.id
}

#-------------------------------------------------------------------------------
# iDMZ
#-------------------------------------------------------------------------------

module "bridge" {
  source      = "./modules/services/bridge"
  app         = "contour"
  env         = "dev"

  vpc_id      = module.vpc.idmz_vpc_id
  subnet_name = "idmz"
  subnet_id   = module.vpc.idmz_subnet_id 

  key_pair    = aws_key_pair.deployer.id
}
