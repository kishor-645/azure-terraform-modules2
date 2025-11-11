#!/bin/bash
set -e

ISTIO_LB_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Istio Internal LB IP: $ISTIO_LB_IP"
