provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

locals {
  appenv       = "${var.app}-${var.env}"
  s3_origin_id = var.app 
  region       = "us-west-2"
}

resource "random_string" "random" {
  length           = 8
  min_lower        = 8
  special          = true
  override_special = "/@£$"
}

resource "aws_key_pair" "deployer" {
  key_name   = "ssh-key"
  public_key = file("${var.ssh_pubkey}")
}

#-------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------

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
  subnet_id      = aws_subnet.subnet_az[0].id
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
  count                       = length(aws_subnet.subnet_az)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.id
  associate_public_ip_address = true

  iam_instance_profile        = aws_iam_instance_profile.test_profile.name

  subnet_id                   = aws_subnet.subnet_az[count.index].id

  vpc_security_group_ids      = [aws_security_group.sg_allow_ssh.id]

  tags                        = {
                         Name = "Bastion"
  }
}

#-------------------------------------------------------------------------------
# S3 Bucket for docs
#-------------------------------------------------------------------------------

# S3 bucket
resource "aws_s3_bucket" "doc-bucket" {
  bucket = "${local.appenv}-${random_string.random.result}-doc-bucket"
  acl    = "private"

  tags = {
    Name        = "${local.appenv}-doc-bucket"
    Environment = var.env
  }
}

resource "aws_s3_bucket" "private-bucket" {
  bucket = "${local.appenv}-${random_string.random.result}-private-bucket"
  acl    = "private"

  tags = {
    Name        = "${local.appenv}-private-bucket"
    Environment = var.env
  }
}

resource "aws_s3_bucket_object" "dist" {
  for_each = fileset("../s3", "*")

  bucket = aws_s3_bucket.doc-bucket.id
  key    = each.value
  source = "../s3/testfile.txt"
  content_type = "text/plain"
  content_encoding = "UTF-8"
}

# ACL

resource "aws_iam_role" "ec2s3_role" {
  name = "a_ec2s3_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "policy" {
  name        = "s3_policy"
  path        = "/" 

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {   
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],  
            "Resource": "*" 
        }   
    ]   
  })  
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.ec2s3_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.ec2s3_role.name
}

#-------------------------------------------------------------------------------
# Endpoint Gateway to S3 
#-------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = var.s3_vpc_endpoint
  policy        = <<POLICY
{
    "Statement": [
       {
         "Action": ["s3:Get*",
           "s3:List*"
         ],
         "Effect": "Allow",
         "Resource": [ "${aws_s3_bucket.doc-bucket.arn}",
                       "${aws_s3_bucket.doc-bucket.arn}/*"],
         "Principal": "*"
       }
     ]
}
POLICY
  
}

resource "aws_route_table" "s3" {
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${local.appenv}-edmz-rt"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_route_table.s3.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_route_table_association" "s3" {
  subnet_id      = aws_subnet.subnet_az[1].id
  route_table_id = aws_route_table.s3.id
}

