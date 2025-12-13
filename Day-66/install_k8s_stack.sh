#!/usr/bin/env bash
set -e

echo "=== Updating system and installing Nginx + Certbot ==="
sudo apt update -y
sudo apt install -y nginx certbot python3-certbot-nginx curl wget apt-transport-https ca-certificates gnupg lsb-release

echo "=== Installing Docker (optional, not required by K3s) ==="
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "=== Installing K3s (Traefik disabled) ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sudo sh -

echo "=== Fixing kubeconfig for ubuntu user ==="
mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
sudo chmod 600 /home/ubuntu/.kube/config
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

echo "=== Validating K3s Install ==="
kubectl get nodes
kubectl get pods -A

echo "=== Creating Argo CD Namespace ==="
kubectl create ns argocd || true

echo "=== Installing Argo CD ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== All components installed successfully ==="
kubectl get pods -n argocd
