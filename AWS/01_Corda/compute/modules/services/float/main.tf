provider "aws" {
  region = "us-east-1"
}

#========================================================================================
# Float Host
#========================================================================================

#------------------------------------------------------------------
# Create Firewall Rules
#------------------------------------------------------------------

resource "aws_security_group" "float_sg" {
  name        = "float_sg"
  description = "Float Proxy security group"
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
    Name = "${local.appenv}-${local.subnet_name}-float-sg"
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
# Float Auto Scale Group
#===============================================================================

resource "aws_launch_configuration" "float_lcf" {
  name            = "${local.appenv}-${local.subnet_name}-float-lcf"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.float_sg.id]
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

resource "aws_lb_target_group" "float_lbtg" {
  name     = "${local.appenv}-${local.subnet_name}-float-lbtg"
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

resource "aws_autoscaling_group" "float_asg" {
  vpc_zone_identifier  = values(var.subnet_ids)
  desired_capacity     = 1 
  max_size             = 1
  min_size             = 1

  launch_configuration = aws_launch_configuration.float_lcf.id
  target_group_arns    = [aws_lb_target_group.float_lbtg.arn] 


  lifecycle {
    ignore_changes        = [load_balancers, target_group_arns]
    create_before_destroy = true
  }

  tags = concat([
    {
      key   = "Name"
      value = "${local.appenv}-${local.subnet_name}-float-asg"
      propagate_at_launch = true
    } 
  ])
}


resource "aws_lb" "float_lb" {
  name               = "${local.appenv}-${local.subnet_name}-float-lb"
  internal           = true
  load_balancer_type = "network"

  subnets            = values(var.subnet_ids)

  enable_deletion_protection = true

  tags = {
    Name = "${local.appenv}-${local.subnet_name}-float-lb"
  }
}

resource "aws_lb_listener" "float_lb_listener"{
  load_balancer_arn = aws_lb.float_lb.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.float_lbtg.arn
  }
}


#===============================================================================
# Local variables
#===============================================================================

locals {
  appenv      = "${var.app}-${var.env}"
  subnet_name = var.subnet_name

  float_vpce_name = "${var.app}-${var.env}-${var.subnet_name}-socks-vpce"
}
