#!/bin/bash
set -eu

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
NAMESPACE_ARGOCD="argocd"
NAMESPACE_DEV="dev"
CLUSTER_NAME="p3-cluster"
ARGOCD_NEW_PWD="daumis123"

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

# ArgoCD portforwarding to access GUI
echo "ArgoCD portforwarding to access GUI .."
kubectl port-forward -n "$NAMESPACE_ARGOCD" svc/argocd-server 8080:443 &
sleep 10 # Wait for service to be ready

# Get machine IP and login to ArgoCD
ARGOCD_URL="localhost:8080"

echo "--------------- Logging into ArgoCD ... ---------------"
# Fetch password
ARGOCD_PWD=$(kubectl -n "$NAMESPACE_ARGOCD" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)

if ! argocd login "$ARGOCD_URL" --username admin --password "$ARGOCD_NEW_PWD" --insecure &>/dev/null; then
    echo "Updating ArgoCD password..."
    # Login with the initial password
    argocd login "$ARGOCD_URL" --username admin --password "$ARGOCD_PWD" --insecure
    # Update to the new password
    argocd account update-password --account admin \
        --current-password "$ARGOCD_PWD" \
        --new-password "$ARGOCD_NEW_PWD"
    echo "✅ ArgoCD password updated."
else
    echo "ArgoCD password already set to $ARGOCD_NEW_PWD."
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
ARGO_APP_YAML="$(realpath "$(dirname "$0")/../confs/argo-app.yaml")"

# Vérifie que le fichier existe avant de l'appliquer
if [ -f "$ARGO_APP_YAML" ]; then
    echo "--------------- Applying YAML files... ---------------"
    kubectl apply -f "$ARGO_APP_YAML"
else
    echo "❌ File not found: $ARGO_APP_YAML"
fi

echo -e "✅ Setup Complete\n\n\n"
echo -e "${GREEN}=============================================${NC}"
echo -e "${CYAN}${BOLD} ArgoCD is running at: https://$ARGOCD_URL ${NC}"
echo -e "${CYAN} Username:${NC} admin"
echo -e "${CYAN} Password:${NC} $ARGOCD_NEW_PWD"
echo -e "${GREEN}=============================================${NC}"