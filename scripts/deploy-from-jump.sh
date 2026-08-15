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

echo "9. Check existing Helm release"

if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then

    echo "Helm release '${RELEASE_NAME}' already exists."
    echo "Existing deployment will be upgraded."

else

    echo "Helm release '${RELEASE_NAME}' does not exist."

    if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
        echo "Old namespace '${NAMESPACE}' exists."
        echo "Deleting namespace created outside Helm..."

        kubectl delete namespace "${NAMESPACE}" --wait=true

        echo "Old namespace deleted."
    fi

fi

echo "10. Deploy Boutique using Helm"

helm upgrade --install "${RELEASE_NAME}" \
  ./boutique \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --wait \
  --timeout 10m

echo "11. Check Helm release"

helm list -n "${NAMESPACE}"

echo "12. Check pods"

kubectl get pods -n "${NAMESPACE}" -o wide

echo "13. Check services"

kubectl get svc -n "${NAMESPACE}"

echo "14. Check ingress"

kubectl get ingress -n "${NAMESPACE}" || true

echo "========================================"
echo "Boutique deployment completed"
echo "========================================"