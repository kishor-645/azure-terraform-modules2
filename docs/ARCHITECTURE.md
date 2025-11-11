# Architecture Documentation

Hub-spoke network topology with Azure Firewall and private AKS cluster.

## Network Architecture

Hub VNet: 10.0.0.0/16
Spoke VNet: 10.1.0.0/16

## Components

- Azure Firewall Premium
- Private AKS with Istio
- Azure Bastion
- PostgreSQL Flexible Server

v1.0.0 (November 2025)
