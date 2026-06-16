---

**Document Title**   : Infrastructure as Code — DFI Source Domain (Azure POC)
**Project**          : DFI Active Directory Domain Migration — Source Environment
**Environment**      : Development (POC)
**Cloud Provider**   : Microsoft Azure — Southeast Asia
**IaC Tool**         : Terraform >= 1.5.0 / AzureRM Provider ~> 4.0
**Prepared By**      : DevOps Team — Venturesoft.ai
**Last Updated**     : June 2026
**Status**           : Draft

---

# Infrastructure as Code — DFI Source Domain (Azure POC)

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Repository Structure](#3-repository-structure)
4. [Infrastructure Components](#4-infrastructure-components)
5. [Network Design](#5-network-design)
6. [Virtual Machine Specifications](#6-virtual-machine-specifications)
7. [Security Configuration](#7-security-configuration)
8. [Prerequisites](#8-prerequisites)
9. [Deployment Guide](#9-deployment-guide)
10. [Configuration Reference](#10-configuration-reference)
11. [Input Variables](#11-input-variables)
12. [Outputs](#12-outputs)
13. [Post-Deployment Scripting](#13-post-deployment-scripting)
14. [Operational Procedures](#14-operational-procedures)
15. [Security Guidelines](#15-security-guidelines)
16. [Troubleshooting](#16-troubleshooting)

---

## 1. Project Overview

This repository contains Terraform infrastructure code for provisioning the **DFI Source Domain** proof-of-concept (POC) environment on Microsoft Azure. The infrastructure establishes a Windows Active Directory domain topology comprising a Forest Root domain controller and a child domain controller, deployed in the Azure Southeast Asia region.

The environment is designed to support Active Directory domain migration testing between source and destination domains across Azure-hosted Windows Server 2019 infrastructure.

| Attribute | Value |
|---|---|
| Project Code | DFI-Source-Domain-POC |
| Environment | Development |
| Hosting Region | Southeast Asia (southeastasia) |
| Hosting Provider | Microsoft Azure |
| Domain Names | poc.dfi.com / poc.dfi.ph |
| Estimated Monthly Cost | USD $366.20 (2 × $183.10) |

---

## 2. Architecture Overview

```
Microsoft Azure — Southeast Asia Region
│
├── Resource Group: rg-source-sa-DFI-network
│   │   (All networking and security resources)
│   │
│   ├── Virtual Network: sa-DFI-source-vnet  [10.1.0.0/20]
│   │   ├── Subnet: sa-DFI-source-sub-app    [10.1.0.0/26]   ← Application tier
│   │   ├── Subnet: sa-DFI-source-sub-dat    [10.1.4.0/26]   ← Data tier
│   │   ├── Subnet: sa-DFI-source-sub-pub    [10.1.8.0/26]   ← Public / DMZ tier
│   │   └── Subnet: sa-DFI-source-sub-nat    [10.1.12.0/26]  ← NAT egress tier
│   │
│   ├── NSG: sa-DFI-source-nsg               (21 AD inbound rules)
│   ├── NAT Gateway: sa-DFI-source-nat-gw    (Standard SKU)
│   └── Public IP: sa-DFI-source-nat-pip     (Static, Standard SKU)
│
└── Resource Group: rg-source-sa-DFI-foundational
        (All compute, disk, and NIC resources)
    │
    ├── VM: dev-dfi-root-ad                  [Standard_DS2_v2]
    │   ├── Purpose : Forest Root Domain Controller
    │   ├── Domain  : poc.dfi.com
    │   ├── NIC     : dev-dfi-root-ad-nic → sa-DFI-source-sub-app (Static IP)
    │   ├── OS Disk : dev-dfi-root-ad-osdisk     (14 GB  Premium SSD)
    │   └── Data Disk: dev-dfi-root-ad-datadisk  ( 8 GB  Premium SSD, LUN 0)
    │
    └── VM: dev-dfi-ad-domain-1              [Standard_DS2_v2]
        ├── Purpose : Child Domain Controller
        ├── Domain  : poc.dfi.ph
        ├── NIC     : dev-dfi-ad-domain-1-nic → sa-DFI-source-sub-app (Static IP)
        ├── OS Disk : dev-dfi-ad-domain-1-osdisk     (14 GB  Premium SSD)
        └── Data Disk: dev-dfi-ad-domain-1-datadisk  ( 8 GB  Premium SSD, LUN 0)
```

---

## 3. Repository Structure

```
azure-dfi/
│
├── provider.tf          # Terraform and AzureRM provider version constraints
├── variables.tf         # All input variable declarations with types and descriptions
├── locals.tf            # Computed locals: OS image reference and NSG rule map
├── main.tf              # All 14 Azure resource definitions
├── outputs.tf           # Post-deployment output values
├── terraform.tfvars     # Environment-specific values (update before applying)
│
└── scripts/
    └── startup.ps1      # PowerShell startup script template (disk init, WinRM, AD DS)
```

| File | Purpose |
|---|---|
| `provider.tf` | Declares AzureRM provider `~> 4.0` and Terraform version `>= 1.5.0` |
| `variables.tf` | Declares all input variables. No values are hardcoded in resource files |
| `locals.tf` | Builds `windows_image` reference and dynamically generates `nsg_rules` map from `var.nsg_ports` |
| `main.tf` | Defines all 14 resources in dependency order: RGs → VNet → Subnets → NSG → NAT → NICs → VMs → Disks → Extension |
| `outputs.tf` | Exports resource names, IDs, and IPs after deployment |
| `terraform.tfvars` | Contains all runtime values. This is the only file that needs to be updated per environment |
| `scripts/startup.ps1` | Template PowerShell script executed on VMs at first boot and via Azure VM Agent |

---

## 4. Infrastructure Components

The following Azure resources are provisioned by this codebase:

| # | Resource Type | Resource Name | Resource Group |
|---|---|---|---|
| 1 | Resource Group | rg-source-sa-DFI-foundational | — |
| 2 | Resource Group | rg-source-sa-DFI-network | — |
| 3 | Virtual Network | sa-DFI-source-vnet | rg-source-sa-DFI-network |
| 4 | Subnet (×4) | sub-app / sub-dat / sub-pub / sub-nat | rg-source-sa-DFI-network |
| 5 | Network Security Group | sa-DFI-source-nsg | rg-source-sa-DFI-network |
| 6 | NSG Inbound Rules (×21) | allow-dns, allow-kerberos, ... | rg-source-sa-DFI-network |
| 7 | Public IP Address | sa-DFI-source-nat-pip | rg-source-sa-DFI-network |
| 8 | NAT Gateway | sa-DFI-source-nat-gw | rg-source-sa-DFI-network |
| 9 | NAT Gateway — Public IP Association | — | rg-source-sa-DFI-network |
| 10 | NAT Gateway — Subnet Association | — | rg-source-sa-DFI-network |
| 11 | Network Interface (×2) | dev-dfi-root-ad-nic / dev-dfi-ad-domain-1-nic | rg-source-sa-DFI-foundational |
| 12 | NSG → NIC Association (×2) | — | rg-source-sa-DFI-foundational |
| 13 | Windows Virtual Machine (×2) | dev-dfi-root-ad / dev-dfi-ad-domain-1 | rg-source-sa-DFI-foundational |
| 14 | Managed Disk (×2) | dev-dfi-root-ad-datadisk / dev-dfi-ad-domain-1-datadisk | rg-source-sa-DFI-foundational |
| 15 | Data Disk Attachment (×2) | LUN 0 | rg-source-sa-DFI-foundational |
| 16 | Custom Script Extension (×2) | dev-dfi-root-ad-custom-script / dev-dfi-ad-domain-1-custom-script | rg-source-sa-DFI-foundational |

> Note: Custom Script Extension resources (item 16) are only created when `user_data_script` is set to a non-empty value in `terraform.tfvars`.

---

## 5. Network Design

### 5.1 Virtual Network

| Property | Value |
|---|---|
| VNet Name | sa-DFI-source-vnet |
| Address Space | 10.1.0.0/20 |
| Region | Southeast Asia |
| Resource Group | rg-source-sa-DFI-network |

### 5.2 Subnets

| Subnet Key | Subnet Name | CIDR | Purpose |
|---|---|---|---|
| `app` | sa-DFI-source-sub-app | 10.1.0.0/26 | Application / Domain Controller tier |
| `dat` | sa-DFI-source-sub-dat | 10.1.4.0/26 | Data tier |
| `pub` | sa-DFI-source-sub-pub | 10.1.8.0/26 | Public / DMZ tier |
| `nat` | sa-DFI-source-sub-nat | 10.1.12.0/26 | NAT Gateway egress subnet |

> The VNet address space has been set to `/20` to accommodate all four subnet CIDRs. Confirm final CIDRs with the network team before deployment.

### 5.3 NAT Gateway

All outbound internet traffic from private subnets is routed through the NAT Gateway attached to `sa-DFI-source-sub-nat`. The NAT Gateway uses a static Standard Public IP address, ensuring a fixed egress IP for firewall allowlisting on destination systems.

---

## 6. Virtual Machine Specifications

Both virtual machines are identically sized as per the infrastructure specification.

| Property | Value |
|---|---|
| Azure SKU | Standard_DS2_v2 |
| vCPU | 2 Cores |
| RAM | 7 GB |
| Operating System | Windows Server 2019 Datacenter |
| OS Disk Size | 14 GB |
| OS Disk Type | Premium SSD (Premium_LRS) |
| Data Disk Size | 8 GB |
| Data Disk Type | Premium SSD (Premium_LRS) |
| Data Disk LUN | 0 |
| High Availability | Not applicable (POC/Dev) |
| Automatic Updates | Enabled |
| VM Agent | Enabled |
| Boot Diagnostics | Enabled |
| Accelerated Networking | Disabled (not required for AD DC workloads on DS2v2) |
| Private IP Allocation | Static |

### 6.1 Domain Controller Mapping

| VM Name | Role | Domain | Subnet |
|---|---|---|---|
| dev-dfi-root-ad | Forest Root Domain Controller | poc.dfi.com | sa-DFI-source-sub-app |
| dev-dfi-ad-domain-1 | Child Domain Controller | poc.dfi.ph | sa-DFI-source-sub-app |

---

## 7. Security Configuration

### 7.1 NSG Inbound Rules

The Network Security Group `sa-DFI-source-nsg` is attached to the NIC of each virtual machine. Rules are dynamically generated from the `nsg_ports` variable and assigned priorities starting at 100 in increments of 10.

| Priority | Rule Name | Port | Protocol | Purpose |
|---|---|---|---|---|
| 100 | allow-wins-replication | 42 | TCP | WINS Replication |
| 110 | allow-dns | 53 | TCP/UDP | DNS Resolution |
| 120 | allow-http | 80 | TCP | HTTP |
| 130 | allow-kerberos | 88 | TCP/UDP | Kerberos Authentication |
| 140 | allow-ntp | 123 | UDP | Network Time Protocol |
| 150 | allow-rpc-epmap | 135 | TCP | RPC Endpoint Mapper |
| 160 | allow-netbios-ns | 137 | UDP | NetBIOS Name Service |
| 170 | allow-netbios-dgm | 138 | UDP | NetBIOS Datagram Service |
| 180 | allow-netbios-ss | 139 | TCP | NetBIOS Session Service |
| 190 | allow-ldap | 389 | TCP/UDP | LDAP |
| 200 | allow-https | 443 | TCP | HTTPS |
| 210 | allow-smb | 445 | TCP | SMB File Sharing |
| 220 | allow-kerberos-pwd | 464 | TCP/UDP | Kerberos Password Change |
| 230 | allow-ldaps | 636 | TCP | LDAP over SSL |
| 240 | allow-wins | 1512 | TCP | WINS |
| 250 | allow-winrm | 5985 | TCP | WinRM (HTTP) |
| 260 | allow-custom-8082 | 8082 | TCP | Custom Application Port |
| 270 | allow-adws | 9389 | TCP | Active Directory Web Services |
| 280 | allow-rpc-dynamic | 1024–5000 | TCP | RPC Dynamic Port Range |
| 290 | allow-ephemeral-tcp | 49152–65535 | TCP | Ephemeral Port Range (TCP) |
| 300 | allow-ephemeral-udp | 49152–65535 | UDP | Ephemeral Port Range (UDP) |

---

## 8. Prerequisites

The following tools must be installed and configured on the workstation prior to deployment.

| Tool | Minimum Version | Reference |
|---|---|---|
| Terraform | >= 1.5.0 | https://developer.hashicorp.com/terraform/install |
| Azure CLI | Latest | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |
| AzureRM Provider | ~> 4.0 | Managed automatically by `terraform init` |

### 8.1 Azure Authentication

Authenticate to Azure and set the target subscription before running any Terraform commands:

```bash
# Step 1: Login to Azure
az login

# Step 2: List available subscriptions
az account list --output table

# Step 3: Set the target subscription
az account set --subscription "<subscription-id>"

# Step 4: Verify active subscription
az account show
```

---

## 9. Deployment Guide

### 9.1 Pre-Deployment Checklist

Before executing any Terraform commands, ensure the following items are completed:

- [ ] Azure CLI is authenticated to the correct subscription
- [ ] Subnet CIDRs have been confirmed with the network team and updated in `terraform.tfvars`
- [ ] Static private IP addresses have been allocated and updated in `terraform.tfvars`
- [ ] `admin_password` has been set securely (environment variable or Key Vault — not in `terraform.tfvars`)
- [ ] `user_data_script` has been reviewed and updated if post-boot configuration is required
- [ ] Resource naming has been reviewed and aligns with the organisation's naming convention

### 9.2 Deployment Steps

```bash
# Step 1: Navigate to the project directory
cd azure

# Step 2: Initialise Terraform (downloads provider plugins)
terraform init

# Step 3: Validate configuration syntax
terraform validate

# Step 4: Review planned changes before applying
terraform plan -out=tfplan

# Step 5: Apply the plan
terraform apply tfplan
```

### 9.3 Expected Deployment Time

| Phase | Estimated Duration |
|---|---|
| Resource Groups | < 1 minute |
| Networking (VNet, Subnets, NSG, NAT) | 2–4 minutes |
| Virtual Machines | 5–8 minutes each |
| Disk Attachments | 1–2 minutes |
| Custom Script Extension | 3–10 minutes (depends on script) |
| **Total** | **~20–30 minutes** |

---

## 10. Configuration Reference

All deployment values are controlled through `terraform.tfvars`. The following sections describe the key configuration blocks.

### 10.1 Subnet CIDRs

Update with values confirmed by the network team:

```hcl
subnets = {
  app = { name = "sa-DFI-source-sub-app", cidr = "10.1.0.0/26"  }
  dat = { name = "sa-DFI-source-sub-dat", cidr = "10.1.4.0/26"  }
  pub = { name = "sa-DFI-source-sub-pub", cidr = "10.1.8.0/26"  }
  nat = { name = "sa-DFI-source-sub-nat", cidr = "10.1.12.0/26" }
}
```

### 10.2 Virtual Machine Private IPs

Assign static IPs from within the confirmed application subnet range:

```hcl
virtual_machines = {
  root_ad = {
    vm_name           = "dev-dfi-root-ad"
    vm_size           = "Standard_DS2_v2"
    private_ip        = "10.1.0.10"       # Update with allocated IP
    subnet_key        = "app"
    os_disk_size_gb   = 14
    data_disk_size_gb = 8
  }
  domain_ad_1 = {
    vm_name           = "dev-dfi-ad-domain-1"
    vm_size           = "Standard_DS2_v2"
    private_ip        = "10.1.0.11"       # Update with allocated IP
    subnet_key        = "app"
    os_disk_size_gb   = 14
    data_disk_size_gb = 8
  }
}
```

### 10.3 Adding Additional VMs

To add a new domain controller or member server, append a new entry to the `virtual_machines` map in `terraform.tfvars`. No changes to `main.tf` are required — the `for_each` construct handles all new entries automatically.

```hcl
virtual_machines = {
  root_ad     = { ... }
  domain_ad_1 = { ... }
  domain_ad_2 = {
    vm_name           = "dev-dfi-ad-domain-2"
    vm_size           = "Standard_DS2_v2"
    private_ip        = "10.1.0.12"
    subnet_key        = "app"
    os_disk_size_gb   = 14
    data_disk_size_gb = 8
  }
}
```

### 10.4 Overriding the OS Image

The default image is Windows Server 2019 Datacenter. To deploy a different version, override the relevant image variable in `terraform.tfvars`:

```hcl
image_sku = "2022-Datacenter"
```

---

## 11. Input Variables

| Variable | Type | Required | Default | Description |
|---|---|---|---|---|
| `location` | string | Yes | — | Azure region (e.g. `southeastasia`) |
| `resource_group_foundational` | string | Yes | — | Name of the compute resource group |
| `resource_group_network` | string | Yes | — | Name of the network resource group |
| `vnet_name` | string | Yes | — | Virtual Network name |
| `vnet_address_space` | list(string) | Yes | — | VNet address space (e.g. `["10.1.0.0/20"]`) |
| `subnets` | map(object) | Yes | — | Map of subnet name and CIDR per tier |
| `nsg_name` | string | Yes | — | Network Security Group name |
| `nsg_ports` | list(object) | Yes | — | List of inbound NSG rules (name, port, protocol) |
| `nat_gateway_name` | string | Yes | — | NAT Gateway resource name |
| `nat_public_ip_name` | string | Yes | — | Public IP resource name for NAT Gateway |
| `nat_subnet_key` | string | Yes | — | Subnet key to associate with NAT Gateway |
| `admin_username` | string | Yes | — | Local administrator username for all VMs |
| `admin_password` | string | Yes | — | Local administrator password (sensitive) |
| `virtual_machines` | map(object) | Yes | — | Map of VM definitions (name, size, IP, disks) |
| `image_publisher` | string | No | `MicrosoftWindowsServer` | VM image publisher |
| `image_offer` | string | No | `WindowsServer` | VM image offer |
| `image_sku` | string | No | `2019-Datacenter` | VM image SKU |
| `image_version` | string | No | `latest` | VM image version |
| `user_data_script` | string | No | `""` | PowerShell script content for post-boot execution |
| `tags` | map(string) | No | `{}` | Tags applied to all resources |

---

## 12. Outputs

The following values are exported after a successful `terraform apply`:

| Output Name | Description |
|---|---|
| `resource_group_foundational` | Name of the compute resource group |
| `resource_group_network` | Name of the network resource group |
| `vnet_name` | Name of the deployed Virtual Network |
| `subnet_ids` | Map of subnet key → Azure resource ID |
| `nat_gateway_id` | Resource ID of the NAT Gateway |
| `nat_public_ip` | Assigned public IP address of the NAT Gateway |
| `virtual_machine_names` | Map of VM key → deployed VM name |
| `virtual_machine_private_ips` | Map of VM key → assigned private IP address |

To retrieve outputs after deployment:

```bash
terraform output

# Retrieve a specific output
terraform output nat_public_ip
terraform output virtual_machine_private_ips
```

---

## 13. Post-Deployment Scripting

### 13.1 Overview

This infrastructure supports two complementary script execution mechanisms:

| Mechanism | Trigger | Use Case |
|---|---|---|
| `user_data` | First boot (before agent) | Early OS configuration, timezone, disk formatting |
| `CustomScriptExtension` | Post-deployment via Azure VM Agent | AD DS installation, domain promotion, application setup |

Both mechanisms use the same script defined in `var.user_data_script`, providing dual execution paths for reliability.

### 13.2 Providing the Script

**Option A — Reference from file (recommended):**

```hcl
# In terraform.tfvars
user_data_script = file("scripts/startup.ps1")
```

**Option B — Inline content:**

```hcl
user_data_script = <<-EOT
  Set-TimeZone -Id "Singapore Standard Time"
  Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
EOT
```

**Option C — Skip scripting entirely:**

```hcl
user_data_script = ""
```

### 13.3 Sample Script

A template script is provided at `scripts/startup.ps1` covering:

- Data disk initialisation and formatting (LUN 0)
- Timezone configuration (Singapore Standard Time)
- WinRM enablement (port 5985)
- AD DS role installation (commented — uncomment when required)

---

## 14. Operational Procedures

### 14.1 Viewing Current State

```bash
# List all managed resources
terraform state list

# Show details of a specific resource
terraform state show azurerm_windows_virtual_machine.vm[\"root_ad\"]
```

### 14.2 Refreshing State

```bash
terraform refresh
```

### 14.3 Targeting a Specific Resource

```bash
# Plan for a single resource
terraform plan -target=azurerm_windows_virtual_machine.vm

# Apply a single resource
terraform apply -target=azurerm_windows_virtual_machine.vm
```

### 14.4 Destroying the Environment

```bash
terraform destroy
```

> **Warning:** This command permanently deletes all provisioned resources, including virtual machines and managed disks. Ensure all data has been backed up and the action has been approved before proceeding.

---

## 15. Security Guidelines

The following security practices must be observed when working with this codebase:

**Credential Management**

The `admin_password` variable is marked `sensitive = true` and will not appear in Terraform plan output or state display. However, it is still stored in the Terraform state file. Observe the following:

```bash
# Recommended: pass password via environment variable — never store in terraform.tfvars
export TF_VAR_admin_password="YourStrongPassword123!"

# Alternative: pass at apply time
terraform apply -var="admin_password=YourStrongPassword123!"
```

For production environments, retrieve the password from Azure Key Vault using a `data` source block.

**Source Control**

- Never commit `terraform.tfvars` containing real passwords or sensitive values to version control
- Add `terraform.tfvars` and `*.tfstate` to `.gitignore`
- Store Terraform state remotely (Azure Blob Storage with state locking via Azure Storage) for team environments

**Terraform State Backend (recommended for team use)**

```hcl
# Add to provider.tf for remote state
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatedfi"
    container_name       = "tfstate"
    key                  = "dfi-source.terraform.tfstate"
  }
}
```

---

## 16. Troubleshooting

| Issue | Likely Cause | Resolution |
|---|---|---|
| `azurerm_subnet` address not within VNet range | Subnet CIDR outside VNet `/20` range | Verify subnet CIDRs are within `10.1.0.0/20` |
| `local.nsg_rules` not found | `nsg_ports` is empty | Ensure `nsg_ports` has at least one entry in `terraform.tfvars` |
| `enable_accelerated_networking` red in editor | Deprecated argument in AzureRM 4.x | Use `accelerated_networking_enabled` (already updated in this codebase) |
| `enable_automatic_updates` red in editor | Deprecated in AzureRM 4.x | Use `automatic_updates_enabled` |
| Custom Script Extension timeout | Script taking too long or failing silently | Check extension logs at `C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension` |
| VM unreachable via WinRM | NSG or Windows Firewall blocking port 5985 | Confirm NSG rule `allow-winrm` exists and `Enable-PSRemoting` ran in startup script |
| `for_each` error on VM map | Duplicate VM names in `virtual_machines` map | Ensure all map keys and `vm_name` values are unique |

---

*This document is maintained by the DevOps team at Venturesoft.ai. For queries or change requests, raise a JIRA ticket under the DFI project.*