# ------------------------------------------------------------------------------
# Network
# ------------------------------------------------------------------------------

variable "project"                          { default = "foo789-terraform-admin" }

variable "vpc-name"                         { default = "my-vpc" }
variable "vpc-auto_create_subnet"           { default = "false" }

variable "internal_vpc-name"                { default = "my-internal" }
variable "internal_vpc-auto_create_subnet"  { default = "false" }

variable "idmz_vpc-name"                    { default = "my-idmz" }
variable "idmz_vpc-auto_create_subnet"      { default = "false" }

variable "edmz_vpc-name"                    { default = "my-edmz" }
variable "edmz_vpc-auto_create_subnet"      { default = "false" }

variable "pri-name"                         { default = "my-pri" } 
variable "pri-region"                       { default = "europe-west2" } 
variable "pri-ip_range"                     { default = "172.16.0.0/24" } 
variable "pri-private_google_access"        { default = "false" } 
variable "pri-pod_ip_range"                 { default = "172.28.64.0/18" }
variable "pri-svc_ip_range"                 { default = "172.28.128.0/18" }

variable "mgnt-name"                        { default = "my-mgnt" } 
variable "mgnt-region"                      { default = "europe-west2" } 
variable "mgnt-ip_range"                    { default = "172.16.1.0/24" } 
variable "mgnt-private_google_access"       { default = "false" } 

variable "internal-name"                    { default = "my-internal" } 
variable "internal-region"                  { default = "europe-west2" } 
variable "internal-ip_range"                { default = "172.16.2.0/24" } 
variable "internal-private_google_access"   { default = "false" } 

variable "idmz-name"                        { default = "my-idmz" } 
variable "idmz-region"                      { default = "europe-west2" } 
variable "idmz-ip_range"                    { default = "172.16.3.0/24" } 
variable "idmz-private_google_access"       { default = "false" } 

variable "edmz-name"                        { default = "my-edmz" } 
variable "edmz-region"                      { default = "europe-west2" } 
variable "edmz-ip_range"                    { default = "172.16.4.0/24" } 
variable "edmz-private_google_access"       { default = "false" } 
