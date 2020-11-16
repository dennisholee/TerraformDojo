provider "aws" {
  region = "us-east-1"
}

data "aws_vpc_endpoint_service" "vpces" {
  service_type = "Interface"
  service_name = var.service_name 
}

#========================================================================================
# Service Endpoint
#========================================================================================

resource "aws_vpc_endpoint" "vpce" {
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = data.aws_vpc_endpoint_service.vpces.service_name

  subnet_ids        = values(var.subnet_ids)

  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.appenv}-${var.subnet_name}-${var.service_name}-eni"
  }
}

resource "aws_security_group" "vpce_sg" {
  name        = "corda_sg"
  description = "Corda security group"
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
    Name = "${local.appenv}-${var.subnet_name}-${var.service_name}-eni-sg"
  }
}


#===============================================================================
# Local variables
#===============================================================================

locals {
  appenv      = "${var.app}-${var.env}"
}
