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

  security_rule {
    name                       = "${local.appenv}-security-rule-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.env
  }
}

#-------------------------------------------------------------------------------
# Public IP Addresses
#-------------------------------------------------------------------------------

resource "azurerm_public_ip" "demo" {
  name                = "${local.appenv}-ip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
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

resource "azurerm_lb_probe" "loadbalancer" {
  name                = "${local.appenv}-lb-probe-ssh"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  protocol            = "TCP"
  port                = 22
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
