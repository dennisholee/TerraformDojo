locals {
  appenv = "${var.app}${var.env}"
}

resource "aws_key_pair" "deployer" {
  key_name   = "ssh-key"
  public_key = file("${var.key_pair}")
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet_az" {
  count                   = length(var.az_subnet_mapping)
  
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = lookup(var.az_subnet_mapping[count.index], "cidr")
  availability_zone       = lookup(var.az_subnet_mapping[count.index], "az")
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.appenv}-vpc-${lookup(var.az_subnet_mapping[count.index], "name")}-subnet"
  }
}

#-------------------------------------------------------------------------------
# Internet Gateway
#-------------------------------------------------------------------------------
resource "aws_internet_gateway" "edmz_igw" {

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.appenv}-edmz-igw"
  }
}

#-------------------------------------------------------------------------------
# Internet Gateway Route
#-------------------------------------------------------------------------------

resource "aws_route_table" "edmz_rt" {
  vpc_id   = aws_vpc.vpc.id
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

  subnet_id      = element(aws_subnet.subnet_az.*.id, count.index)
  route_table_id = aws_route_table.edmz_rt.id
}

#------------------------------------------------------------------
# Create Firewall Rules
#------------------------------------------------------------------

resource "aws_security_group" "sg_allow_ssh" {
  name        = "${local.appenv}-allow_ssh"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Accept SSH from Internet to Bastion host"
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
    Name = "${local.appenv}-bastion-sg"
  }
}

#------------------------------------------------------------------
# Create Compute Instance
#------------------------------------------------------------------

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
  key_name                    = aws_key_pair.deployer.id
  associate_public_ip_address = true

  subnet_id                   = aws_subnet.subnet_az[0].id

  vpc_security_group_ids      = [aws_security_group.sg_allow_ssh.id]

  tags                        = {
                         Name = "Bastion"
  }
}

