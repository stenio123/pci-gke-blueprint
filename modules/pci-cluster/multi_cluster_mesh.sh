
# from version 1.15
# Configure discovery between two clusters
# Source https://cloud.google.com/service-mesh/docs/unified-install/gke-install-multi-cluster#private-clusters-endpoint
export PROJECT_1=pci-refresh-test-7c56
export LOCATION_1=us-central1
export CLUSTER_1=in-scope
export CTX_1="gke_${PROJECT_1}_${LOCATION_1}_${CLUSTER_1}"

export PROJECT_2=pci-refresh-test-7c56
export LOCATION_2=us-central1
export CLUSTER_2=out-of-scope
export CTX_2="gke_${PROJECT_2}_${LOCATION_2}_${CLUSTER_2}"

export NETWORK_NAME=pci-vpc
export NETWORK_PATH="projects/${PROJECT_1}/global/networks/${NETWORK_NAME}"

gcloud config set project pci-refresh-test-7c56
gcloud container clusters get-credentials ${CLUSTER_1} --region ${LOCATION_1}
gcloud container clusters get-credentials ${CLUSTER_2} --region ${LOCATION_2}

# Create firewall rule
## Gather information for all clusters in project(if you don't want to add specific clusters, check instructions on the link top of this file)
function join_by { local IFS="$1"; shift; echo "$*"; }
ALL_CLUSTER_CIDRS=$(gcloud container clusters list --project $PROJECT_1 --format='value(clusterIpv4Cidr)' | sort | uniq)
ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
#No cluster nettags in this installation
#ALL_CLUSTER_NETTAGS=$(gcloud compute instances list --project $PROJECT_1 --format='value(tags.items.[0])' | sort | uniq)
#ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))

## Create firewall rule - all clusters (but not all services, since the mesh will track that) can communicate with each other
gcloud compute firewall-rules create "istio-multicluster-pods" \
  --allow tcp,udp,icmp,esp,ah,sctp \
  --direction INGRESS \
  --priority 900 \
  --source-ranges "${ALL_CLUSTER_CIDRS}" \
  --network "${NETWORK_PATH}" #\
  # Since no nettags, it would miss this parameter, so comment out
  #--target-tags "${ALL_CLUSTER_NETTAGS}" 

# Setup endpoint discovery
## Using Declarative API. For other options check the link top of this file
kubectl patch configmap/asm-options -n istio-system --type merge -p '{"data":{"multicluster_mode":"connected"}}'

# Configure authorized networks for private clusters
#source: https://cloud.google.com/service-mesh/docs/unified-install/gke-install-multi-cluster#private-clusters-authorized-network
#Follow this section only if all of the following conditions apply to your mesh:

#You are using private clusters.
#The clusters do not belong to the same subnet.
#The clusters have enabled authorized networks.
#Get the Pod IP CIDR block for each cluster:
POD_IP_CIDR_1=`gcloud container clusters describe ${CLUSTER_1} --project ${PROJECT_1} --zone ${LOCATION_1} \
  --format "value(ipAllocationPolicy.clusterIpv4CidrBlock)"`

POD_IP_CIDR_2=`gcloud container clusters describe ${CLUSTER_2} --project ${PROJECT_2} --zone ${LOCATION_2} \
  --format "value(ipAllocationPolicy.clusterIpv4CidrBlock)"`

#Add the Kubernetes cluster Pod IP CIDR blocks to the remote clusters:
EXISTING_CIDR_1=`gcloud container clusters describe ${CLUSTER_1} --project ${PROJECT_1} --zone ${LOCATION_1} \
 --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"`
