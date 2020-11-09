resource "aws_vpc" "vpc_edmz" {
  cidr_block = local.edmz_cidr

  tags = {
    Name = "contour-${local.appenv}-edmz-vpc"
  }
}

resource "aws_subnet" "subnet_edmz_az1" {
  vpc_id            = aws_vpc.vpc_edmz.id
  cidr_block        = local.edmz_subnet1
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_edmz_az2" {
  vpc_id            = aws_vpc.vpc_edmz.id
  cidr_block        = local.edmz_subnet2
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "subnet_edmz_az3" {
  vpc_id            = aws_vpc.vpc_edmz.id
  cidr_block        = local.edmz_subnet3
  availability_zone = "us-east-1c"
}

resource "aws_internet_gateway" "igw_edmz" {
  vpc_id = aws_vpc.vpc_edmz.id

  tags = {
    Name = "contour-${local.appenv}-edmz-igw"
  }
}

resource "aws_route_table" "rt_edmz" {
  vpc_id   = aws_vpc.vpc_edmz.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_edmz.id
  }

  tags = {
    Name = "contour-${local.appenv}-edmz-rt"
  }
}

locals {
    appenv       = "${var.app}-${var.env}"
    edmz_cidr    = "10.1.0.0/16"
    edmz_subnet1 = "10.1.1.0/24"
    edmz_subnet2 = "10.1.2.0/24"
    edmz_subnet3 = "10.1.3.0/24"
}

