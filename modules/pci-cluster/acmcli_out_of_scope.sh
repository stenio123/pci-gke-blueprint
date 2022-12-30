# Deploys the asm cli tool used for the online boutique
# source: https://cloud.google.com/service-mesh/docs/managed/provision-managed-anthos-service-mesh-asmcli

curl https://storage.googleapis.com/csm-artifacts/asm/asmcli > asmcli

chmod +x asmcli

# Check notes on VPC Service control and other for additional flags
  ./asmcli install \
      -p pci-refresh-test-7c56 \
      -l us-central1 \
      -n out-of-scope \
      --fleet_id pci-refresh-test-7c56 \
      --managed \
      --verbose \
      --output_dir out-of-scope \
      --enable-all \
      --channel regular \
      --option legacy-default-ingressgateway

# To check
kubectl describe controlplanerevision asm-managed-regular -n istio-system

./asmcli validate \
  --project_id pci-refresh-test-7c56 \
  --cluster_name out-of-scope \
  --cluster_location us-central1 \
  --fleet_id pci-refresh-test-7c56
# TODO Error!
# asmcli: [ERROR]: Autopilot clusters are only supported with managed control plane.