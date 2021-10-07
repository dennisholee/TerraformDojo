provider "azurerm" {
  skip_provider_registration = "true"

  features {
  }
}

locals {
  appenv   = "${var.app}-${var.env}"
  location = "westus2" 
}

data "azurerm_resource_group" "resource-group" {
  name     = var.resource_group
}

#===============================================================================
# Network
#===============================================================================

resource "azurerm_virtual_network" "demo" {
  name                = "${local.appenv}-vpc"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  address_space       = [var.cidr]
}

#-------------------------------------------------------------------------------
# Subnets
#-------------------------------------------------------------------------------

resource "azurerm_subnet" "demo-subnet-frontend" {
  name                 = "${local.appenv}-subnet-frontend"
  
  resource_group_name  = data.azurerm_resource_group.resource-group.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_subnet" "demo-subnet-backend" {
  name                 = "${local.appenv}-subnet-backend"
  
  resource_group_name  = data.azurerm_resource_group.resource-group.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = [var.internal_cidr]
}

#-------------------------------------------------------------------------------
# Network Security Group
#-------------------------------------------------------------------------------

resource "azurerm_network_security_group" "demo" {
  name                = "${local.appenv}-security-group"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  tags = {
    environment = var.env
  }
}

resource "azurerm_network_security_rule" "demo-ssh" {
  name                        = "${local.appenv}-security-rule-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  network_security_group_name = azurerm_network_security_group.demo.name
}


resource "azurerm_network_security_rule" "demo-http" {
  name                        = "${local.appenv}-security-rule-http"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  network_security_group_name = azurerm_network_security_group.demo.name
}

#-------------------------------------------------------------------------------
# Public IP Addresses
#-------------------------------------------------------------------------------

resource "azurerm_public_ip" "demo" {
  name                = "${local.appenv}-ip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "demo" {
  name                = "${local.appenv}-nic"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo-subnet-frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo.id
  }
}


resource "azurerm_public_ip" "nat" {
  name                = "${local.appenv}-nat-ip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = "1"
}


#-------------------------------------------------------------------------------
# Private IP Addresses
#-------------------------------------------------------------------------------

resource "azurerm_network_interface" "demo-private-nic" {
  name                = "${local.appenv}-private-nic"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "${local.appenv}-internal-ip"
    subnet_id                     = azurerm_subnet.demo-subnet-frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

#-------------------------------------------------------------------------------
# Security Group Association
#-------------------------------------------------------------------------------

resource "azurerm_network_interface_security_group_association" "demo" {
  network_interface_id      = azurerm_network_interface.demo-private-nic.id
  network_security_group_id = azurerm_network_security_group.demo.id
}

#-------------------------------------------------------------------------------
# NAT Gateway
#-------------------------------------------------------------------------------

resource "azurerm_nat_gateway" "nat-gateway" {
  name                    = "${local.appenv}-nat-gateway"
  location                = local.location
  resource_group_name     = data.azurerm_resource_group.resource-group.name
#  public_ip_address_ids   = [azurerm_public_ip.nat.id]
#  public_ip_prefix_ids    = [azurerm_public_ip_prefix.example.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_nat_gateway_public_ip_association" "nat-gateway" {
  nat_gateway_id       = azurerm_nat_gateway.nat-gateway.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.demo-subnet-frontend.id
  nat_gateway_id = azurerm_nat_gateway.nat-gateway.id
}

#-------------------------------------------------------------------------------
# Application load balancer
#-------------------------------------------------------------------------------

resource "azurerm_public_ip" "loadbalancer" {
  name                = "${local.appenv}-loadbalancer-ip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "loadbalancer" {
  name                = "${local.appenv}-loadbalancer"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${local.appenv}-loadbalancer-ip-config"
    public_ip_address_id = azurerm_public_ip.loadbalancer.id
  }
}

resource "azurerm_lb_rule" "loadbalancer" {
  name                           = "${local.appenv}-loadbalancer-rule"
  resource_group_name            = data.azurerm_resource_group.resource-group.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  protocol                       = "TCP"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "${local.appenv}-loadbalancer-ip-config"
  probe_id                       = azurerm_lb_probe.loadbalancer.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.loadbalancer.id
}

resource "azurerm_lb_rule" "loadbalancer-rule-http" {
  name                           = "${local.appenv}-loadbalancer-rule-http"
  resource_group_name            = data.azurerm_resource_group.resource-group.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${local.appenv}-loadbalancer-ip-config"
  probe_id                       = azurerm_lb_probe.loadbalancer.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.loadbalancer.id
}

resource "azurerm_lb_probe" "loadbalancer" {
  name                = "${local.appenv}-lb-probe-ssh"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  protocol            = "TCP"
  port                = 22
}

resource "azurerm_lb_probe" "loadbalancer-probe-http" {
  name                = "${local.appenv}-lb-probe-http"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  protocol            = "TCP"
  port                = 80
}

