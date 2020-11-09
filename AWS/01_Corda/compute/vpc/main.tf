#===============================================================================
# eDMZ
#===============================================================================

data "aws_vpc" "edmz_vpc" {
  tags = {
    Name = "${local.appenv}-edmz-vpc"
  }
}

data "aws_subnet" "edmz_subnet" {
  tags = {
    Name = "${local.appenv}-edmz-1a-subnet"
  }
}

data "aws_internet_gateway" "edmz_igw" {
  tags = {
    Name = "${local.appenv}-edmz-1b-igw"
  }
}


#===============================================================================
# iDMZ
#===============================================================================

data "aws_vpc" "idmz_vpc" {
  tags = {
    Name = "${local.appenv}-idmz-vpc"
  }
}

data "aws_subnet" "idmz_subnet" {
  tags = {
    Name = "${local.appenv}-idmz-1a-subnet"
  }
}


#===============================================================================
# Local variables
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
