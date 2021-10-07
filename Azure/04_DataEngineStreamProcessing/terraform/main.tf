provider "azurerm" {
  skip_provider_registration = "true"

  features {
  }
}

locals {
  appenv = "${var.app}-${var.env}"
}

data "azurerm_resource_group" "resource-group" {
  name     = var.resource_group
}

resource "azurerm_virtual_network" "demo" {
  name                = "${local.appenv}-vpc"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  address_space       = [var.cidr]
}

resource "azurerm_subnet" "demo" {
  name                 = "${local.appenv}-subnet"
  
  resource_group_name  = data.azurerm_resource_group.resource-group.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_public_ip" "demo" {
  name                = "${local.appenv}-ip"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "demo" {
  name                = "${local.appenv}-nic"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo.id
  }
}

resource "azurerm_linux_virtual_machine" "demo" {
  name                  = "${local.appenv}-machine"
  resource_group_name   = data.azurerm_resource_group.resource-group.name
  location              = data.azurerm_resource_group.resource-group.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.demo.id
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


#===============================================================================
# Event Hub
#===============================================================================

resource "azurerm_eventhub_namespace" "demo" {
  name                = "${local.appenv}-eventhub-namespace"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    environment = var.env
  }
}

resource "azurerm_eventhub" "demo" {
  name                = "${local.appenv}-eventhub"
  namespace_name      = azurerm_eventhub_namespace.eventhub-namespace.name
  resource_group_name = azurerm_resource_group.resource-group.name
  partition_count     = 2
  message_retention   = 1
}
