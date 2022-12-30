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
```
## Notes
### Isolation
- Despite being in different subnets, both clusters are in the same project, to make it easier to manage as a single Anthos fleet. Only one fleet can exist per project. In theory each cluster could be in a separate project and separate fleet, however in the best practices it is recommended that services that interact with each other oftern (such as the Online Boutique microservices) should be part of the same fleet for easier config management. Having two fleets would add network complexity, cluster management complexity and additional costs, increasing the risk of a misconfiguration and reducing development speed. 
    
   We use the same fleet because the services are related to each other and are administered by the same team. [Source](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts#grouping_infrastructure)
- To leverage Anthos Service Mesh across clusters, the "in-scope" cluster accepts connections from the "out-of-scope" cluster, despite being in different subnets. This is described [here](https://cloud.google.com/service-mesh/docs/unified-install/gke-install-multi-cluster#private-clusters-endpoint) and configured in the modules/pci-cluster variables "master_authorized_networks"
- There could be a further division where the Anthos fleet management is in one project, and each cluster is in its own project, however there is no clear benefit for our pci use case
- Despite the clusters being able to communicate to each other through the firewall, and having permissions managed by the Anthos Service Mesh, there is still benefit in having separate subnets - it ensures that other clusters, services, applications deployed in this subnet, which are not part of these clusters, won't have access to the clusters, services and applications of the other subnet

### Pricing
- Anthos has two pricing models - subscription based, when the API is enabled
- Per service (service mesh, config manager)
- TODO links