provider "aws" {
  profile = "default"
  region  = var.region
}

locals {
  appenv       = "${var.app}-${var.env}"
  s3_origin_id = var.app 
#  region       = "us-west-2"
}

resource "random_string" "random" {
  length           = 8
  min_lower        = 8
  special          = true
  override_special = "/@£$"
}

#===============================================================================
# Account Key Pair
#===============================================================================

resource "aws_iam_policy" "policy" {
  name        = "${local.appenv}-allowssh-policy"
  path        = "/"
  description = "Allow SSH policy"

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
# VPC
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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  count          = length(aws_subnet.subnet)

  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.table.id
}

resource aws_network_acl "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for s in aws_subnet.subnet : s.id]
  
  ingress = [
    { 
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 22
      to_port    = 22
      icmp_code  = 0
      icmp_type  = 0
      ipv6_cidr_block = null
    }
  ]

  egress = [
    { 
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
      icmp_code  = 0
      icmp_type  = 0
      ipv6_cidr_block = null
    }
  ]
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
# ENIs
#===============================================================================

resource "aws_network_interface" "test" {
  count           = length(aws_subnet.subnet)

  subnet_id       = aws_subnet.subnet[count.index].id
  security_groups = [aws_security_group.allow_ssh_sg.id]
}

resource "aws_eip" "one" {
  count                     = length(aws_subnet.subnet)

  vpc                       = true
  network_interface         = aws_network_interface.test[count.index].id
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
  count                       = length(aws_subnet.subnet)

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
#  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true

  subnet_id                   = aws_subnet.subnet[count.index].id

  vpc_security_group_ids      = [aws_security_group.allow_ssh_sg.id]

  tags                        = {
    Name = "${local.appenv}-bastion"
  }
}

resource "aws_network_interface_attachment" "test" {
  count                = length(aws_subnet.subnet)
  
  instance_id          = aws_instance.instance_bastion[count.index].id
  network_interface_id = aws_network_interface.test[count.index].id
  device_index         = 1
}

#===============================================================================
# Flow log
#===============================================================================

resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "example" {
  name = "example"
}

resource "aws_iam_role" "example" {
  name = "example"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  name = "example"
  role = aws_iam_role.example.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
