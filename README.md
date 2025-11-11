# ERP Infrastructure - Azure Terraform

Production-ready infrastructure for ERP system on Azure with simplified architecture.

## Quick Start

1. Navigate to environment: `cd environments/canada-central/prod` or `cd environments/canada-central/dev`
2. Copy variables: `cp terraform.tfvars.example terraform.tfvars`
3. Update `terraform.tfvars` with your values
4. Initialize: `terraform init`
5. Deploy Stage 1: `terraform apply`
6. Get Istio LB IP: `kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
7. Update `terraform.tfvars` with Istio LB IP and set `deployment_stage = "stage2"`
8. Deploy Stage 2: `terraform apply`

## Documentation

- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Complete Azure DevOps pipeline setup and deployment guide
- **[Infrastructure Guide](environments/canada-central/prod/INFRASTRUCTURE-DEPLOYMENT-GUIDE.md)** - Detailed infrastructure deployment steps and architecture
- [MODULES-GUIDE.md](docs/MODULES-GUIDE.md) - Detailed module usage and reference
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architecture details
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Key Features

- **Single Resource Group**: All resources in one resource group per environment
- **Single Region**: All resources in Canada Central region
- **Hub-Spoke Network Topology**: Centralized firewall for security
- **Private AKS Cluster**: With Istio Service Mesh (inbuilt feature)
- **Shared AKS Subnet**: Both system and user node pools use the same subnet
- **Azure Firewall Premium**: With IDPS and threat intelligence
- **PostgreSQL Flexible Server**: Managed database with private endpoint
- **Private Endpoints**: All Azure services accessed via private endpoints
- **Centralized Monitoring**: Log Analytics workspace for all resources

## Environments

- **Production**: `environments/canada-central/prod/`
- **Development**: `environments/canada-central/dev/`

## Architecture Simplifications

- ✅ Single resource group instead of 4
- ✅ Single shared subnet for AKS (system + user node pools)
- ✅ Istio enabled as inbuilt AKS feature (no shell scripts)
- ✅ Two environments only (prod and dev)
- ✅ Single region deployment (Canada Central)

## Cost

Estimated Monthly Cost: $3,445 - $5,945 USD (varies by usage and node count)

v2.0.0 (November 2025)
