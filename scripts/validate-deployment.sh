#!/bin/bash
set -e

echo "Validating deployment..."
kubectl get nodes
kubectl get namespaces
echo "Validation complete!"
