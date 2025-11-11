# AKS Cluster with Istio Service Mesh Module

Private AKS cluster with Azure CNI Overlay, Calico network policy, and Istio service mesh.

## Features
- ✅ **Private Cluster** with private endpoint
- ✅ **Azure CNI Overlay** for efficient IP usage
- ✅ **Calico Network Policy** for pod-level security
- ✅ **Istio Service Mesh** with internal ingress gateway
- ✅ **User-Assigned Managed Identity**
- ✅ **ACR Integration** with AcrPull role
- ✅ **Key Vault Secrets Provider** with CSI driver
- ✅ **Azure AD RBAC** for authorization
- ✅ **Monitoring Add-on** with Log Analytics
- ✅ **Autoscaling** (1-5 nodes per pool)
- ✅ **Two-Stage Deployment** (loadBalancer → userDefinedRouting)

## Usage

### Stage 1: Initial Deployment (with LoadBalancer)
\`\`\`hcl
module "aks_cluster" {
  source = "../../modules/compute/aks-cluster"

  cluster_name            = "aks-canadacentral-prod"
  location                = "canadacentral"
  resource_group_name     = "rg-spoke-canadacentral-prod"
  dns_prefix              = "aks-canadacentral-prod"
  node_resource_group_name = "rg-aks-nodes-canadacentral-prod"
  kubernetes_version      = "1.28"

  # Network Configuration
  vnet_id                     = module.spoke_vnet.vnet_id
  system_node_pool_subnet_id  = module.spoke_vnet.aks_system_subnet_id
  user_node_pool_subnet_id    = module.spoke_vnet.aks_user_subnet_id
  
  # Stage 1: Use loadBalancer for initial deployment
  outbound_type = "loadBalancer"

  # Identity
  aks_identity_name = "id-aks-canadacentral-prod"
  acr_id           = module.acr.acr_id
  key_vault_id     = module.key_vault.key_vault_id

  # Azure AD Integration
  azure_rbac_enabled     = true
  tenant_id              = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids = ["your-admin-group-object-id"]

  # Istio Configuration
  istio_internal_ingress_gateway_enabled = true
  istio_external_ingress_gateway_enabled = false

  # Monitoring
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
\`\`\`

### Stage 2: Update to User-Defined Routing
\`\`\`hcl
# After firewall and route table are configured
module "aks_cluster" {
  # ... same config as Stage 1 ...

  # Stage 2: Switch to userDefinedRouting
  outbound_type = "userDefinedRouting"
}
\`\`\`

## Two-Stage Deployment Strategy

### Why Two Stages?
- **Circular Dependency**: Firewall needs Istio internal LB IP, but AKS needs firewall to be configured first
- **Solution**: Deploy AKS with loadBalancer first, then switch to userDefinedRouting

### Stage 1: Initial Deployment
1. Deploy AKS with `outbound_type = "loadBalancer"`
2. Deploy Istio (automatically configured by AKS)
3. Get Istio internal LB IP: `kubectl get svc istio-ingressgateway -n istio-system`

### Stage 2: Switch to Firewall Routing
1. Update firewall DNAT rules with Istio internal LB IP
2. Create route table with default route to firewall
3. Associate route table with AKS subnets
4. Update AKS: `outbound_type = "userDefinedRouting"`
5. Recreate node pools (automatic during update)

## Requirements
- Terraform >= 1.10.3
- azurerm ~> 4.51.0

## Node Pools

### System Node Pool
- **Purpose**: System pods (CoreDNS, metrics-server)
- **VM Size**: Standard_D4s_v5 (4 vCPU, 16 GB RAM)
- **Autoscaling**: 1-5 nodes
- **Max Pods**: 30 per node

### User Node Pool
- **Purpose**: Application workloads
- **VM Size**: Standard_F16s_v2 (16 vCPU, 32 GB RAM)
- **Autoscaling**: 1-5 nodes
- **Max Pods**: 110 per node

## Istio Configuration

### Internal Ingress Gateway
- **Purpose**: Receive traffic from Azure Firewall
- **Service Type**: LoadBalancer (internal)
- **IP**: Assigned from AKS user subnet (e.g., 10.1.16.4)

### External Ingress Gateway
- **Status**: Disabled (traffic comes through firewall)

## Monitoring

### Log Analytics Integration
- Container logs
- Performance metrics
- Resource utilization
- Istio telemetry

### Prometheus Metrics
- Scraped by Azure Monitor
- Available in Log Analytics

## Security

### Azure AD RBAC
- Users authenticate with Azure AD
- Authorization controlled by Azure RBAC roles
- No static kubeconfig credentials

### Network Policies
- Calico enforces pod-to-pod communication rules
- Default deny all ingress
- Explicit allow rules required

### Key Vault Integration
- Secrets mounted as volumes via CSI driver
- Automatic rotation every 2 minutes
- No secrets stored in pod definitions

## Cost Estimation

### Cluster Control Plane
- **Free**: Control plane is managed by Azure at no cost

### Node Pools (per node, per month)
- **System Pool (D4s_v5)**: ~$140/month per node
- **User Pool (F16s_v2)**: ~$625/month per node

### Total Monthly Cost (Production)
- System Pool: 2-5 nodes = $280-700/month
- User Pool: 1-5 nodes = $625-3,125/month
- **Total**: ~$905-3,825/month (excluding egress)

v1.0.0 (November 2025)
