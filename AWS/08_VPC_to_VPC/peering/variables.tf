variable app {
  description = ""
  type        = string
  default     = "vpc2vpc"
}


variable env {
  description = ""
  type        = string
  default     = "dev"
}

variable cidr {
  description = ""
  type        = string
}

variable az_subnet_mapping {
  description = ""
  type        = list
}

variable "key_pair" {
  type        = string
  description = "SSH Key"
}
