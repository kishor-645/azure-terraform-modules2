# Canada Central Production Environment

Complete production infrastructure for ERP system in Canada Central region.

## Two-Stage Deployment

### Stage 1: Initial Deployment
terraform init
terraform plan
terraform apply

### Stage 2: Switch to Firewall Routing
Update terraform.tfvars with deployment_stage = stage2
terraform plan
terraform apply

## Cost Estimation

Azure Firewall Premium: ~$1,350/month
AKS Cluster: ~$1,000-$3,500/month
Azure Bastion: ~$295/month
Total: ~$2,645-$5,145/month

v1.0.0 (November 2025)
