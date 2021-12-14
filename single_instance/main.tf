# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Create a virtual network
resource "azurerm_virtual_network" "qt-vnet-single" {
  name                = var.azurerm_virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group
  tags = {
    Environment = "Terraform Getting Started"
    Team        = "qt-test"
  }
}

# Create subnet
resource "azurerm_subnet" "qt-subnet-single" {
  name                 = var.azurerm_subnet_name
  resource_group_name  = var.azurerm_resource_group
  virtual_network_name = azurerm_virtual_network.qt-vnet-single.name
  address_prefix       = "10.0.1.0/24"
}

# Create NIC
resource "azurerm_network_interface" "qt-nic-single" {
  name                = "qt-nic-single"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.qt-subnet-single.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create VM
resource "azurerm_linux_virtual_machine" "qt-vm-single" {
  name                = "qt-machine"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.qt-nic-single.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
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
