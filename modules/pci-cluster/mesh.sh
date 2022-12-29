# Installs Managed Anthos Service Mesh
# more info: https://cloud.google.com/service-mesh/docs/managed/provision-managed-anthos-service-mesh 

gcloud services enable mesh.googleapis.com --project=pci-refresh-test-7c56
gcloud container fleet mesh enable --project pci-refresh-test-7c56

# gcloud auth login --project pci-refresh-test-7c56
# gcloud components update

# Configure kubectl to point to the cluster.
gcloud container clusters get-credentials in-scope \
    --region us-central1 \
    --project pci-refresh-test-7c56

# Register clusters to a fleet
# to get URI
# gcloud container clusters list --uri
gcloud container fleet memberships register in-scope-membership \
  --gke-uri=https://container.googleapis.com/v1/projects/pci-refresh-test-7c56/locations/us-central1/clusters/in-scope \
  --enable-workload-identity \
  --project pci-refresh-test-7c56
# Verify registered
gcloud container fleet memberships list --project pci-refresh-test-7c56

# Apply the mesh_id label
gcloud container clusters update  --project pci-refresh-test-7c56 in-scope \
  --region us-central1 --update-labels mesh_id=proj-pci-refresh-test-7c56

# Enable automatic management
gcloud container fleet mesh update \
     --management automatic \
     --memberships in-scope-membership \
     --project pci-refresh-test-7c56

# TODO
# Note that an ingress gateway isn't automatically deployed with the control plane. Decoupling the deployment of the ingress gateway and control plane allows you to more easily manage your gateways in a production environment. If the cluster needs an ingress gateway or an egress gateway, see Deploy gateways. To enable other optional features, see Enabling optional features on managed Anthos Service Mesh.
# https://cloud.google.com/service-mesh/docs/managed/provision-managed-anthos-service-mesh#enable_automatic_management

# Verify control plane provisioned
gcloud container fleet mesh describe --project pci-refresh-test-7c56

# Managed Data Plane is currently disabled.

# Deploy Applictions:
# To deploy applications, use either the label corresponding to the channel you configured during installation or istio-injection=enabled if you are using default injection labels.
# kubectl label namespace NAMESPACE istio-injection=enabled istio.io/rev- --overwrite

# Install Gateway
# source https://cloud.google.com/service-mesh/docs/unified-install/install-anthos-service-mesh#install_gateways

kubectl create namespace gateway-namespace

# Apply default injection label (no revision specified)
#kubectl label namespace gateway-namespace istio-injection=enabled istio.io/rev-
# Using stable as previously defined
kubectl label namespace gateway-namespace \
  istio.io/rev=stable --overwrite
