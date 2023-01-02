export PROJECT_1=pci-refresh-test-7c56
export LOCATION_1=us-central1
export CLUSTER_1=in-scope
export IN_SCOPE_CLUSTER_CTX="gke_${PROJECT_1}_${LOCATION_1}_${CLUSTER_1}"

export PROJECT_2=pci-refresh-test-7c56
export LOCATION_2=us-central1
export CLUSTER_2=out-of-scope
export OUT_OF_SCOPE_CLUSTER_CTX="gke_${PROJECT_2}_${LOCATION_2}_${CLUSTER_2}"

export NETWORK_NAME=pci-vpc
export NETWORK_PATH="projects/${PROJECT_1}/global/networks/${NETWORK_NAME}"

export APP_DIR="app/store"
 

# in-scope cluster application resources per namespace
kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n paymentservice  apply -f ${APP_DIR}/cluster/in-scope/namespaces/paymentservice
kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n checkoutservice apply -f ${APP_DIR}/cluster/in-scope/namespaces/checkoutservice
kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n frontend        apply -f ${APP_DIR}/cluster/in-scope/namespaces/frontend

# store-out-of-scope resources on in-scope cluster
kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n store-out-of-scope apply -f ${APP_DIR}/cluster/in-scope/namespaces/store-out-of-scope

# store-out-of-scope resources on out-of-scope cluster
kubectl --context ${OUT_OF_SCOPE_CLUSTER_CTX} -n store-out-of-scope apply -f ${APP_DIR}/cluster/out-of-scope/namespaces/store-out-of-scope