#!/bin/bash
set -e

echo "Creating namespace for Argo Rollouts..."
kubectl create namespace argo-rollouts || echo "Namespace argo-rollouts already exists"

echo "Installing Argo Rollouts controller..."
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

echo "Downloading kubectl-argo-rollouts plugin..."
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64

echo "Installing kubectl-argo-rollouts plugin..."
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

echo "Installation completed successfully."
