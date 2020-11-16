provider "aws" {
  region = var.region
}

#===============================================================================
# VPC
#===============================================================================

resource "aws_vpc" "vpc_idmz" {
  cidr_block = var.idmz_cidr
  tags = {
    Name = "${local.appenv}-idmz-vpc"
  }
}

resource "aws_subnet" "subnet_idmz_az" {
  count                   = length(var.az_subnet_mapping)

  vpc_id                  = aws_vpc.vpc_idmz.id
  cidr_block              = lookup(var.az_subnet_mapping[count.index], "cidr")
  availability_zone       = lookup(var.az_subnet_mapping[count.index], "az")
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.appenv}-idmz-${lookup(var.az_subnet_mapping[count.index], "name")}-subnet"
  }
}

#===============================================================================
# Local Variables 
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
