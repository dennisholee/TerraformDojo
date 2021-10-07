variable resource_group {
  description = ""
  type        = string
}

variable app {
  description = ""
  type        = string
  default     = "demo"
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

variable subnet_cidr {
  description = ""
  type        = string
  default     = "173.17.1.0/24"
}

