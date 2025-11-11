#!/bin/bash
# Script to retrieve secrets from Azure Key Vault and update terraform.tfvars
# Usage: ./get-secrets-from-keyvault.sh <keyvault-name> <tfvars-file-path>

set -e

KEYVAULT_NAME="${1}"
TFVARS_FILE="${2}"

if [ -z "$KEYVAULT_NAME" ] || [ -z "$TFVARS_FILE" ]; then
  echo "Usage: $0 <keyvault-name> <tfvars-file-path>"
  exit 1
fi

echo "Retrieving secrets from Key Vault: $KEYVAULT_NAME"

# Ensure tfvars file exists and has newline at end
if [ -s "$TFVARS_FILE" ]; then
  echo "" >> "$TFVARS_FILE"
fi

# List of secrets to retrieve
SECRETS=(
  "postgresql-admin-login"
  "postgresql-admin-password"
  "jumpbox-admin-username"
  "jumpbox-admin-password"
  "agent-vm-admin-username"
  "agent-vm-admin-password"
)

# Retrieve and append secrets to tfvars
for secret in "${SECRETS[@]}"; do
  # Convert secret name to terraform variable name
  case $secret in
    "postgresql-admin-login")
      VAR_NAME="postgresql_admin_login"
      ;;
    "postgresql-admin-password")
      VAR_NAME="postgresql_admin_password"
      ;;
    "jumpbox-admin-username")
      VAR_NAME="jumpbox_admin_username"
      ;;
    "jumpbox-admin-password")
      VAR_NAME="jumpbox_admin_password"
      ;;
    "agent-vm-admin-username")
      VAR_NAME="agent_vm_admin_username"
      ;;
    "agent-vm-admin-password")
      VAR_NAME="agent_vm_admin_password"
      ;;
    *)
      VAR_NAME=$(echo "$secret" | tr '-' '_')
      ;;
  esac

  # Get secret value from Key Vault
  SECRET_VALUE=$(az keyvault secret show \
    --vault-name "$KEYVAULT_NAME" \
    --name "$secret" \
    --query "value" \
    --output tsv 2>/dev/null || echo "")

  if [ -n "$SECRET_VALUE" ]; then
    # Remove existing variable if present
    sed -i "/^${VAR_NAME}[[:space:]]*=/d" "$TFVARS_FILE"
    # Append new variable
    echo "${VAR_NAME} = \"${SECRET_VALUE}\"" >> "$TFVARS_FILE"
    echo "✓ Retrieved and updated: $VAR_NAME"
  else
    echo "⚠ Warning: Secret '$secret' not found in Key Vault"
  fi
done

echo "Secrets retrieval complete!"

