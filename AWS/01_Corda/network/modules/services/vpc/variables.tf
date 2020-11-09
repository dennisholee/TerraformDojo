variable "region" {
  description = "Region"
  type        = string
  default     = "us-east"
}

variable "azones" {
  description = "Availability Zone"
  type        = list(string)
  default     = ["1a", "1b"]
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "app" {
  description = "Application"
  type        = string
}

