variable "region" {
  description = "Deployment region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "app" {
  description = "Application"
  type        = string
}

#===============================================================================
# eDMZ
#===============================================================================

variable "edmz_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.16.0.0/16"
}

variable "edmz_az_subnet_mapping" {
  type        = list
  description = "Lists the subnets to be created in their respective AZ."

  default = [
    {
      name = "1a"
      az   = "us-east-1a"
      cidr = "172.16.1.0/24"
    },
  ]
}


#===============================================================================
# iDMZ 
#===============================================================================

variable "idmz_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.17.0.0/16"
}

variable "idmz_az_subnet_mapping" {
  type        = list
  description = "Lists the subnets to be created in their respective AZ."

  default = [
    {
      name = "1a"
      az   = "us-east-1a"
      cidr = "172.17.1.0/24"
    },
  ]
}
