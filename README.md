# GKE PCI DSS 4.0 Blueprint

## Overview

## How to Deploy

### Infrastructure and GKE

### Configuring GKE Cluster

```
gcloud config set project pci-refresh-test-ae18
gcloud container clusters get-credentials in-scope --zone us-central1
# creds valid for X minutes

IN_SCOPE_INGRESS_NAME=terraform output -json in_scope_ingress_name | jq -r '.[0]'
IN_SCOPE_INGRESS_ADDRESS=terraform output -json in_scope_ingress_address | jq -r '.[0]'
SECURITY_POLICY_NAME=terraform output -json security_policy_name | jq -r '.[0]'
kubectl apply -f ./dir 