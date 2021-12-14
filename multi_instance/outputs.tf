output "azurerm_virtual_network_name" {
  value = azurerm_virtual_network.qt-vnet-multi.name
}

output "azurerm_subnet_name" {
  value = azurerm_subnet.qt-subnet-multi.name
}

output "azurerm_vm_name" {
  value     = azurerm_linux_virtual_machine.qt-vm-multi[*]
  sensitive = true
}

output "azurerm_privateip" {
  value = azurerm_network_interface.qt-nic-multi[*].private_ip_address
}
