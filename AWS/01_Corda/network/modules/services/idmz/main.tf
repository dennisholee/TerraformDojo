provider "aws" {
  region = "us-east-1"
}

locals {
    idmz_cidr    = "172.17.0.0/16"
    idmz_subnet1 = "172.17.1.0/24"
}

#===============================================================================
# VPC
#===============================================================================

#-------------------------------------------------------------------------------
# iDMZ
#-------------------------------------------------------------------------------

resource "aws_vpc" "vpc_idmz" {
  cidr_block = local.idmz_cidr
  tags = {
    Name = "${local.appenv}-idmz-vpc"
  }
}

resource "aws_subnet" "subnet_idmz_az1" {
  vpc_id            = aws_vpc.vpc_idmz.id
  cidr_block        = local.idmz_subnet1
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.appenv}-idmz-1a-subnet"
  }
}


#===============================================================================
# Local Variables 
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
