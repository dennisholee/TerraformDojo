variable region {
  type        = string
  description = "Deployment region"
}

variable app {
  type        = string
  description = "Name of application"
}

variable env {
  type        = string
  description = "Environment name"
}

variable username {
  type        = string
  description = "SSH username"
}

variable public_key {
  type        = string
  description = "RSA public key for SSH to compute engine"
}
