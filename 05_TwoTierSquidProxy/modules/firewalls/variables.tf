# ------------------------------------------------------------------------------
# Firewall
# ------------------------------------------------------------------------------

variable "firewall-name"                  {}
variable "firewall-network"               {} 
variable "firewall-direction"             { default = "INGRESS" }
variable "firewall-protocol"              { default = "tcp" }
variable "firewall-ports"                 {}
variable "firewall-source_range"          { default = [] }
variable "firewall-target_tags"           {}
