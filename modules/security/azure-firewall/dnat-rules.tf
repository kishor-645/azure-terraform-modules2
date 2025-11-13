# DNAT (Destination NAT) Rules
# Manages inbound traffic from Cloudflare to internal load balancer

# ========================================
# Fetch Cloudflare IP Ranges
# ========================================

# Fetch Cloudflare IPv4 ranges dynamically
data "http" "cloudflare_ips_v4" {
  count = var.fetch_cloudflare_ips_dynamically ? 1 : 0
  url   = "https://www.cloudflare.com/ips-v4"
}

# Fetch Cloudflare IPv6 ranges dynamically (optional)
data "http" "cloudflare_ips_v6" {
  count = var.fetch_cloudflare_ips_dynamically && var.enable_ipv6 ? 1 : 0
  url   = "https://www.cloudflare.com/ips-v6"
}

# Parse Cloudflare IPs
locals {
  # Use dynamic Cloudflare IPs if enabled, otherwise use static list
  cloudflare_ipv4_list = var.fetch_cloudflare_ips_dynamically ? split("\n", trimspace(data.http.cloudflare_ips_v4[0].response_body)) : var.cloudflare_ip_ranges

  cloudflare_ipv6_list = var.fetch_cloudflare_ips_dynamically && var.enable_ipv6 ? split("\n", trimspace(data.http.cloudflare_ips_v6[0].response_body)) : []

  # Combine IPv4 and IPv6 if enabled
  cloudflare_all_ips = var.enable_ipv6 ? concat(local.cloudflare_ipv4_list, local.cloudflare_ipv6_list) : local.cloudflare_ipv4_list
}

# ========================================
# DNAT Rule Collection Group
# ========================================

resource "azurerm_firewall_policy_rule_collection_group" "dnat" {
  name               = "dnat-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  # ========================================
  # Cloudflare to Internal Load Balancer
  # ========================================
  nat_rule_collection {
    name     = "cloudflare-to-istio-ilb"
    priority = 100
    action   = "Dnat"

    # HTTP Rule
    rule {
      name      = "allow-http-from-cloudflare"
      protocols = ["TCP"]

      source_addresses = local.cloudflare_all_ips

      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["80"]

      translated_address = var.internal_lb_ip
      translated_port    = 80
    }

    # HTTPS Rule
    rule {
      name      = "allow-https-from-cloudflare"
      protocols = ["TCP"]

      source_addresses = local.cloudflare_all_ips

      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["443"]

      translated_address = var.internal_lb_ip
      translated_port    = 443
    }
  }

  # ========================================
  # Additional DNAT Rules (Commented Examples)
  # ========================================

  # Example: SSH Access to Jumpbox
  # Uncomment and configure for SSH access from specific IPs
  # nat_rule_collection {
  #   name     = "ssh-to-jumpbox"
  #   priority = 110
  #   action   = "Dnat"
  #
  #   rule {
  #     name = "allow-ssh-from-admin"
  #     protocols = ["TCP"]
  #     
  #     source_addresses = ["YOUR_ADMIN_PUBLIC_IP/32"]
  #     
  #     destination_address = azurerm_public_ip.firewall.ip_address
  #     destination_ports   = ["22"]
  #     
  #     translated_address = "10.1.30.132"  # Jumpbox private IP
  #     translated_port    = 22
  #   }
  # }

  # Example: RDP Access (Windows Jumpbox)
  # nat_rule_collection {
  #   name     = "rdp-to-jumpbox"
  #   priority = 120
  #   action   = "Dnat"
  #
  #   rule {
  #     name = "allow-rdp-from-admin"
  #     protocols = ["TCP"]
  #     
  #     source_addresses = ["YOUR_ADMIN_PUBLIC_IP/32"]
  #     
  #     destination_address = azurerm_public_ip.firewall.ip_address
  #     destination_ports   = ["3389"]
  #     
  #     translated_address = "10.1.30.133"  # Windows Jumpbox private IP
  #     translated_port    = 3389
  #   }
  # }

  depends_on = [
    azurerm_firewall_policy.this
  ]
}
