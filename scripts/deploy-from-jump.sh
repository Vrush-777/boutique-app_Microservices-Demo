#!/bin/bash

set -e

echo "========================================"
echo "Starting Boutique deployment"
echo "========================================"

RESOURCE_GROUP="rg-devsecops-poc"
AKS_NAME="aks-boutique-dev"
ACR_NAME="vrushacr777"
NAMESPACE="boutique"
RELEASE_NAME="boutique"
CHART_PATH="/opt/deploy/boutique"

# IMAGE_TAG is passed from GitHub Actions.
# Example:
# IMAGE_TAG=a19067...
IMAGE_TAG="${IMAGE_TAG:-}"

if [ -z "${IMAGE_TAG}" ]; then
    echo "ERROR: IMAGE_TAG is not set."
    exit 1
fi

echo "Using image tag: ${IMAGE_TAG}"

echo "1. Login to Azure using Jump VM Managed Identity"

az login --identity --allow-no-subscriptions

echo "2. Set Azure subscription"

az account set --subscription "${AZURE_SUBSCRIPTION_ID}"

echo "3. Verify Azure identity"

az account show \
  --query "{name:name,id:id,tenantId:tenantId}" \
  -o table

echo "4. Get AKS credentials"

az aks get-credentials \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AKS_NAME}" \
  --overwrite-existing

echo "5. Configure kubelogin"

kubelogin convert-kubeconfig -l azurecli

echo "6. Verify AKS access"

kubectl get nodes

echo "7. Verify ACR access"

az acr repository list \
  --name "${ACR_NAME}" \
  --output table

echo "8. Verify Helm"

helm version

echo "9. Verify Helm chart"

test -f "${CHART_PATH}/Chart.yaml"

echo "Helm chart found:"
ls -la "${CHART_PATH}"

echo "10. Verify namespace"

if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    echo "Namespace '${NAMESPACE}' already exists."
else
    echo "Creating namespace '${NAMESPACE}'."
    kubectl create namespace "${NAMESPACE}"
fi

echo "11. Deploy Boutique using Helm"

cd "${CHART_PATH}"

helm upgrade --install "${RELEASE_NAME}" . \
  --namespace "${NAMESPACE}" \
  --set image.tag="${IMAGE_TAG}" \
  --set redis.tag="${IMAGE_TAG}" \
  --wait \
  --timeout 10m

echo "12. Check Helm release"

helm list -n "${NAMESPACE}"

echo "13. Check pods"

kubectl get pods \
  -n "${NAMESPACE}" \
  -o wide

echo "14. Check services"

kubectl get svc \
  -n "${NAMESPACE}"

echo "15. Check HPA"

kubectl get hpa \
  -n "${NAMESPACE}" || true

echo "16. Check ingress"

kubectl get ingress \
  -n "${NAMESPACE}" || true

echo "========================================"
echo "Boutique deployment completed"
echo "========================================"