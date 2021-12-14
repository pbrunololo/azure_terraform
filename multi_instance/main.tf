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
resource "azurerm_virtual_network" "qt-vnet-multi" {
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
resource "azurerm_subnet" "qt-subnet-multi" {
  name                 = var.azurerm_subnet_name
  resource_group_name  = var.azurerm_resource_group
  virtual_network_name = azurerm_virtual_network.qt-vnet-multi.name
  address_prefix       = "10.0.1.0/24"
}

# Create NIC
resource "azurerm_network_interface" "qt-nic-multi" {
  name                = "${var.azurerm_nic_name}-${count.index}"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group
  count               = var.azurerm_nic_count

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.qt-subnet-multi.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create VM Linux
resource "azurerm_linux_virtual_machine" "qt-vm-multi" {
  name                = "${var.azurerm_linux_vm_name}-${count.index}"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group
  size                = "Standard_F2"
  admin_username      = "adminuser"
  count               = var.azurerm_vm_count
  network_interface_ids = [
    azurerm_network_interface.qt-nic-multi.*.id[count.index]
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "osdisk-vmlinux-${count.index}"
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

# Create VM WINDOWS
resource "azurerm_windows_virtual_machine" "win-vm" {
  name                = "qt-win"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.qt-nic-multi.2.id
  ]

  os_disk {
    name                 = "osdisk-vmwin"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

# POWERBI
resource "azurerm_powerbi_embedded" "qt-pbi" {
  name                = "qtpowerbi"
  resource_group_name = var.azurerm_resource_group
  location            = var.azurerm_location
  sku_name            = "A1"
  administrators      = ["cloud_user_p_8b7b8933@azurelabs.linuxacademy.com"]
}

# Database
resource "azurerm_mssql_server" "sql-srv" {
  name                         = var.azurerm_mssql_server_name
  resource_group_name          = var.azurerm_resource_group
  location                     = var.azurerm_location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "AdminPassword123!"
}

resource "azurerm_mssql_database" "sql-db" {
  name      = var.azurerm_mssql_database_name
  server_id = azurerm_mssql_server.sql-srv.id
}

resource "azurerm_storage_account" "sql-sa" {
  resource_group_name      = var.azurerm_resource_group
  location                 = var.azurerm_location
  name                     = "sqlqtsa"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_database_extended_auditing_policy" "sql-eap" {
  database_id                             = azurerm_mssql_database.sql-db.id
  storage_endpoint                        = azurerm_storage_account.sql-sa.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.sql-sa.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 6
}
