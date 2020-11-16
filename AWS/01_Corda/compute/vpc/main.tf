# #===============================================================================
# # eDMZ
# #===============================================================================
# 
# data "aws_vpc" "edmz_vpc" {
#   tags = {
#     Name = "${local.appenv}-edmz-vpc"
#   }
# }
# 
# #
# data "aws_subnet_ids" "edmz_subnets" {
#   vpc_id = data.aws_vpc.edmz_vpc.id
# }
# 
# data "aws_subnet" "edmz_subnet" {
#   tags = {
#     Name = "${local.appenv}-edmz-1a-subnet"
#   }
# }
# 
# data "aws_internet_gateway" "edmz_igw" {
#   tags = {
#     Name = "${local.appenv}-edmz-1b-igw"
#   }
# }

data "aws_vpc" "edmz_vpc" {
  tags = {
    Name = "${local.appenv}-edmz-vpc"
  }
}

data "aws_subnet_ids" "edmz_subnet_ids" {
  vpc_id = data.aws_vpc.edmz_vpc.id
}

data "aws_subnet" "edmz_subnet" {
  count = length(data.aws_subnet_ids.edmz_subnet_ids.ids)
  id    = tolist(data.aws_subnet_ids.edmz_subnet_ids.ids)[count.index]
}

#===============================================================================
# iDMZ
#===============================================================================

data "aws_vpc" "idmz_vpc" {
  tags = {
    Name = "${local.appenv}-idmz-vpc"
  }
}

data "aws_subnet_ids" "idmz_subnet_ids" {
  vpc_id = data.aws_vpc.idmz_vpc.id
}

data "aws_subnet" "idmz_subnet" {
  count = length(data.aws_subnet_ids.idmz_subnet_ids.ids)
  id    = tolist(data.aws_subnet_ids.idmz_subnet_ids.ids)[count.index]
}


#===============================================================================
# Local variables
#===============================================================================

locals {
  appenv = "${var.app}-${var.env}"
}
