provider "aws" {
  region = "us-east-1"
}

#========================================================================================
# Bridge Host
#========================================================================================

#------------------------------------------------------------------
# Create Firewall Rules
#------------------------------------------------------------------

resource "aws_security_group" "bridge_sg" {
  name        = "bridge_sg"
  description = "Bridge Proxy security group"
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
    Name = "${local.appenv}-${local.subnet_name}-bridge-sg"
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


#===============================================================================
# Bridge Auto Scale Group
#===============================================================================

resource "aws_launch_configuration" "bridge_lcf" {
  name            = "${local.appenv}-${local.subnet_name}-bridge-lcf"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.bridge_sg.id]
  key_name        = var.key_pair

#   user_data = <<-EOF
#               #!/bin/bash
#               echo "Hello, World" > index.html
#               nohup busybox httpd -f -p "${var.server_port}" &
#               EOF

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lb_target_group" "bridge_lbtg" {
  name     = "${local.appenv}-${local.subnet_name}-bridge-lbtg"
  port     = "22"
  protocol = "TCP"
  vpc_id   = var.vpc_id
  deregistration_delay = "300"
  health_check {
    interval = "10"
    port = "22"
    protocol = "TCP"
    healthy_threshold = "10" 
    unhealthy_threshold= "10" 
  }
}

resource "aws_autoscaling_group" "bridge_asg" {
  vpc_zone_identifier  = [var.subnet_id]
  desired_capacity     = 3
  max_size             = 3
  min_size             = 3

  launch_configuration = aws_launch_configuration.bridge_lcf.id
  target_group_arns    = [aws_lb_target_group.bridge_lbtg.arn] 


  lifecycle {
    ignore_changes        = [load_balancers, target_group_arns]
    create_before_destroy = true
  }

  tags = concat([
    {
      key   = "Name"
      value = "${local.appenv}-${local.subnet_name}-bridge-asg"
      propagate_at_launch = true
    } 
  ])
}


resource "aws_lb" "bridge_lb" {
  name               = "${local.appenv}-${local.subnet_name}-bridge-lb"
  internal           = true
  load_balancer_type = "network"

  subnets            = [local.subnet_id]

  enable_deletion_protection = true

  tags = {
    Name = "${local.appenv}-${local.subnet_name}-bridge-lb"
  }
}

resource "aws_lb_listener" "bridge_lb_listener"{
  load_balancer_arn = aws_lb.bridge_lb.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bridge_lbtg.arn
  }
}

#===============================================================================
# VPC Endpoint Service
#===============================================================================

resource "aws_vpc_endpoint_service" "bridge_vpce" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.bridge_lb.arn]

  tags = {
    Name = "${local.appenv}-${local.subnet_name}-bridge-vpce"
  }
}

#===============================================================================
# Local variables
#===============================================================================

locals {
  appenv      = "${var.app}-${var.env}"
  subnet_name = var.subnet_name
  subnet_id   = var.subnet_id

  bridge_vpce_name = "${var.app}-${var.env}-${var.subnet_name}-socks-vpce"
}
