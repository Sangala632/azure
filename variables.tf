# REGION / LOCATION
variable "location" {
  type        = string
  description = "Azure region for all resources (e.g. southeastasia)"
}

# RESOURCE GROUPS
variable "resource_group_foundational" {
  type        = string
  description = "Resource group for VMs and foundational compute resources"
}

variable "resource_group_network" {
  type        = string
  description = "Resource group for networking resources (VNet, NSG, NAT GW)"
}

# VIRTUAL NETWORK
variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VNet (e.g. [\"10.1.0.0/24\"])"
}

# SUBNETS
variable "subnets" {
  type = map(object({
    name = string
    cidr = string
  }))
  description = "Map of subnets. Key is used internally (e.g. app, dat, pub, nat)"
}

# NSG
variable "nsg_name" {
  type        = string
  description = "Name of the Network Security Group"
}

variable "nsg_ports" {
  type = list(object({
    name     = string
    port     = string
    protocol = string
  }))
  description = "List of NSG inbound rules. Each entry has a name, port (or range), and protocol (Tcp / Udp / *)."
}

# NAT GATEWAY
variable "nat_gateway_name" {
  type        = string
  description = "Name of the NAT Gateway"
}

variable "nat_public_ip_name" {
  type        = string
  description = "Name of the Public IP attached to the NAT Gateway"
}

variable "nat_subnet_key" {
  type        = string
  description = "Key from var.subnets to associate with the NAT Gateway (e.g. \"nat\")"
}

# VIRTUAL MACHINES
variable "admin_username" {
  type        = string
  description = "Local administrator username for Windows VMs"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Local administrator password for Windows VMs"
}

variable "virtual_machines" {
  type = map(object({
    vm_name           = string
    vm_size           = string
    private_ip        = string
    subnet_key        = string
    os_disk_size_gb   = number
    data_disk_size_gb = number
  }))
  description = "Map of Windows VMs to create. Key is an internal identifier."
}

# OS IMAGE  (parameterized so it can be overridden if needed)
variable "image_publisher" {
  type        = string
  description = "VM image publisher"
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  type        = string
  description = "VM image offer"
  default     = "WindowsServer"
}

variable "image_sku" {
  type        = string
  description = "VM image SKU"
  default     = "2019-Datacenter"
}

variable "image_version" {
  type        = string
  description = "VM image version"
  default     = "latest"
}

# TAGS
variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}

# USER DATA / CUSTOM SCRIPT
variable "user_data_script" {
  type        = string
  description = "PowerShell script content to run on VMs. Passed as user_data and also executed via CustomScriptExtension. Leave empty to skip."
  default     = ""
}

