locals {
  # Windows Server 2019 image reference
  windows_image = {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  # NSG Rules - built from var.nsg_ports
  # Each entry in var.nsg_ports becomes one rule.
  # Priority is auto-assigned starting at 100 (step 10).
  nsg_rules = {
    for idx, port_obj in var.nsg_ports :
    "allow-${port_obj.name}" => {
      priority = 100 + idx * 10
      port     = port_obj.port
      protocol = port_obj.protocol
    }
  }
}
