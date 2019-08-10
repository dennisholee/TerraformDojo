variable "var_project"                          { default = "foo789-terraform-admin" }
variable "var_vpc"                              { default = "my-vpc" }
variable "var_vpc-name"                         { default = "my-vpc-name" }
variable "var_vpc-auto_create_subnet"           { default = "false" }

variable "var_vpc_internal"                       { default = "my-vpc-internal" }
variable "var_vpc_internal-name"                  { default = "my-vpc-internal-name" } 
variable "var_vpc_internal-region"                { default = "europe-west2" } 
variable "var_vpc_internal-ip_range"              { default = "172.23.32.0/19" } 
variable "var_vpc_internal-private_google_access" { default = "true" } 


variable "var_vpc_dmz"                       { default = "my-vpc-dmz" }
variable "var_vpc_dmz-name"                  { default = "my-vpc-dmz-name" } 
variable "var_vpc_dmz-region"                { default = "europe-west2" } 
variable "var_vpc_dmz-ip_range"              { default = "172.24.4.0/24" } 
variable "var_vpc_dmz-private_google_access" { default = "true" } 
