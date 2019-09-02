variable "project" {
  description = "Google Project ID"
}

variable "public_key" {
  description = "RSA public key for SSH to compute engine"
}

variable "region" {
  description = "Default GCP region"
  default     = "asia-east2"
}

variable "zone" {
  description = "Default GCP zone"
  default     = "asia-east2-a"
}
