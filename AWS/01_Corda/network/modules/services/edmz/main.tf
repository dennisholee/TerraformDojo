provider "aws" {
  region = var.region
}

#===============================================================================
# VPC
#===============================================================================

resource "aws_vpc" "vpc_edmz" {
  cidr_block = var.edmz_cidr
  tags = {
    Name = "${local.appenv}-edmz-vpc"
  }
}


resource "aws_subnet" "subnet_edmz_az" {
  count                   = length(var.az_subnet_mapping)
  
  vpc_id                  = aws_vpc.vpc_edmz.id
  cidr_block              = lookup(var.az_subnet_mapping[count.index], "cidr")
  availability_zone       = lookup(var.az_subnet_mapping[count.index], "az")
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.appenv}-edmz-${lookup(var.az_subnet_mapping[count.index], "name")}-subnet"
  }
}

#------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------

resource "aws_internet_gateway" "edmz_igw" {

  vpc_id = aws_vpc.vpc_edmz.id

  tags = {
    Name = "${local.appenv}-edmz-igw"
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
  count          = length(var.az_subnet_mapping)

  subnet_id      = element(aws_subnet.subnet_edmz_az.*.id, count.index)
  route_table_id = aws_route_table.edmz_rt.id
}

#------------------------------------------------------------------
# External IP Address
#------------------------------------------------------------------

resource "aws_eip" "edmz_nat_eip" {
  count      = length(var.az_subnet_mapping)
  vpc        = true
  depends_on = [aws_internet_gateway.edmz_igw]
}

#------------------------------------------------------------------
# NAT Gateway 
#------------------------------------------------------------------

resource "aws_nat_gateway" "edmz_nat" {
  count         = length(var.az_subnet_mapping)

  allocation_id = element(aws_eip.edmz_nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.subnet_edmz_az.*.id, count.index)

  tags = {
    Name = "${local.appenv}-edmz-${lookup(var.az_subnet_mapping[count.index], "name")}-nat"
  }

  depends_on = [aws_eip.edmz_nat_eip]
}

#===============================================================================
# Local Variables 
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
