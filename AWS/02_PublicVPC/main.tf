provider "aws" {
  region = var.region
}

variable "vpc_conf" {
  type    = map
  default = {
    "name" = "public"
    "cidr" = "172.16.0.0/16",
  }
}

variable "az_conf" {
  type    = list
  default = [{
    name = "a",
    cidr = "172.16.1.0/24"
  }]
}

#===============================================================================
# Network
#===============================================================================

resource aws_vpc "main" {
  cidr_block = lookup(var.vpc_conf, "cidr")

  tags = {
    Name = "${local.appenv}-${lookup(var.vpc_conf, "name")}-vpc"
  }
}

resource aws_subnet "subnet" {
  count             = length(var.az_conf)
  vpc_id            = aws_vpc.main.id
  cidr_block        = lookup(var.az_conf[count.index], "cidr")
  availability_zone = "${var.region}${lookup(var.az_conf[count.index], "name")}"

  tags = {
    Name = "${local.appenv}-${lookup(var.az_conf[count.index], "name")}-subnet"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.appenv}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.appenv}-rt"
  }
}

resource "aws_route_table_association" "subnet-association" {
  count          = length(var.az_conf)

  subnet_id      = element(aws_subnet.subnet.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

#===============================================================================
# Security Group 
#===============================================================================

resource "aws_security_group" "allow_ssh_sg" {
  name        = "${local.appenv}-ssh-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.appenv}-ssh-sg"
  }
}

#===============================================================================
# Account Key Pair
#===============================================================================

resource "aws_iam_policy" "policy" {
  name        = "${local.appenv}-allowssh-policy"
  path        = "/"
  description = "My test policy"

  policy = file("./aws_ssh_policy.json")
}

resource "aws_iam_user" "user" {
  name = var.username

  tags = {
    tag-key = "${local.appenv}-tf-user"
  }
}

resource "aws_iam_user_ssh_key" "user" {
  username   = aws_iam_user.user.name
  encoding   = "SSH"
  public_key = file("${var.public_key}")
}

#===============================================================================
# Compute Resource 
#===============================================================================

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
     name   = "owner-alias"
     values = ["amazon"]
  }

  filter {
     name   = "name"
     values = ["amzn2-ami-hvm*"]
  }

  owners = ["amazon"]
}


resource "aws_instance" "instance_bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
#  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true

  subnet_id                   = aws_subnet.subnet[0].id

  vpc_security_group_ids      = [aws_security_group.allow_ssh_sg.id]

  tags                        = {
    Name = "${local.appenv}-bastion"
  }
}


#===============================================================================
# Local variables
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
