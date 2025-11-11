#!/bin/bash
set -e

RESOURCE_GROUP="rg-terraform-state-canadacentral"
STORAGE_ACCOUNT="sttfstateccprod"

az group create --name "$RESOURCE_GROUP" --location canadacentral
az storage account create --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP"