gcloud container clusters update ${CLUSTER_1} --project ${PROJECT_1} --zone ${LOCATION_1} \
--enable-master-authorized-networks \
--master-authorized-networks ${POD_IP_CIDR_2},${EXISTING_CIDR_1//;/,}

EXISTING_CIDR_2=`gcloud container clusters describe ${CLUSTER_2} --project ${PROJECT_2} --zone ${LOCATION_2} \
 --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"`
gcloud container clusters update ${CLUSTER_2} --project ${PROJECT_2} --zone ${LOCATION_2} \
--enable-master-authorized-networks \
--master-authorized-networks ${POD_IP_CIDR_1},${EXISTING_CIDR_2//;/,}

# Verify that the authorized networks are updated:
gcloud container clusters describe ${CLUSTER_1} --project ${PROJECT_1} --zone ${LOCATION_1} \
 --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"

gcloud container clusters describe ${CLUSTER_2} --project ${PROJECT_2} --zone ${LOCATION_2} \
 --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"

# Enable automatic sidecar injection
## Check which asm deployed
kubectl -n istio-system get controlplanerevision

# Using rapid here to avoid error
#Error: admission webhook asm managed denied the request 'NET_ADMIN' on container 'istio-init' not allowed;
#solution: change asm channel to rapid
# TODO make sure it matches in other previous places
kubectl label namespace default  istio-injection- istio.io/rev=asm-rapid --overwrite


## Test Connection
# go to asmcli folder
# export ASM_VERSION="$(./asmcli --version)"

# make sure matches folder where you downloaded samples (during asm install)
# export SAMPLES_DIR=in-scope/istio-${ASM_VERSION%+*}

# create namespaces in each cluster with auto injection enabled(context was set behind the scenes when cluster credentials were retireved in the start of this file)
#for CTX in ${CTX_1} ${CTX_2}
#do
#    kubectl create --context=${CTX} namespace sample
#    kubectl label --context=${CTX} namespace sample \
#        istio-injection- istio.io/rev=rapid --overwrite
#done

# Message " label "istio-injection" not found." is correct
# Create hello world both clusters
#kubectl create --context=${CTX_1} \
#    -f ${SAMPLES_DIR}/samples/helloworld/helloworld.yaml \
#    -l service=helloworld -n sample

#kubectl create --context=${CTX_2} \
#    -f ${SAMPLES_DIR}/samples/helloworld/helloworld.yaml \
#    -l service=helloworld -n sample

# Deploy hello world
#kubectl create --context=${CTX_1} \
#  -f ${SAMPLES_DIR}/samples/helloworld/helloworld.yaml \
#  -l version=v1 -n sample

#kubectl create --context=${CTX_2} \
#  -f ${SAMPLES_DIR}/samples/helloworld/helloworld.yaml \
#  -l version=v2 -n sample

# Confirm running
#kubectl get pod --context=${CTX_1} -n sample
#kubectl get pod --context=${CTX_2} -n sample
#Error: admission webhook asm managed denied the request 'NET_ADMIN' on container 'istio-init' not allowed;
#solution: change asm channel to rapid

# deploy sleep service
#for CTX in ${CTX_1} ${CTX_2}
#do
#    kubectl apply --context=${CTX} \
#        -f ${SAMPLES_DIR}/samples/sleep/sleep.yaml -n sample
#done

# wait for start, then
# kubectl get pod --context=${CTX_1} -n sample -l app=sleep

#Cross cluster load balancing
#kubectl exec --context="${CTX_1}" -n sample -c sleep \
#    "$(kubectl get pod --context="${CTX_1}" -n sample -l \
#    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
#    -- /bin/sh -c 'for i in $(seq 1 20); do curl -sS helloworld.sample:5000/hello; done'
# about 10-20 iterations

#kubectl exec --context="${CTX_2}" -n sample -c sleep \
#    "$(kubectl get pod --context="${CTX_2}" -n sample -l \
#    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
#    -- /bin/sh -c 'for i in $(seq 1 20); do curl -sS helloworld.sample:5000/hello; done'
# about 10-20 iterations

# Cleanup
#kubectl delete ns sample --context ${CTX_1}
#kubectl delete ns sample --context ${CTX_2}