# Linux VM Terraform Module

Ubuntu 24.04 LTS VM with Azure AD login and JIT access support.

## Features
- ✅ **Ubuntu 24.04 LTS** (latest)
- ✅ **Azure AD Login** for authentication
- ✅ **JIT Access** compatible
- ✅ **SSH Key Authentication** (no passwords)
- ✅ **System-Assigned Managed Identity**
- ✅ **Azure Monitor Agent** for monitoring
- ✅ **Dependency Agent** for service maps
- ✅ **Boot Diagnostics** enabled

## Usage
\`\`\`hcl
module "jumpbox_vm" {
  source = "../../modules/compute/linux-vm"

  vm_name             = "vm-jumpbox-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = "rg-spoke-canadacentral-prod"
  subnet_id           = module.spoke_vnet.jumpbox_subnet_id
  
  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
  
  nic_name    = "nic-jumpbox-canadacentral-prod"
  os_disk_name = "osdisk-jumpbox-canadacentral-prod"
  
  vm_size    = "Standard_B2s"
  vm_purpose = "Jumpbox"
  
  enable_azure_ad_login = true
  enable_monitoring     = true
  
  tags = {
    Environment = "Production"
    Purpose     = "AKS Access"
  }
}
\`\`\`

## Requirements
- Terraform >= 1.10.3
- azurerm ~> 4.51.0

## VM Sizes
- **Standard_B2s**: 2 vCPU, 4 GB RAM (~$37/month) - Recommended for jumpbox
- **Standard_D2s_v5**: 2 vCPU, 8 GB RAM (~$96/month) - For agent VMs
- **Standard_F4s_v2**: 4 vCPU, 8 GB RAM (~$176/month) - For DevOps agents

v1.0.0 (November 2025)
