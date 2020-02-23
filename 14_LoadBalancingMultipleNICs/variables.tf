variable "project_id" {
  description = "Google Project ID"
}

variable "public_key" {
  description = "RSA public key for SSH to compute engine"
}

variable "region" {
  description = "Default GCP region"
  default     = "us-central1"
}

variable "zone" {
  description = "Default GCP zone"
  default     = "us-central1-a"
}
