output "resource_group_foundational" {
  value       = azurerm_resource_group.foundational.name
  description = "Name of the foundational resource group (VMs)"
}

output "resource_group_network" {
  value       = azurerm_resource_group.network.name
  description = "Name of the network resource group (VNet, NSG, NAT)"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Virtual Network name"
}

output "subnet_ids" {
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
  description = "Map of subnet key → subnet ID"
}

output "nat_gateway_id" {
  value       = azurerm_nat_gateway.nat.id
  description = "NAT Gateway resource ID"
}

output "nat_public_ip" {
  value       = azurerm_public_ip.nat.ip_address
  description = "Public IP address assigned to the NAT Gateway"
}

output "virtual_machine_names" {
  value = {
    for k, v in azurerm_windows_virtual_machine.vm : k => v.name
  }
  description = "Map of VM key → VM name"
}

output "virtual_machine_private_ips" {
  value = {
    for k, v in azurerm_network_interface.nic : k => v.private_ip_address
  }
  description = "Map of VM key → private IP"
}
