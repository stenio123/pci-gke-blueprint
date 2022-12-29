# Source: https://cloud.google.com/service-mesh/docs/onlineboutique-install-kpt#managed-service-mesh

gcloud components install kpt
kpt pkg get \
  https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/samples/online-boutique \
  online-boutique

cd online-boutique

kubectl apply -f kubernetes-manifests/namespaces

kubectl apply -f kubernetes-manifests/deployments

kubectl apply -f kubernetes-manifests/services

kubectl apply -f istio-manifests/allow-egress-googleapis.yaml

# "stable" should match the channel used when you installed asm cli
for ns in ad cart checkout currency email frontend loadgenerator \
  payment product-catalog recommendation shipping; do
    kubectl label namespace $ns istio.io/rev=stable --overwrite
done;

# Not using managed dataspace, otherwise would use:
#for ns in ad cart checkout currency email frontend loadgenerator \
#  payment product-catalog recommendation shipping; do
#    kubectl annotate --overwrite namespace $ns mesh.cloud.google.com/proxy='{"managed":"true"}'
#done;

# restart pods
for ns in ad cart checkout currency email frontend loadgenerator \
  payment product-catalog recommendation shipping; do
    kubectl rollout restart deployment -n ${ns}
done;

# Exposing and accessing the application
## TODO - review - need to install ingress gateway, this is a quick fix
istioctl install --set profile=demo
kubectl apply -f istio-manifests/frontend-gateway.yaml

# Get endpoint
kubectl get service istio-ingressgateway  -n istio-system

# Visit application
# http://EXTERNAL_IP/