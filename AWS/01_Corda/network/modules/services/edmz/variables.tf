variable "region" {
  description = "Deployment region"
  type        = string
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "app" {
  description = "Application"
  type        = string
}

variable "edmz_cidr" {
  description = "VPC CIDR"
  type        = string
#  default     = "172.16.0.0/16"
}

variable "az_subnet_mapping" {
  type        = list
  description = "Lists the subnets to be created in their respective AZ."

#   default = [
#     {
#       name = "1a"
#       az   = "us-east-1a"
#       cidr = "172.16.1.0/24"
#     },
#     {
#       name = "1b"
#       az   = "us-east-1b"
#       cidr = "172.16.2.0/24"
#     },
#   ]
}

