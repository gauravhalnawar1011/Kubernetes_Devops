
---

# 🚀 Day-60: ArgoCD Setup & Installation (UI + CLI) using Kind, Helm & kubectl

This guide explains how to **set up and install ArgoCD step-by-step using a Kind Kubernetes cluster**, including:

* ✅ Cluster creation using **Kind**
* ✅ ArgoCD installation using **Helm (production-style)**
* ✅ ArgoCD installation using **official manifests**
* ✅ ArgoCD **UI & CLI access**
* ✅ Official tool installation links
* ✅ Best practices used in real-world DevOps teams

---

## 📌 What is ArgoCD?

**ArgoCD** is a **declarative, GitOps continuous delivery tool for Kubernetes**.

It:

* Pulls application manifests from Git
* Syncs them automatically to Kubernetes
* Provides a powerful UI & CLI for deployments
* Enforces Git as the **single source of truth**

Official Website:
🔗 [https://argo-cd.readthedocs.io/](https://argo-cd.readthedocs.io/)

---

# ✅ Prerequisites (With Official Links)

Before starting, you must install the following tools:

---

## 1️⃣ Docker (Required for Kind)

Kind runs Kubernetes nodes as Docker containers.

### ✅ Install Docker (Ubuntu)

```bash
sudo apt-get update
sudo apt install docker.io -y
sudo usermod -aG docker $USER && newgrp docker
docker --version
```

🔗 Official Docker Install Guide:
[https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

---

## 2️⃣ Kind (Kubernetes in Docker)

Used to create a local Kubernetes cluster inside Docker.

### ✅ Install Kind

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv kind /usr/local/bin/
kind version
```

🔗 Official Kind Install Guide:
[https://kind.sigs.k8s.io/docs/user/quick-start/#installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

---

## 3️⃣ kubectl (Kubernetes CLI)

Used to interact with the Kubernetes API server.

### ✅ Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

🔗 Official kubectl Install Guide:
[https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

---

## 4️⃣ Helm (Kubernetes Package Manager)

Used to install ArgoCD in a production-grade way.

### ✅ Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

🔗 Official Helm Install Guide:
[https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)

---

# ⚠️ Important Note (For EC2 Users)

> If you are running Kind on an EC2 instance, you **must replace the private IP address** in the cluster config:
>
> Replace `172.31.19.178` with your EC2 private IP:
>
> ```bash
> hostname -I
> ```

---

# 🟢 Step 1: Create Kind Cluster

Create the file **`kind-config.yaml`**

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "172.31.19.178"
  apiServerPort: 33893
nodes:
  - role: control-plane
    image: kindest/node:v1.33.1
  - role: worker
    image: kindest/node:v1.33.1
  - role: worker
    image: kindest/node:v1.33.1
```

### ✅ Create the cluster

```bash
kind create cluster --name argocd-cluster --config kind-config.yaml
```

### ✅ Verify cluster

```bash
kubectl cluster-info
kubectl get nodes
```

---

# 🟢 Step 2: Install ArgoCD

We support **two professional methods**:

| Method   | Use Case         |
| -------- | ---------------- |
| Helm     | Production-grade |
| Manifest | Learning / Labs  |

---

## 🔵 Method 1: Install ArgoCD Using Helm (Recommended)

### 1️⃣ Add Helm Repo

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### 2️⃣ Create Namespace

```bash
kubectl create namespace argocd
```

### 3️⃣ Install ArgoCD

```bash
helm install argocd argo/argo-cd -n argocd
```

### 4️⃣ Verify Installation

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### 5️⃣ Expose ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0 &
```

Access in browser:

```
https://<INSTANCE_PUBLIC_IP>:8080
```

### 6️⃣ Get Admin Password

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
-o jsonpath="{.data.password}" | base64 -d && echo
```

Login:

* Username: `admin`
* Password: (output above)

---

## 🔵 Method 2: Install Using Official Kubernetes Manifest

### 1️⃣ Create Namespace

```bash
kubectl create namespace argocd
```

### 2️⃣ Apply Official Manifest

```bash
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 3️⃣ Verify Installation

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### 4️⃣ Expose ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0 &
```

---

# 🟢 Step 3: Install ArgoCD CLI (argocd)

The CLI allows you to manage ArgoCD from the terminal.

### ✅ Install CLI

```bash
curl -sSL -o argocd-linux-amd64 \
https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### ✅ Verify CLI

```bash
argocd version --client
```

---

# 🟢 Step 4: Login to ArgoCD Using CLI

```bash
argocd login <INSTANCE_PUBLIC_IP>:8080 \
--username admin \
--password <INITIAL_PASSWORD> \
--insecure
```

```bash
argocd account get-user-info
```

---

# ⚔️ Helm vs Manifest Comparison

| Feature          | Helm   | Manifest |
| ---------------- | ------ | -------- |
| Customization    | ✅ High | ❌ Low    |
| Upgrades         | ✅ Easy | ❌ Manual |
| Production Ready | ✅ Yes  | ❌ No     |
| Learning Labs    | ✅      | ✅        |

---

# ✅ Professional Best Practices

* Always use **Helm for production**
* Never install ArgoCD in `default` namespace
* Protect ArgoCD using:

  * TLS
  * RBAC
  * SSO (OIDC)
* Store Kubernetes **Applications in Git**
* Use **App-of-Apps pattern** for scaling GitOps
* Keep **ArgoCD versions updated**

---
