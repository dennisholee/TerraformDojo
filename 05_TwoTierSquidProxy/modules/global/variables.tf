# ------------------------------------------------------------------------------
# Network
# ------------------------------------------------------------------------------

variable "vpc-name"                         { default = "my-vpc" }
variable "vpc-auto_create_subnet"           { default = "false" }

variable "region"                           { }

variable "internal_vpc-name"                { default = "my-internal" }
variable "internal_vpc-auto_create_subnet"  { default = "false" }

variable "idmz_vpc-name"                    { default = "my-idmz" }
variable "idmz_vpc-auto_create_subnet"      { default = "false" }

variable "edmz_vpc-name"                    { default = "my-edmz" }
variable "edmz_vpc-auto_create_subnet"      { default = "false" }

variable "internal-name"                    { default = "my-internal" } 
variable "internal-ip_range"                { default = "192.168.1.0/24" } 
variable "internal-private_google_access"   { default = "false" } 

variable "idmz-name"                        { default = "my-idmz" } 
variable "idmz-ip_range"                    { default = "192.168.2.0/24" } 
variable "idmz-private_google_access"       { default = "false" } 

variable "edmz-name"                        { default = "my-edmz" } 
variable "edmz-ip_range"                    { default = "192.168.3.0/24" } 
variable "edmz-private_google_access"       { default = "false" } 
