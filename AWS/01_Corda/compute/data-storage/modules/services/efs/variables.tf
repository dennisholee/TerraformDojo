variable "app" {
  type        = string
  default     = "contour"
  description = "Application name"
}


variable "env" {
  type        = string
  description = "Environment name"
}

variable "name" {
  type        = string
  description = "EFS Name"
}

variable "subnet_ids" {
  type        = map
  description = "Subnets to attached the EFS"
}
