#!/bin/bash
# Pre-Deployment Resource Conflict Checker
# This script checks for potential conflicts with existing Azure resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Azure Resource Conflict Checker${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    echo "Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI is installed and authenticated${NC}"
echo ""

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${BLUE}Current Subscription:${NC} $SUBSCRIPTION"
echo -e "${BLUE}Subscription ID:${NC} $SUBSCRIPTION_ID"
echo ""

# Expected resource names from Terraform
EXPECTED_RG="rg-erp-cc-prod"
EXPECTED_AKS="aks-canadacentral-prod"
EXPECTED_PSQL="psql-erp-cc-prod"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}1. Checking Resource Groups${NC}"
echo -e "${YELLOW}========================================${NC}"

# List all resource groups
echo "Existing Resource Groups:"
az group list --query "[].{Name:name, Location:location}" -o table
echo ""

# Check if expected RG exists
if az group show --name "$EXPECTED_RG" &> /dev/null; then
    echo -e "${RED}⚠️  WARNING: Resource group '$EXPECTED_RG' already exists!${NC}"
    echo -e "${RED}   This Terraform will try to create this resource group.${NC}"
    echo -e "${RED}   ACTION REQUIRED: Change the naming prefix in locals.tf${NC}"
    echo ""
    echo "   Resources in this group:"
    az resource list --resource-group "$EXPECTED_RG" --query "[].{Name:name, Type:type}" -o table
    echo ""
else
    echo -e "${GREEN}✅ Resource group '$EXPECTED_RG' does not exist (safe to create)${NC}"
fi
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}2. Checking VNet CIDR Ranges${NC}"
echo -e "${YELLOW}========================================${NC}"

echo "Terraform will create VNets with these CIDR ranges:"
echo -e "  ${BLUE}Hub VNet:${NC}   10.0.0.0/16"
echo -e "  ${BLUE}Spoke VNet:${NC} 10.1.0.0/16"
echo ""

echo "Your existing VNets and their CIDR ranges:"
VNETS=$(az network vnet list --query "[].{Name:name, ResourceGroup:resourceGroup, AddressSpace:addressSpace.addressPrefixes[0]}" -o tsv)

if [ -z "$VNETS" ]; then
    echo -e "${GREEN}✅ No existing VNets found${NC}"
else
    echo "$VNETS" | while IFS=$'\t' read -r name rg cidr; do
        echo -e "  ${BLUE}$name${NC} (RG: $rg): $cidr"
        
        # Check for conflicts
        if [[ "$cidr" == "10.0.0.0/16" ]] || [[ "$cidr" == "10.1.0.0/16" ]]; then
            echo -e "    ${RED}⚠️  CONFLICT: This CIDR overlaps with planned infrastructure!${NC}"
            echo -e "    ${RED}   ACTION REQUIRED: Change CIDR ranges in locals.tf${NC}"
        fi
    done
fi
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}3. Checking AKS Clusters${NC}"
echo -e "${YELLOW}========================================${NC}"

echo "Terraform will create AKS cluster: $EXPECTED_AKS"
echo ""

AKS_CLUSTERS=$(az aks list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Version:kubernetesVersion}" -o tsv)

if [ -z "$AKS_CLUSTERS" ]; then
    echo -e "${GREEN}✅ No existing AKS clusters found${NC}"
else
    echo "Your existing AKS clusters:"
    echo "$AKS_CLUSTERS" | while IFS=$'\t' read -r name rg location version; do
        echo -e "  ${BLUE}$name${NC} (RG: $rg, Location: $location, Version: $version)"
        
        if [[ "$name" == "$EXPECTED_AKS" ]]; then
            echo -e "    ${RED}⚠️  CONFLICT: Cluster name matches planned infrastructure!${NC}"
            echo -e "    ${RED}   ACTION REQUIRED: Change the naming prefix in locals.tf${NC}"
        fi
    done
fi
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}4. Checking PostgreSQL Servers${NC}"
echo -e "${YELLOW}========================================${NC}"

echo "Terraform will create PostgreSQL server: $EXPECTED_PSQL"
echo ""

