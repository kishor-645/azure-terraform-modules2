# Azure Firewall Premium Terraform Module

This module deploys Azure Firewall Premium with comprehensive security policies, IDPS, threat intelligence, and dynamic Cloudflare IP integration.

## Features

- ✅ **Azure Firewall Premium** with zone redundancy (3 zones)
- ✅ **Forced Tunneling** support with management subnet
- ✅ **IDPS** (Intrusion Detection and Prevention System)
- ✅ **Threat Intelligence** with customizable allowlists
- ✅ **Dynamic Cloudflare IPs** fetched from official API
- ✅ **DNAT Rules** for inbound traffic from Cloudflare to internal LB
- ✅ **Network Rules** for Azure services, AKS, NTP, DNS
- ✅ **Application Rules** for FQDN filtering
- ✅ **TLS Inspection** support (Premium feature)
- ✅ **Log Analytics** integration for diagnostics
- ✅ **DNS Proxy** for centralized DNS resolution

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Internet                               │
└────────────────────┬────────────────────────────────────┘
                     │
              ┌──────▼──────┐
              │ Cloudflare  │
              │  (CDN/WAF)  │
              └──────┬──────┘
                     │ Cloudflare IPs Only
                     │
         ┌───────────▼────────────┐
         │  Firewall Public IP    │
         │  (DNAT Rule)           │
         └───────────┬────────────┘
                     │
         ┌───────────▼────────────┐
         │  Azure Firewall        │
         │  Premium               │
         │  - IDPS: Alert/Deny    │
         │  - Threat Intel        │
         │  - Private IP: .4      │
         └───────────┬────────────┘
                     │
         ┌───────────▼────────────┐
         │  Internal Load Balancer│
         │  (Istio Ingress)       │
         │  Private IP: 10.1.16.4 │
         └───────────┬────────────┘
                     │
              ┌──────▼──────┐
              │  AKS Pods   │
              └─────────────┘
```

## Usage

### Basic Example (Stage 1 - Without Internal LB)

```hcl
module "azure_firewall" {
  source = "../../modules/security/azure-firewall"

  firewall_name           = "azfw-canadacentral-prod"
  location                = "canadacentral"
  resource_group_name     = "rg-hub-canadacentral-prod"
  firewall_policy_name    = "azfwpol-canadacentral-prod"

  # Public IPs
  firewall_public_ip_name    = "pip-azfw-canadacentral-prod"
  firewall_management_ip_name = "pip-azfw-mgmt-canadacentral-prod"

  # Subnets
  firewall_subnet_id            = module.hub_vnet.firewall_subnet_id
  firewall_management_subnet_id = module.hub_vnet.firewall_management_subnet_id

  # Availability Zones
  availability_zones = ["1", "2", "3"]

  # DNAT - Internal LB IP empty initially (Stage 1)
  internal_lb_ip                    = ""  # Will update in Stage 2
  fetch_cloudflare_ips_dynamically  = true

  # Security Settings
  threat_intelligence_mode = "Alert"
  idps_mode               = "Alert"

