#!/bin/bash

set -e

echo "========================================"
echo "Starting Boutique deployment"
echo "========================================"

RESOURCE_GROUP="rg-devsecops-poc"
AKS_NAME="aks-boutique-dev"
ACR_NAME="vrushacr777"
NAMESPACE="boutique"

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

az acr show \
  --name "${ACR_NAME}" \
  --query "{name:name, loginServer:loginServer}" \
  --output table

echo "8. Verify ACR repositories"

az acr repository list \
  --name "${ACR_NAME}" \
  --output table

echo "9. Create Boutique namespace"

kubectl create namespace "${NAMESPACE}" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo "10. Deploy Boutique using Helm"

helm upgrade --install boutique \
  ./boutique-helm/boutique \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --wait \
  --timeout 10m

echo "11. Check Helm release"

helm list -n "${NAMESPACE}"

echo "12. Check pods"

kubectl get pods -n "${NAMESPACE}"

echo "13. Check services"

kubectl get svc -n "${NAMESPACE}"

echo "========================================"
echo "Boutique deployment completed"
echo "========================================"