PSQL_SERVERS=$(az postgres flexible-server list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Version:version}" -o tsv 2>/dev/null || echo "")

if [ -z "$PSQL_SERVERS" ]; then
    echo -e "${GREEN}✅ No existing PostgreSQL Flexible servers found${NC}"
else
    echo "Your existing PostgreSQL servers:"
    echo "$PSQL_SERVERS" | while IFS=$'\t' read -r name rg location version; do
        echo -e "  ${BLUE}$name${NC} (RG: $rg, Location: $location, Version: $version)"
        
        if [[ "$name" == "$EXPECTED_PSQL" ]]; then
            echo -e "    ${RED}⚠️  CONFLICT: Server name matches planned infrastructure!${NC}"
            echo -e "    ${RED}   ACTION REQUIRED: Change the naming prefix in locals.tf${NC}"
        fi
    done
fi
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}5. Checking Storage Accounts${NC}"
echo -e "${YELLOW}========================================${NC}"

echo "Terraform will create storage account with pattern: sterp*ccprod (with random suffix)"
echo ""

STORAGE_ACCOUNTS=$(az storage account list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o tsv)

if [ -z "$STORAGE_ACCOUNTS" ]; then
    echo -e "${GREEN}✅ No existing storage accounts found${NC}"
else
    echo "Your existing storage accounts:"
    echo "$STORAGE_ACCOUNTS" | while IFS=$'\t' read -r name rg location; do
        echo -e "  ${BLUE}$name${NC} (RG: $rg, Location: $location)"
        
        if [[ "$name" == sterp*ccprod ]]; then
            echo -e "    ${YELLOW}⚠️  Similar naming pattern detected${NC}"
            echo -e "    ${YELLOW}   Terraform uses random suffix, should be safe${NC}"
        fi
    done
fi
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}6. Checking Key Vaults${NC}"
echo -e "${YELLOW}========================================${NC}"

echo "Terraform will create Key Vault with pattern: kv-erp-*-cc-prod (with random suffix)"
echo ""

KEY_VAULTS=$(az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o tsv)

if [ -z "$KEY_VAULTS" ]; then
    echo -e "${GREEN}✅ No existing Key Vaults found${NC}"
else
    echo "Your existing Key Vaults:"
    echo "$KEY_VAULTS" | while IFS=$'\t' read -r name rg location; do
        echo -e "  ${BLUE}$name${NC} (RG: $rg, Location: $location)"
        
        if [[ "$name" == kv-erp-*-cc-prod ]]; then
            echo -e "    ${YELLOW}⚠️  Similar naming pattern detected${NC}"
            echo -e "    ${YELLOW}   Terraform uses random suffix, should be safe${NC}"
        fi
    done
fi
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}7. Checking Container Registries${NC}"
echo -e "${YELLOW}========================================${NC}"

echo "Terraform will create ACR with pattern: acrerp*ccprod (with random suffix)"
echo ""

ACRS=$(az acr list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o tsv 2>/dev/null || echo "")

if [ -z "$ACRS" ]; then
    echo -e "${GREEN}✅ No existing Container Registries found${NC}"
else
    echo "Your existing Container Registries:"
    echo "$ACRS" | while IFS=$'\t' read -r name rg location; do
        echo -e "  ${BLUE}$name${NC} (RG: $rg, Location: $location)"
        
        if [[ "$name" == acrerp*ccprod ]]; then
            echo -e "    ${YELLOW}⚠️  Similar naming pattern detected${NC}"
            echo -e "    ${YELLOW}   Terraform uses random suffix, should be safe${NC}"
        fi
    done
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review any warnings above"
echo "2. If conflicts found, update naming in environments/canada-central/prod/locals.tf"
echo "3. Run: cd environments/canada-central/prod && terraform plan"
echo "4. Carefully review the plan output before applying"
echo "5. See PRE-DEPLOYMENT-SAFETY-CHECKLIST.md for detailed guidance"
echo ""
echo -e "${GREEN}✅ Resource conflict check complete${NC}"

