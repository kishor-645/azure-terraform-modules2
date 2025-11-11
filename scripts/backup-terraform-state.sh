#!/bin/bash
set -e

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p backups
az storage blob download --account-name sttfstateccprod --container-name tfstate --name canadacentral/prod/terraform.tfstate --file backups/terraform-$TIMESTAMP.tfstate
echo "Backup complete: backups/terraform-$TIMESTAMP.tfstate"