  # VNet CIDRs for network rules
  hub_vnet_cidr   = "10.0.0.0/16"
  spoke_vnet_cidr = "10.1.0.0/16"

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.regional.id

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Stage 2 - With Internal LB IP

```hcl
module "azure_firewall" {
  source = "../../modules/security/azure-firewall"

  # ... same config as Stage 1 ...

  # DNAT - Internal LB IP discovered from AKS/Istio
  internal_lb_ip = "10.1.16.4"  # Istio internal LB private IP

  # ... rest of config ...
}
```

### Advanced Configuration

```hcl
module "azure_firewall" {
  source = "../../modules/security/azure-firewall"

  firewall_name           = "azfw-canadacentral-prod"
  location                = "canadacentral"
  resource_group_name     = "rg-hub-canadacentral-prod"
  firewall_policy_name    = "azfwpol-canadacentral-prod"

  firewall_public_ip_name     = "pip-azfw-canadacentral-prod"
  firewall_management_ip_name = "pip-azfw-mgmt-canadacentral-prod"

  firewall_subnet_id            = module.hub_vnet.firewall_subnet_id
  firewall_management_subnet_id = module.hub_vnet.firewall_management_subnet_id

  availability_zones = ["1", "2", "3"]

  # DNAT Configuration
  internal_lb_ip                   = "10.1.16.4"
  fetch_cloudflare_ips_dynamically = true
  enable_ipv6                      = false

  # Security Configuration
  threat_intelligence_mode = "Deny"  # Block malicious IPs automatically
  idps_mode               = "Deny"   # Block malicious traffic patterns

  # Custom DNS servers (optional)
  custom_dns_servers = [
    "8.8.8.8",   # Google DNS
    "8.8.4.4"
  ]

  # Threat Intelligence Allowlist
  threat_intel_allowlist_ips = [
    "203.0.113.0/24"  # Trusted partner network
  ]

  threat_intel_allowlist_fqdns = [
    "trusted-partner.com"
  ]

  # IDPS Signature Overrides (disable specific signatures)
  idps_signature_overrides = [
    {
      id    = "2024897"
      state = "Off"  # Disable false positive signature
    }
  ]

  # VNet CIDRs
  hub_vnet_cidr   = "10.0.0.0/16"
  spoke_vnet_cidr = "10.1.0.0/16"

  # Custom Allowed FQDNs
  custom_allowed_fqdns = [
    "api.example.com",
    "*.example.com"
  ]

  # TLS Inspection (requires certificate in Key Vault)
  enable_tls_inspection              = true
  tls_certificate_key_vault_secret_id = azurerm_key_vault_certificate.tls_inspection.secret_id
  tls_certificate_name               = "tls-inspection-cert"

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.regional.id

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "IT-Security"
  }
}
```

### Using Static Cloudflare IPs

```hcl
module "azure_firewall" {
  source = "../../modules/security/azure-firewall"

  # ... basic config ...

  # Use static Cloudflare IP list
  fetch_cloudflare_ips_dynamically = false
  cloudflare_ip_ranges = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    # ... add more IPs ...
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.3 |
| azurerm | ~> 4.51.0 |
| http | ~> 3.4 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| firewall_name | Azure Firewall name | string |
| location | Azure region | string |
| resource_group_name | Resource group name | string |
| firewall_subnet_id | AzureFirewallSubnet ID | string |
| firewall_management_subnet_id | AzureFirewallManagementSubnet ID | string |
| firewall_policy_name | Firewall Policy name | string |
| firewall_public_ip_name | Firewall public IP name | string |
| firewall_management_ip_name | Management public IP name | string |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| availability_zones | Availability zones | list(string) | ["1", "2", "3"] |
| internal_lb_ip | Internal LB private IP | string | "" |
| fetch_cloudflare_ips_dynamically | Fetch Cloudflare IPs dynamically | bool | true |
| cloudflare_ip_ranges | Static Cloudflare IP list | list(string) | [14 ranges] |
| enable_ipv6 | Enable IPv6 support | bool | false |
| threat_intelligence_mode | Threat intel mode (Alert/Deny/Off) | string | "Alert" |
| idps_mode | IDPS mode (Alert/Deny/Off) | string | "Alert" |
| idps_signature_overrides | IDPS signature overrides | list(object) | [] |
| idps_traffic_bypass | IDPS traffic bypass rules | list(object) | [] |
| threat_intel_allowlist_ips | Threat intel IP allowlist | list(string) | [] |
| threat_intel_allowlist_fqdns | Threat intel FQDN allowlist | list(string) | [] |
| custom_dns_servers | Custom DNS servers | list(string) | [] |
| enable_tls_inspection | Enable TLS inspection | bool | false |
| tls_certificate_key_vault_secret_id | Key Vault TLS cert secret ID | string | null |
| tls_certificate_name | TLS certificate name | string | "tls-inspection-cert" |
| hub_vnet_cidr | Hub VNet CIDR | string | "10.0.0.0/16" |
| spoke_vnet_cidr | Spoke VNet CIDR | string | "10.1.0.0/16" |
| custom_source_addresses | Custom source addresses | list(string) | ["*"] |
| custom_destination_addresses | Custom destination addresses | list(string) | [] |
| custom_destination_ports | Custom destination ports | list(string) | ["443"] |
| custom_allowed_fqdns | Custom allowed FQDNs | list(string) | [] |
| log_analytics_workspace_id | Log Analytics workspace ID | string | null |
| tags | Resource tags | map(string) | {} |

## Outputs

### Primary Outputs

| Name | Description |
|------|-------------|
| firewall_id | Firewall resource ID |
| firewall_name | Firewall name |
| firewall_private_ip | Firewall private IP (for UDR) |
| firewall_public_ip | Firewall public IP |
| firewall_management_public_ip | Management public IP |
| firewall_policy_id | Firewall Policy ID |
| firewall_routing_config | Consolidated routing config for UDR |
| firewall_details | All firewall configuration details |
| deployment_status | Deployment status message |

### Reference Outputs

| Name | Description |
|------|-------------|
| cloudflare_ip_ranges_used | Cloudflare IPs in DNAT rules |
| cloudflare_ipv4_count | Number of Cloudflare ranges |
| firewall_sku | Firewall SKU tier |
| firewall_zones | Availability zones |
| threat_intelligence_mode | Threat intel mode |
| idps_mode | IDPS mode |
| dns_proxy_enabled | DNS proxy status |

## Firewall Rules

### DNAT Rules (Priority 100)

| Rule | Source | Destination | Translated To | Ports |
|------|--------|-------------|---------------|-------|
| allow-http-from-cloudflare | Cloudflare IPs | Firewall Public IP | Internal LB IP | 80 |
| allow-https-from-cloudflare | Cloudflare IPs | Firewall Public IP | Internal LB IP | 443 |

### Network Rules

#### Azure Services (Priority 100)
- Azure Monitor (443)
- Azure Storage (443, 445)
- Azure Container Registry (443)
- Azure Key Vault (443)
- Azure SQL/PostgreSQL (1433, 5432)

#### AKS Required (Priority 110)
- AKS API Server (443, 9000)
- NTP (123)
- External DNS (53)

#### VNet-to-VNet (Priority 130)
- Hub ↔ Spoke communication (all protocols)

### Application Rules

#### Azure FQDNs (Priority 100)
- Azure Management API
- Azure Container Registry
- Azure Key Vault
- Azure Monitor

#### AKS FQDNs (Priority 110)
- AzureKubernetesService FQDN tag
- Ubuntu package updates
- Kubernetes package repositories
- Microsoft package repositories

#### Container Registries (Priority 120)
- Docker Hub
- GitHub Container Registry (ghcr.io)
- Quay.io

## Two-Stage Deployment Strategy

### Stage 1: Initial Firewall Deployment

Deploy firewall **without** internal LB IP (before AKS):

```bash
cd environments/canada-central/prod
terraform apply -var="deployment_stage=stage1"
```

**Result:**
- ✅ Firewall deployed
- ✅ Public IP allocated
- ✅ DNAT rules created (with empty translated_address)
- ⚠️  DNAT rules not functional until Stage 2

### Stage 2: Configure DNAT with Internal LB IP

After AKS/Istio deployment, discover internal LB IP and update:

```bash
# Get Istio internal LB IP
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Output: 10.1.16.4

# Update terraform.tfvars
internal_lb_ip = "10.1.16.4"

# Apply Stage 2
terraform apply -var="deployment_stage=stage2"
```

**Result:**
- ✅ DNAT rules updated with valid translated_address
- ✅ Traffic flows: Cloudflare → Firewall → Internal LB → AKS Pods

## Cloudflare Integration

### Dynamic IP Fetching

By default, this module fetches Cloudflare IP ranges from the official API:

```hcl
fetch_cloudflare_ips_dynamically = true
```

**Data Source:**
- IPv4: `https://www.cloudflare.com/ips-v4`
- IPv6: `https://www.cloudflare.com/ips-v6` (if enabled)

**Advantages:**
- Always up-to-date with Cloudflare's published ranges
- No manual maintenance required
- Automatic updates on `terraform apply`

**Considerations:**
- Requires internet access during `terraform plan/apply`
- Cloudflare API must be reachable
- Plan will change if Cloudflare updates their ranges

### Static IP List

For air-gapped environments or stable configurations:

```hcl
fetch_cloudflare_ips_dynamically = false
cloudflare_ip_ranges = [
  "173.245.48.0/20",
  # ... 14 default ranges ...
]
```

## Security Best Practices

### 1. Start with Alert Mode

Begin with `threat_intelligence_mode = "Alert"` and `idps_mode = "Alert"`:

```hcl
threat_intelligence_mode = "Alert"
idps_mode               = "Alert"
```

**Monitor logs for:**
- False positives
- Legitimate traffic blocked
- Signature tuning needs

### 2. Gradually Enable Deny Mode

After monitoring for 1-2 weeks:

```hcl
threat_intelligence_mode = "Deny"
idps_mode               = "Deny"
```

### 3. Use IDPS Signature Overrides

Disable false positive signatures:

```hcl
idps_signature_overrides = [
  {
    id    = "2024897"
    state = "Off"
  }
]
```

### 4. Implement Threat Intelligence Allowlist

Allowlist trusted partners:

```hcl
threat_intel_allowlist_fqdns = [
  "trusted-api.partner.com"
]
```

### 5. Enable TLS Inspection (Optional)

For deep packet inspection:

1. Generate TLS certificate
2. Upload to Key Vault
3. Enable TLS inspection:

```hcl
enable_tls_inspection              = true
tls_certificate_key_vault_secret_id = "<key-vault-secret-id>"
```

**Note:** TLS inspection breaks end-to-end encryption and may cause certificate warnings.

## Monitoring and Logging

### Log Analytics Integration

All firewall logs are sent to Log Analytics workspace:

- **Application Rule Logs**: HTTP/HTTPS FQDN filtering
- **Network Rule Logs**: Layer 3/4 traffic
- **NAT Rule Logs**: DNAT translations
- **Threat Intelligence Logs**: Blocked malicious IPs
- **IDPS Logs**: Intrusion detection events
- **DNS Query Logs**: DNS proxy queries
- **Metrics**: Throughput, health, rule hits

### Sample Kusto Queries

**Top blocked FQDNs:**
```kusto
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| where msg_s contains "Deny"
| summarize Count=count() by Fqdn=tostring(split(msg_s, "|")[1])
| top 10 by Count desc
```

**IDPS alerts:**
```kusto
AzureDiagnostics
| where Category == "AZFWIdpsSignature"
| project TimeGenerated, msg_s
| order by TimeGenerated desc
```

**DNAT rule hits:**
```kusto
AzureDiagnostics
| where Category == "AZFWNatRule"
| summarize Count=count() by Rule=tostring(split(msg_s, "|")[0])
```

## Cost Considerations

### Azure Firewall Premium Pricing (Approximate)

- **Deployment**: ~$1,250/month (24/7 running)
- **Data Processing**: ~$0.016/GB processed
- **Public IPs**: ~$4/month per IP (2 IPs = $8/month)

**Typical Monthly Cost:**
- Small deployment (<100GB/month): ~$1,350/month
- Medium deployment (500GB/month): ~$1,350 + $8 = ~$1,358/month
- Large deployment (2TB/month): ~$1,350 + $32 = ~$1,382/month

**Cost Optimization:**
- Use forced tunneling (management subnet) for hybrid scenarios
- Consider Firewall Standard if Premium features not needed (~$625/month)
- Review rule efficiency to reduce data processing

## Troubleshooting

### Issue: Terraform plan shows DNAT rule changes every time

**Cause:** Dynamic Cloudflare IPs change

**Solution:** Use static IP list or accept minor updates

### Issue: Internal LB IP not reachable after Stage 2

**Diagnostic Steps:**
1. Verify internal LB IP: `kubectl get svc -n istio-system`
2. Check DNAT rule: `az network firewall nat-rule list`
3. Test from external: `curl -I http://<firewall-public-ip>`
4. Check UDR association on AKS subnets

### Issue: IDPS blocking legitimate traffic

**Solution:**
1. Identify signature ID from logs
2. Add signature override:
   ```hcl
   idps_signature_overrides = [
     { id = "123456", state = "Off" }
   ]
   ```
3. Re-apply Terraform

### Issue: Firewall deployment fails with subnet error

**Error:** `Subnet must be named AzureFirewallSubnet`

**Solution:** Ensure subnet name is exactly `AzureFirewallSubnet` (case-sensitive)

## Related Modules

- [hub-vnet](../../networking/hub-vnet/) - Creates hub VNet with firewall subnet
- [route-table](../route-table/) - Creates UDR pointing to firewall private IP
- [nsg](../nsg/) - Network Security Groups for defense-in-depth

## Version History

- **v1.0.0** (November 2025)
  - Initial release
  - Azure Firewall Premium with IDPS
  - Dynamic Cloudflare IP fetching
  - Two-stage deployment support
  - Comprehensive rule sets
  - Terraform 1.10.3 and AzureRM 4.51.0

## References

- [Azure Firewall Documentation](https://learn.microsoft.com/en-us/azure/firewall/)
- [Azure Firewall Premium Features](https://learn.microsoft.com/en-us/azure/firewall/premium-features)
- [Cloudflare IP Ranges](https://www.cloudflare.com/ips/)
- [AKS Outbound Network Rules](https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress)
