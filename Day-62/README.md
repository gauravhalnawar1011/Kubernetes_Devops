
---

# 🚀 Day-62: Multi-Cluster Hub–Spoke Architecture Using Amazon EKS & ArgoCD

This project demonstrates a **real-world GitOps-based multi-cluster Kubernetes deployment** using:

* **Amazon EKS**
* **ArgoCD**
* **Hub–Spoke Architecture**
* **Multi-Region Setup**
* **NodePort-based UI Access (for demo only)**

The goal of this project is to show how **one central ArgoCD (Hub) can manage multiple Kubernetes clusters (Spokes)** using GitOps.

---

## 🧱 Architecture Overview

* **Hub Cluster:**
  Hosts ArgoCD and manages all GitOps deployments.

* **Spoke-1 Cluster:**
  Application deployment target (Same region – `ap-south-1`).

* **Spoke-2 Cluster:**
  Application deployment target (Different region – `us-east-1`).

---

## ✅ Prerequisites

Before starting, make sure the following tools are installed:

```bash
aws --version
kubectl version --client
helm version
eksctl version
```
<img width="1845" height="729" alt="Image" src="https://github.com/user-attachments/assets/c3cd255c-8344-4faf-96cc-71f8acc9b3a9" />

### Required Tools

* AWS CLI
* kubectl
* Helm
* eksctl

---

## ⚙️ Step 1: Create EKS Clusters Using eksctl

### ✅ Hub Cluster (ap-south-1)

```bash
eksctl create cluster \
  --name hub-cluster \
  --region ap-south-1 \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 2 \
  --managed
```

---

### ✅ Spoke-1 Cluster (Same Region – ap-south-1)

```bash
eksctl create cluster \
  --name spoke1-cluster \
  --region ap-south-1 \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 2 \
  --managed
```

---

### ✅ Spoke-2 Cluster (Different Region – us-east-1)

```bash
eksctl create cluster \
  --name spoke2-cluster \
  --region us-east-1 \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 2 \
  --managed
```

---

## 🔄 Step 2: Verify and Switch kubectl Context

```bash
kubectl config get-contexts
```

Switch to Hub Cluster:

```bash
kubectl config use-context hub-cluster.ap-south-1.eksctl.io
```

Verify Nodes:

```bash
kubectl get nodes
```

---

## 🚀 Step 3: Install ArgoCD on Hub Cluster Using Helm

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

Create Namespace:

```bash
kubectl create namespace argocd
```

Install ArgoCD:

```bash
helm install argocd argo/argo-cd -n argocd
```

Verify Installation:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

---

## 🌐 Step 4: Expose ArgoCD UI Using NodePort (Demo Only)

Edit Service:

```bash
kubectl edit svc argocd-server -n argocd
```

Change:

```yaml
type: ClusterIP
```

To:

```yaml
type: NodePort
```

Get NodePort:

```bash
kubectl get svc -n argocd
```

Get Worker Node IP:

```bash
kubectl get nodes -o wide
```

Access UI:

```text
http://<Worker-Node-Public-IP>:<NodePort>
```

---

## 🔐 Step 5: Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d && echo
```

Login Credentials:

* **Username:** `admin`
* **Password:** Output from command above

---

## 🔗 Step 6: Install ArgoCD CLI & Login

Install CLI:

```bash
curl -sSL -o argocd-linux-amd64 \
https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Login to ArgoCD:

```bash
argocd login <Node-IP>:<NodePort>
```

---

## 🔄 Step 7: Register Spoke Clusters in ArgoCD

```bash
argocd cluster add spoke1-cluster --server <argo-server-ip>:<nodeport>
argocd cluster add spoke2-cluster --server <argo-server-ip>:<nodeport>
```

✅ Clusters will now be visible in ArgoCD UI.

---

## 📦 Step 8: Deploy Sample Guestbook App Using GitOps

### ✅ Deployment YAML

**Path:** `Day-62/manifests/guest-book/guestbook-ui-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook-ui
spec:
  replicas: 1
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: guestbook-ui
  template:
    metadata:
      labels:
        app: guestbook-ui
    spec:
      containers:
      - image: gcr.io/google-samples/gb-frontend:v5
        name: guestbook-ui
        ports:
        - containerPort: 80
```

---

### ✅ Service YAML

**Path:** `Day-62/manifests/guest-book/guestbook-ui-svc.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: guestbook-ui
```

---

## 🧩 Step 9: Create ArgoCD Application (Via UI)

For each cluster:

You must provide:

* Application Name
* Project Name (default)
* Repository URL
* Path to Manifest Folder
* Target Cluster
* Target Namespace

> ⚠️ One ArgoCD Application is required **per cluster**.

---

## ✅ Step 10: Verify Deployment

Switch to target cluster:

```bash
kubectl config use-context spoke1-cluster
kubectl get deploy
```

Repeat for `spoke2-cluster`.

---

## 🧹 Cleanup (To Avoid AWS Charges)

```bash
eksctl delete cluster --region ap-south-1 --name spoke1-cluster
eksctl delete cluster --region ap-south-1 --name hub-cluster
eksctl delete cluster --region us-east-1 --name spoke2-cluster
```

---



```md
## 📸 Screenshots


### ✅ ArgoCD Dashboard
<img width="1764" height="1009" alt="Image" src="https://github.com/user-attachments/assets/b842e635-f192-4811-a545-585bb9dc52da" />

### ✅ Application Synced
<img width="1764" height="1009" alt="Image" src="https://github.com/user-attachments/assets/e2dee0c1-7cb0-41be-9ef5-87d65621ad09" />

### ✅ Guestbook App Running
<img width="1857" height="473" alt="Image" src="https://github.com/user-attachments/assets/b4740a9b-a688-4088-bcf2-50fdebcc09ca" />
```

---

## 🎯 Key Learning Outcomes

* Multi-cluster EKS setup
* Hub–Spoke GitOps architecture
* ArgoCD installation with Helm
* Cluster registration using ArgoCD CLI
* GitOps-based application delivery
* Multi-region Kubernetes management

---


