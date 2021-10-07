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

variable firewall_cidr {
  description = ""
  type        = string
  default     = "173.17.1.0/26"
}

variable subnet_cidr {
  description = ""
  type        = string
  default     = "173.17.2.0/26"
}

variable internal_cidr {
  description = ""
  type        = string
  default     = "173.17.3.0/26"
}

variable "firewall_service_endpoints" {
  description = "Service endpoints to add to the firewall subnet"
  type        = list(string)
  default = [
#    "Microsoft.AzureActiveDirectory",
#    "Microsoft.AzureCosmosDB",
#    "Microsoft.EventHub",
    "Microsoft.KeyVault",
#    "Microsoft.ServiceBus",
#    "Microsoft.Sql",
#    "Microsoft.Storage",
  ]
}

variable email_address {
  description = ""
  type        = string
}

variable tags {
  description = ""
  type        = map(string)
  default     = {}
}
