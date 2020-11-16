variable "app" {
  type        = string
  default     = "contour"
  description = "Application name"
}


variable "env" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_name"{
  type        = string
  description = "Subnet name"
}

variable "subnet_ids" {
  type        = map
  description = "Subnet ID"
}

variable "key_pair" {
  type        = string
  description = "SSH Key"
}
