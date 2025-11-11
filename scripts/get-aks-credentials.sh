#!/bin/bash
set -e

az aks get-credentials --resource-group rg-spoke-canadacentral-prod --name aks-canadacentral-prod
kubectl get nodes
