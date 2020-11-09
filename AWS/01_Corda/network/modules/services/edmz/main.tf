provider "aws" {
  region = "us-east-1"
}

locals {
    edmz_cidr    = "172.16.0.0/16"
    edmz_subnet1 = "172.16.1.0/24"
}

#===============================================================================
# VPC
#===============================================================================

#-------------------------------------------------------------------------------
# eDMZ
#-------------------------------------------------------------------------------

resource "aws_vpc" "vpc_edmz" {
  cidr_block = local.edmz_cidr
  tags = {
    Name = "${local.appenv}-edmz-vpc"
  }
}

resource "aws_subnet" "subnet_edmz_az1" {
  vpc_id            = aws_vpc.vpc_edmz.id
  cidr_block        = local.edmz_subnet1
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.appenv}-edmz-1a-subnet"
  }
}

#------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------

resource "aws_internet_gateway" "edmz_igw" {
  vpc_id = aws_vpc.vpc_edmz.id

  tags = {
    Name = "${local.appenv}-edmz-1b-igw"
  }
}

#------------------------------------------------------------------
# Internet Gateway Route
#------------------------------------------------------------------

resource "aws_route_table" "edmz_rt" {
  vpc_id   = aws_vpc.vpc_edmz.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edmz_igw.id
  }

  tags = {
    Name = "${local.appenv}-edmz-rt"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.subnet_edmz_az1.id
  route_table_id = aws_route_table.edmz_rt.id
}

#------------------------------------------------------------------
# External Gateway 
#------------------------------------------------------------------

resource "aws_eip" "edmz_nat_eip" {
  vpc      = true
  depends_on = [aws_internet_gateway.edmz_igw]
}

#------------------------------------------------------------------
# NAT Gateway 
#------------------------------------------------------------------

resource "aws_nat_gateway" "edmz_nat" {
  allocation_id = aws_eip.edmz_nat_eip.id
  subnet_id     = aws_subnet.subnet_edmz_az1.id

  tags = {
    Name = "${local.appenv}-edmz-1b-nat"
  }

  depends_on = [aws_eip.edmz_nat_eip]
}

#===============================================================================
# Local Variables 
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