resource "azurerm_lb_backend_address_pool" "loadbalancer" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "${local.appenv}-loadbalancer-backend"
}

resource "azurerm_lb_backend_address_pool_address" "loadbalancer" {
  name                    = "${local.appenv}-lb"
  backend_address_pool_id = azurerm_lb_backend_address_pool.loadbalancer.id
  virtual_network_id      = azurerm_virtual_network.demo.id
  ip_address              = azurerm_network_interface.demo-private-nic.private_ip_address
}

#===============================================================================
# Compute Resources
#===============================================================================

#-------------------------------------------------------------------------------
# Web VM
#-------------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "demo" {
  name                  = "${local.appenv}-machine"
  resource_group_name   = data.azurerm_resource_group.resource-group.name
  location              = local.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [
   azurerm_network_interface.demo-private-nic.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_pubkey)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  custom_data = filebase64("cloud-init.tpl")
}

resource "azurerm_linux_virtual_machine_scale_set" "demo" {
  name                = "${local.appenv}-vm-scaleset"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = local.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.demo-subnet-backend.id
    }
  }
}

#-------------------------------------------------------------------------------
# Define action group to specify notification preferences
#-------------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "monitor-action-group" {
  name                = "${local.appenv}-monitor-action-group"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  short_name          = "mntractgrp"

  email_receiver {
    name          = "sendtosupport"
    email_address = var.email_address
  }
}

#-------------------------------------------------------------------------------
# Monitoring alert
#-------------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "alert-cpu" {
  name                = "${local.appenv}-monitor-metric-alert-cpu"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  scopes              = [azurerm_linux_virtual_machine.demo.id]
  description         = "Action will be triggered when CPU count is greater than 80."

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitor-action-group.id
  }
}

#===============================================================================
# Azure Front Door
#===============================================================================

resource "azurerm_frontdoor" "demo" {
  name                                         = "${local.appenv}-frontdoor"
#  location                                     = local.location
  resource_group_name                          = data.azurerm_resource_group.resource-group.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "${local.appenv}-frontdoor-wwwrr"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["${local.appenv}-frontdoor"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "exampleBackendBing"
    }
  }

  backend_pool_load_balancing {
#    name = "exampleLoadBalancingSettings1"
    name = azurerm_lb.loadbalancer.name
  }

  backend_pool_health_probe {
#    name = "exampleHealthProbeSetting1"
    name = azurerm_lb_probe.loadbalancer-probe-http.name
  }

  backend_pool {
    name = "exampleBackendBing"
    backend {
      host_header = "foo.com"
      address     = azurerm_public_ip.loadbalancer.ip_address #fqdn # "www.bing.com"
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = azurerm_lb.loadbalancer.name # "exampleLoadBalancingSettings1"
    health_probe_name   = azurerm_lb_probe.loadbalancer-probe-http.name # "exampleHealthProbeSetting1"
  }

  frontend_endpoint {
    name      = "${local.appenv}-frontdoor"
    host_name = "${local.appenv}-frontdoor.azurefd.net"
  }
}

#===============================================================================
# Log Analytics
#===============================================================================

resource "azurerm_log_analytics_workspace" "log-analytics-workspace" {
  name                = "${local.appenv}-log-analytics-workspace"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "log-analytics-solution" {
  solution_name         = "ContainerInsights"
  location              = local.location
  resource_group_name   = data.azurerm_resource_group.resource-group.name
  workspace_resource_id = azurerm_log_analytics_workspace.log-analytics-workspace.id
  workspace_name        = azurerm_log_analytics_workspace.log-analytics-workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}

resource "azurerm_virtual_machine_extension" "oms_mma02" {
  name                       = "test-OMSExtension"
  virtual_machine_id         =  azurerm_linux_virtual_machine.demo.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.12"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" : "${azurerm_log_analytics_workspace.log-analytics-workspace.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${azurerm_log_analytics_workspace.log-analytics-workspace.primary_shared_key}"
    }
  PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "da" {
  name                       = "DAExtension"
  virtual_machine_id         = azurerm_linux_virtual_machine.demo.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

}

resource "azurerm_virtual_machine_scale_set_extension" "monitoring" {
  name                         = "MMAExtension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.demo.id
  publisher                    = "Microsoft.EnterpriseCloud.Monitoring"
  type                         = "OmsAgentForLinux"
  type_handler_version         = "1.13"
  auto_upgrade_minor_version   = true

  settings = <<SETTINGS
  {
     "workspaceId": "${azurerm_log_analytics_workspace.log-analytics-workspace.workspace_id}"
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
      "workspaceKey": "${azurerm_log_analytics_workspace.log-analytics-workspace.primary_shared_key}"
  }
  PROTECTED_SETTINGS

  #depends_on = [ azurerm_kubernetes_cluster.aks-cluster ]
}
