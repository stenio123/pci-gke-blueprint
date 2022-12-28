# GKE PCI DSS 4.0 Blueprint

## Overview
1. Create a project using project_factory module
2. Create network, subnets, NAT and router to enable the private cluster to have external access
3. Create 2 GKE clusters
4. Enable service mesh
5. Configure k8s externally

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