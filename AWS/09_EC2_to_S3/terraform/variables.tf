variable app {
  description = ""
  type        = string
  default     = "ec2s3"
}

variable env {
  description = ""
  type        = string
  default     = "dev"
}

variable ssh_pubkey {
  description = ""
  type        = string
}

variable cidr {
  description = ""
  type        = string
  default     = "173.17.0.0/16"
}

variable az_subnet_mapping {
  description = ""
  type        = list
  default     = [ 
    {   
      name = "1a"
      az   = "us-west-2a"
      cidr = "173.17.1.0/24"
    },  
    {   
      name = "1b"
      az   = "us-west-2b"
      cidr = "173.17.2.0/24"
    }
  ]
}

variable s3_vpc_endpoint {
  description = ""
  type        = string
  default     = "com.amazonaws.us-west-2.s3"
}
