module "us-east-1" {
  source = "./peering"

  providers = {
    aws = aws.region-one
  }

  cidr = "172.16.0.0/16"
  az_subnet_mapping = [
    { 
      name = "1a"
      az   = "us-east-1a"
      cidr = "172.16.1.0/24"
    },
    { 
      name = "1b"
      az   = "us-east-1b"
      cidr = "172.16.2.0/24"
    },
  ]
  key_pair = var.key_pair
}


module "us-west-2" {
  source = "./peering"

  providers = {
    aws = aws.region-two
  }

  cidr = "173.17.0.0/16"
  az_subnet_mapping = [
    { 
      name = "1a"
      az   = "us-west-2a"
      cidr = "173.17.1.0/24"
    },
    { 
      name = "1b"
      az   = "us-west-2b"
      cidr = "173.17.2.0/24"
    },
  ]
  key_pair = var.key_pair
}

data "aws_caller_identity" "peer" {
  provider = aws.region-two
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  provider = aws.region-one

  vpc_id        = module.us-east-1.vpc.id
  peer_vpc_id   = module.us-west-2.vpc.id
  peer_owner_id = data.aws_caller_identity.peer.account_id
  peer_region   = "us-west-2"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider = aws.region-two

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

