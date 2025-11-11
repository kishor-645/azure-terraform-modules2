#!/bin/bash
set -e

echo "Deploying Stage 1..."
cd environments/canadacentral/prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
echo "Stage 1 deployment complete!"
