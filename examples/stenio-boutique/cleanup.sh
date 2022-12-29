# Cleanup script to destroy Online Boutique
# Source https://cloud.google.com/service-mesh/docs/onlineboutique-install-kpt#using-ingress-gateway

kubectl delete -f kubernetes-manifests/namespaces
kubectl delete -f istio-manifests/allow-egress-googleapis.yaml