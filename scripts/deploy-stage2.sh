#!/bin/bash
set -e

echo "Deploying Stage 2..."
cd environments/canadacentral/prod
terraform plan -out=tfplan
terraform apply tfplan
echo "Stage 2 deployment complete!"
