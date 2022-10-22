variable region {
  description = ""
  type        = string
  default     = "us-west-2"
}

variable app {
  description = ""
  type        = string
  default     = "apikey"
}


variable env {
  description = ""
  type        = string
  default     = "dev"
}

variable username {
  type        = string
  description = "SSH username"
}

variable public_key {
  type        = string
  description = "RSA public key for SSH to compute engine"
}

variable vpc_conf {
  type        = map
  description = ""
  default     = {
    "name" = "dmz"
    "cidr" = "192.168.1.0/24",
  }
}

variable az_conf {
  type        = list
  description = "List of DMZs"
  default     = [
    { name = "a", cidr = "192.168.1.64/26" },
    { name = "b", cidr = "192.168.1.192/26" },
  ]
}

