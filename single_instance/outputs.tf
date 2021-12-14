output "azurerm_virtual_network_name" {
  value = azurerm_virtual_network.qt-vnet-single.name
}

output "azurerm_subnet_name" {
  value = azurerm_subnet.qt-subnet-single.name
}

output "azurerm_vm_name" {
  value = azurerm_linux_virtual_machine.qt-vm-single.name
}

output "azurerm_privateip" {
  value = azurerm_network_interface.qt-nic-single.private_ip_address
}
