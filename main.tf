
# 1. RESOURCE GROUPS
#    - Foundational : VMs, disks, NICs
#    - Network      : VNet, Subnets, NSG, NAT GW

resource "azurerm_resource_group" "foundational" {
  name     = var.resource_group_foundational
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "network" {
  name     = var.resource_group_network
  location = var.location
  tags     = var.tags
}

# 2. VIRTUAL NETWORK
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# 3. SUBNETS

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.cidr]
}

# 4. NETWORK SECURITY GROUP

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

# 5. NSG RULES  (driven by local.nsg_rules from var.nsg_ports)
resource "azurerm_network_security_rule" "rules" {
  for_each = local.nsg_rules
  name      = each.key
  priority  = each.value.priority
  direction = "Inbound"
  access    = "Allow"
  protocol  = each.value.protocol

  source_port_range          = "*"
  destination_port_range     = each.value.port
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# 6. PUBLIC IP  (for NAT Gateway)
resource "azurerm_public_ip" "nat" {
  name                = var.nat_public_ip_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# 7. NAT GATEWAY
resource "azurerm_nat_gateway" "nat" {
  name                = var.nat_gateway_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  sku_name            = "Standard"
  tags                = var.tags
}
# 8. NAT GATEWAY ASSOCIATIONS
resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  subnet_id      = azurerm_subnet.subnets[var.nat_subnet_key].id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# 9. NETWORK INTERFACES
resource "azurerm_network_interface" "nic" {
  for_each = var.virtual_machines
  name                          = "${each.value.vm_name}-nic"
  location                      = azurerm_resource_group.foundational.location
  resource_group_name           = azurerm_resource_group.foundational.name
  accelerated_networking_enabled = false  # DS2v2 + AD DC - not required

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[each.value.subnet_key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
  }

  tags = var.tags
}

# 10. NSG → NIC ASSOCIATION
resource "azurerm_network_interface_security_group_association" "nsg" {
  for_each = azurerm_network_interface.nic
  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# 11. WINDOWS VIRTUAL MACHINES
resource "azurerm_windows_virtual_machine" "vm" {
  for_each = var.virtual_machines
  name          = each.value.vm_name
  computer_name = each.value.vm_name
  location            = azurerm_resource_group.foundational.location
  resource_group_name = azurerm_resource_group.foundational.name
  size = each.value.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]
  provision_vm_agent       = true
  automatic_updates_enabled = true
  # USER DATA  (base64-encoded PowerShell / cloud-init)
  # Provide script content via var.user_data_script.
  # If left empty (""), no user_data is attached.
  user_data = var.user_data_script != "" ? base64encode(var.user_data_script) : null

  boot_diagnostics {}
  os_disk {
    name                 = "${each.value.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = each.value.os_disk_size_gb
  }
  source_image_reference {
    publisher = local.windows_image.publisher
    offer     = local.windows_image.offer
    sku       = local.windows_image.sku
    version   = local.windows_image.version
  }

  tags = var.tags
}

# 12. MANAGED DATA DISKS
resource "azurerm_managed_disk" "disk" {
  for_each = var.virtual_machines
  name                 = "${each.value.vm_name}-datadisk"
  location             = azurerm_resource_group.foundational.location
  resource_group_name  = azurerm_resource_group.foundational.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk_size_gb
  tags                 = var.tags
}

# 13. DATA DISK ATTACHMENTS
resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each = var.virtual_machines

  managed_disk_id    = azurerm_managed_disk.disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}
