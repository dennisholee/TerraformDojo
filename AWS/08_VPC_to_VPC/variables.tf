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

variable "key_pair" {
  type        = string
  description = "SSH Key"
}
