#!/bin/bash
set -euo pipefail

NAMESPACE_ARGOCD="argocd"
NAMESPACE_DEV="dev"
CLUSTER_NAME="p3_cluster"
ARGO_NEW_PWD="daumis123"

# Create k3d cluster (only if missing)

if ! k3d cluster list | grep -q "^$CLUSTER_NAME\b"; then
    echo "--------------- Creating k3d cluster... ---------------"
    k3d cluster create "$CLUSTER_NAME" --servers 1
else
    echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
fi

# Install ArgoCD (if not installed)

if ! kubectl get namespace "$NAMESPACE_ARGOCD" &>/dev/null; then
    echo "--------------- Creating namespace: $NAMESPACE_ARGOCD ---------------"
    kubectl create namespace "$NAMESPACE_ARGOCD"
else
    echo "Namespace '$NAMESPACE_ARGOCD' already exists."
fi

if ! kubectl get deployment -n "$NAMESPACE_ARGOCD" argocd-server &>/dev/null; then
    echo "--------------- Installing ArgoCD... ---------------"
    kubectl apply -n "$NAMESPACE_ARGOCD" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    echo "Waiting for ArgoCD server to be ready..."
    kubectl wait --for=condition=Available --timeout=600s deployment/argocd-server -n "$NAMESPACE_ARGOCD"
else
    echo "ArgoCD is already installed."
fi

# Install ArgoCD CLI (if missing)

if ! command -v argocd &> /dev/null; then
    echo "--------------- Installing ArgoCD CLI... ---------------"
    curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    chmod +x argocd-linux-amd64
    sudo mv argocd-linux-amd64 /usr/local/bin/argocd
else
    echo "ArgoCD CLI already installed."
fi

# Login to ArgoCD and update password (if not already set)

echo "--------------- Checking ArgoCD password... ---------------"
CURRENT_PWD=$(kubectl -n "$NAMESPACE_ARGOCD" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "")

# Expose ArgoCD using NodePort if not already exposed
echo "Ensuring ArgoCD is exposed with NodePort..."
CURRENT_TYPE=$(kubectl get svc argocd-server -n "$NAMESPACE_ARGOCD" -o jsonpath='{.spec.type}' 2>/dev/null || echo "")

if [ "$CURRENT_TYPE" != "NodePort" ]; then
    kubectl patch svc argocd-server -n "$NAMESPACE_ARGOCD" \
      -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30080}]}}'
    echo "ArgoCD service patched to NodePort."
else
    echo "ArgoCD service is already NodePort."
fi

# Wait for service to be ready
sleep 5

# Get machine IP and login to ArgoCD
ARGOCD_URL="https://$(hostname -I | awk '{print $1}'):30080"
argocd login "$ARGOCD_URL" --username admin --password "$ARGOCD_PWD" --insecure

# Change password only if not already set
if ! argocd account get-user-info --server "$ARGOCD_URL" --insecure 2>&1 | grep -q "admin123"; then
    argocd account update-password --account admin \
      --current-password "$ARGOCD_PWD" --new-password "admin123"
    echo "ArgoCD password updated."
else
    echo "ArgoCD password already set to admin123."
fi

# Create dev namespace

if ! kubectl get namespace "$NAMESPACE_DEV" &>/dev/null; then
    echo "Creating namespace: $NAMESPACE_DEV"
    kubectl create namespace "$NAMESPACE_DEV"
else
    echo "Namespace '$NAMESPACE_DEV' already exists."
fi

# Apply YAML manifests

echo "--------------- Applying YAML files... ---------------"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$BASE_DIR/conf/deployment.yaml"
kubectl apply -f "$BASE_DIR/conf/service.yaml"
kubectl apply -f "$BASE_DIR/conf/argo-application.yaml"

echo "✅ Everything is setup! Success!"
