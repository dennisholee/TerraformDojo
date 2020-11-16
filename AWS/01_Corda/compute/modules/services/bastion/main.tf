provider "aws" {
  region = "us-east-1"
}

#========================================================================================
# Bastion Host
#========================================================================================

#------------------------------------------------------------------
# Reserve public IP address
#------------------------------------------------------------------

resource "aws_eip" "eip_bastion" {
  vpc      = true
  instance = aws_instance.instance_bastion.id

  tags = {
    Name = "${local.appenv}-${local.subnet_name}-bastion-eip"
  }
}

#------------------------------------------------------------------
# Create Firewall Rules
#------------------------------------------------------------------

resource "aws_security_group" "sg_allow_ssh" {
  name        = "allow_ssh"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

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
    Name = "${local.appenv}-${local.subnet_name}-bastion-sg"
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
  key_name                    = var.key_pair
  associate_public_ip_address = true

  subnet_id                   = values(var.subnet_ids)[0]

  vpc_security_group_ids      = [aws_security_group.sg_allow_ssh.id]

  tags                        = {
                         Name = "Bastion"
  }
}

# resource "aws_eip_association" "eip_assoc_bastion" {
#   instance_id   = aws_instance.instance_bastion.id
#   allocation_id = aws_eip.eip_bastion.id
# }


locals {
  appenv      = "${var.app}-${var.env}"
  subnet_name = var.subnet_name
}
