variable "var_project"                          { default = "foo789-terraform-admin" }
variable "var_vpc"                              { default = "my-vpc" }
variable "var_vpc-name"                         { default = "my-vpc-name" }
variable "var_vpc-auto_create_subnet"           { default = "false" }

variable "var_vpc_subnet"                       { default = "my-vpc-subnet" }
variable "var_vpc_subnet-name"                  { default = "my-vpc-subnet-name" } 
variable "var_vpc_subnet-region"                { default = "europe-west2" } 
variable "var_vpc_subnet-ip_range"              { default = "172.23.32.0/19" } 
variable "var_vpc_subnet-private_google_access" { default = "true" } 


