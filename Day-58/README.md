
---

# 🚀 Argo CD Installation & Component Deep-Dive

A clean and comprehensive guide to installing Argo CD on a local Kubernetes cluster (Kind, Minikube, or kubeadm) and understanding its architecture.

---

## 📌 Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Creating a Kubernetes Cluster With Kind](#creating-a-kubernetes-cluster-with-kind)
4. [Installing Argo CD](#installing-argo-cd)
5. [Understanding Argo CD Components](#understanding-argo-cd-components)
6. [Exposing the Argo CD UI](#exposing-the-argo-cd-ui)
7. [Accessing Argo CD Web UI](#accessing-argo-cd-web-ui)
8. [Deploying an Application Using Argo CD UI](#deploying-an-application-using-argo-cd-ui)
9. [Using Helm and Kustomize With Argo CD](#using-helm-and-kustomize-with-argo-cd)
10. [Installing and Using Argo CD CLI](#installing-and-using-argo-cd-cli)
11. [Useful References](#useful-references)

---

## 🧭 Introduction

**Argo CD** is a declarative GitOps continuous delivery tool for Kubernetes.
It monitors your Git repository and ensures your Kubernetes cluster matches the declared state.

This guide walks you through:

* Installing Argo CD
* Understanding every internal component
* Accessing the UI
* Deploying apps (Helm, Kustomize, plain YAML)
* Using the Argo CD CLI

---

## 🔧 Prerequisites

You should have:

* Docker installed
* `kubectl` installed
* Basic understanding of Kubernetes
* Optional: Helm installed

---

## 🏗️ Creating a Kubernetes Cluster with Kind

### **Cluster Config (`config.yaml`)**

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true

nodes:
  - role: control-plane
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          name: mycluster-app-1
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          name: mycluster-app-2
```

### **Create the cluster**

```bash
kind create cluster --name space9-v2 \
  --image kindest/node:v1.33.4 --config config.yaml

kubectl get nodes
```

---

## 🚀 Installing Argo CD

### **Create a namespace**

```bash
kubectl create namespace argocd
```

### **Install Argo CD**

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

This installs:

* CRDs
* Deployments
* Services
* Secrets
* RBAC
* ConfigMaps

You can verify:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

---

# 🧩 Understanding Argo CD Components

Argo CD deploys multiple core components. Below is an explanation of **what each one does and why it matters.**

---

### ### **1. Argo CD API Server (`argocd-server`)**

* Provides **UI**, **CLI**, and **REST API**
* Handles authentication, RBAC, SSO (via Dex)
* Converts Git data → Kubernetes manifests (delegates to repo-server)

**Why it matters:**
It’s the primary entry point for users. Without it, you cannot manage applications.

---

### **2. Argo CD Repository Server (`argocd-repo-server`)**

* Clones Git repositories
* Renders manifests using:

  * **Helm**
  * **Kustomize**
  * **Plain YAML**
* Responds to API server with final manifests

**Why it matters:**
This is the “brains” that converts Git into deployable manifests.

---

### **3. Argo CD Application Controller (`argocd-application-controller`)**

* Continuously watches:

  * Desired state (Git)
  * Live state (Cluster)
* Performs reconciliation:

  * Sync
  * Prune
  * Health checks

**Why it matters:**
It is the **GitOps engine** that ensures cluster = Git.

---

### **4. Argo CD ApplicationSet Controller**

* Enables **mass-generation of applications**
* Useful when deploying to many clusters (10–500+)
* Uses “generators” (matrix, list, clusters, Git dirs)

**Why it matters:**
It automates multi-cluster GitOps at scale.

---

### **5. Argo CD Dex Server**

* Handles SSO integrations:

  * GitHub
  * Google
  * LDAP
  * OIDC

**Why it matters:**
Enterprise-grade authentication.

---

### **6. Argo CD Notifications Controller**

* Sends notifications:

  * Slack
  * Email
  * Webhooks
  * Microsoft Teams

**Why it matters:**
Keeps teams updated about sync status or failures.

---

### **7. Redis**

* Used as in-memory storage cache
* Speeds up Argo CD API responses

**Why it matters:**
Performance optimization.

---

# 🌐 Exposing the Argo CD UI

Argo CD server is a `ClusterIP` by default.
To expose it outside, change it to `NodePort`:

```bash
kubectl edit svc argocd-server -n argocd
```

Modify:

```yaml
type: NodePort
```

Then check again:

```bash
kubectl get svc -n argocd
```

---

# 🔑 Accessing Argo CD Web UI

### **Find the node running argocd-server**

```bash
kubectl get pods -n argocd -o wide
```

### **Find the node IP**

```bash
kubectl get nodes -o wide
```

### **Access UI**

```
http://<NODE_IP>:<NODE_PORT>
```

---

## 🧍 Default Credentials

### **Get initial admin password**

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
```

Decode:

```bash
echo <encoded-password> | base64 --decode
```

Login:

* **Username:** `admin`
* **Password:** `<decoded-password>`

---

# 📦 Deploying an Application Using Argo CD UI

Use the example apps:

```
https://github.com/argoproj/argocd-example-apps
```

Typical steps:

1. Click **New Application**
2. Enter name, project, and sync policy
3. Git repo URL:

   ```
   https://github.com/argoproj/argocd-example-apps
   ```
4. Path:

   ```
   guestbook
   ```
5. Destination:

   * Cluster: in-cluster URL
   * Namespace: default
6. Click **Create**

Argo CD will:

* Pull manifests
* Apply them to cluster
* Maintain desired state

---

# 🎛️ Using Helm & Kustomize in Argo CD

Argo CD is **not opinionated**—it supports:

* Helm
* Kustomize
* Jsonnet
* Plain YAML

When creating an app:

* For Helm, specify `values.yaml` overrides.
* For Kustomize, point to directory with `kustomization.yaml`.

---

# 🖥️ Installing & Using Argo CD CLI

### **Download CLI (Linux AMD64 example)**

```bash
uname -m   # should be x86_64

curl -L -o argocd \
https://github.com/argoproj/argo-cd/releases/download/v3.2.1/argocd-linux-amd64

chmod +x argocd
sudo mv argocd /usr/local/bin/
```

Verify:

```bash
argocd version --client
```

### **Login via CLI**

```bash
argocd login <ARGOCD_SERVER_NODE_IP>:<NODE_PORT>
```

### **Create an app via CLI**

Documentation:
[https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_app_create/](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_app_create/)

---

# 📘 Useful References

* Argo CD Getting Started
  [https://argo-cd.readthedocs.io/en/stable/getting_started/](https://argo-cd.readthedocs.io/en/stable/getting_started/)

* Example Applications
  [https://github.com/argoproj/argocd-example-apps](https://github.com/argoproj/argocd-example-apps)

* Argo CD CLI Docs
  [https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd/](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd/)

* Helm Chart Installation
  [https://github.com/argoproj/argo-helm](https://github.com/argoproj/argo-helm)

---



