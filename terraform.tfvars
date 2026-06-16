
# REGION
location = "southeastasia"

# RESOURCE GROUPS
resource_group_foundational = "rg-source-sa-DFI-foundational"
resource_group_network      = "rg-source-sa-DFI-network"

# VIRTUAL NETWORK
vnet_name          = "sa-DFI-source-vnet"
vnet_address_space = ["10.1.0.0/20"]    # Change to your confirmed CIDR
# SUBNETS
# Update CIDRs below with your confirmed values
subnets = {
  app = {
    name = "sa-DFI-source-sub-app"
    cidr = "10.1.0.0/26"     # <-- provide your CIDR
  }
  dat = {
    name = "sa-DFI-source-sub-dat"
    cidr = "10.1.4.0/26"     # <-- provide your CIDR
  }
  pub = {
    name = "sa-DFI-source-sub-pub"
    cidr = "10.1.8.0/26"     # <-- provide your CIDR
  }
  nat = {
    name = "sa-DFI-source-sub-nat"
    cidr = "10.1.12.0/26"    # <-- provide your CIDR
  }
}

# NSG
nsg_name = "sa-DFI-source-nsg"
nsg_ports = [
  { name = "wins-replication", port = "42",          protocol = "Tcp"  },
  { name = "dns",              port = "53",           protocol = "*"    },
  { name = "http",             port = "80",           protocol = "Tcp"  },
  { name = "kerberos",         port = "88",           protocol = "*"    },
  { name = "ntp",              port = "123",          protocol = "Udp"  },
  { name = "rpc-epmap",        port = "135",          protocol = "Tcp"  },
  { name = "netbios-ns",       port = "137",          protocol = "Udp"  },
  { name = "netbios-dgm",      port = "138",          protocol = "Udp"  },
  { name = "netbios-ss",       port = "139",          protocol = "Tcp"  },
  { name = "ldap",             port = "389",          protocol = "*"    },
  { name = "https",            port = "443",          protocol = "Tcp"  },
  { name = "smb",              port = "445",          protocol = "Tcp"  },
  { name = "kerberos-pwd",     port = "464",          protocol = "*"    },
  { name = "ldaps",            port = "636",          protocol = "Tcp"  },
  { name = "wins",             port = "1512",         protocol = "Tcp"  },
  { name = "winrm",            port = "5985",         protocol = "Tcp"  },
  { name = "custom-8082",      port = "8082",         protocol = "Tcp"  },
  { name = "adws",             port = "9389",         protocol = "Tcp"  },
  { name = "rpc-dynamic",      port = "1024-5000",    protocol = "Tcp"  },
  { name = "ephemeral-tcp",    port = "49152-65535",  protocol = "Tcp"  },
  { name = "ephemeral-udp",    port = "49152-65535",  protocol = "Udp"  },
]

# NAT GATEWAY
nat_gateway_name   = "sa-DFI-source-nat-gw"
nat_public_ip_name = "sa-DFI-source-nat-pip"
nat_subnet_key     = "nat"
# VIRTUAL MACHINES
# os_disk_size_gb  = 14 (OS disk per spec)
# data_disk_size_gb = 8 (additional disk per spec)
# vm_size          = Standard_DS2_v2 (DS2 v2 per spec)
admin_username = "dfi-admin"
admin_password = "CHANGE_ME_Before_Apply!"   # Use Azure Key Vault or env var in production

virtual_machines = {
  root_ad = {
    vm_name           = "dev-dfi-root-ad"
    vm_size           = "Standard_DS2_v2"
    private_ip        = "10.1.0.10"    # <-- provide your IP from subnet range
    subnet_key        = "app"
    os_disk_size_gb   = 14
    data_disk_size_gb = 8
  }
  domain_ad_1 = {
    vm_name           = "dev-dfi-ad-domain-1"
    vm_size           = "Standard_DS2_v2"
    private_ip        = "10.1.0.11"    # <-- provide your IP from subnet range
    subnet_key        = "app"
    os_disk_size_gb   = 14
    data_disk_size_gb = 8
  }
}

# TAGS
tags = {
  environment = "Dev"
  project     = "DFI-Source-Domain"
  owner       = "DFI-Team"
  managed_by  = "Terraform"
}

# USER DATA SCRIPT
# Paste your PowerShell script content here, or use:
#   user_data_script = file("scripts/your-script.ps1")
# Leave as "" to skip user_data and extension entirely.
user_data_script = file("scripts/startup.ps1")