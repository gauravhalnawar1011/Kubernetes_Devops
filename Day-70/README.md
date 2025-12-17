
---

# Day 70 – Blue-Green Deployment Strategy with Argo Rollouts (Hands-On)

## Overview

This repository demonstrates a **Blue-Green deployment strategy** using **Argo Rollouts**, **Kubernetes**, and **NGINX Ingress**.

Blue-Green deployment allows you to deploy a new version of an application alongside the existing version and switch traffic instantly with **zero downtime**. Argo Rollouts provides advanced deployment strategies beyond standard Kubernetes Deployments, such as **Blue-Green** and **Canary**.

This hands-on example uses:

* A **single Docker image**
* Version switching via **environment variables**
* Traffic control using **Active** and **Preview** services
* Manual promotion using Argo Rollouts

---

## How Argo Rollouts Works

Argo Rollouts introduces a new Kubernetes resource called **`Rollout`**, which is an alternative to the standard `Deployment`.

Key points:

* The **Argo Rollouts controller** manages the creation, scaling, and deletion of **ReplicaSets**
* ReplicaSets are derived from the `spec.template` section of the Rollout (same concept as Deployments)
* Any change under `spec.template` triggers a **new ReplicaSet**

Examples of changes that create a new ReplicaSet:

* Image name or tag change
* Environment variable change
* Container configuration change

---

## Blue-Green Strategy Explained

In a **Blue-Green strategy**, two Kubernetes Services are used:

| Service             | Purpose                               |
| ------------------- | ------------------------------------- |
| **Active Service**  | Serves production traffic             |
| **Preview Service** | Serves the new version for validation |

### Traffic Flow Logic

1. **Initial State (Blue / v1)**

   * Active Service → ReplicaSet v1
   * Preview Service → ReplicaSet v1

2. **New Version Introduced (Green / v2)**

   * A new ReplicaSet is created
   * Preview Service → ReplicaSet v2
   * Active Service → ReplicaSet v1

3. **Promotion**

   * Active Service is switched to ReplicaSet v2
   * Old ReplicaSet is scaled down

### How Argo Rollouts Handles Routing

Argo Rollouts automatically:

* Adds a `pod-template-hash` label to ReplicaSets
* Modifies Service selectors internally
* Ensures:

  * Active Service points to the **stable ReplicaSet**
  * Preview Service points to the **new ReplicaSet**

This traffic switching is handled entirely by the controller—no manual Service edits required.

---

## Repository Structure

```text
.
├── ingress.yaml
├── rollout.yaml
├── svc.yaml
└── README.md
```

---

## Prerequisites

* Kubernetes cluster (Killercoda recommended)
* `kubectl` configured
* Docker image pushed to Docker Hub
* Internet access (to install controllers)

---

## Step 1: Install Argo Rollouts Controller

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

Verify:

```bash
kubectl get pods -n argo-rollouts
```

---

## Step 2: Install kubectl Argo Rollouts Plugin

```bash
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

Verify:

```bash
kubectl argo rollouts version
```

---

## Step 3: Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

Wait until it is ready:

```bash
kubectl get pods -n ingress-nginx
```

---

## Step 4: Create Application Namespace

```bash
kubectl create namespace blue-green
```

---

## Step 5: Rollout Configuration (`rollout.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: blue-green-deployment
  namespace: blue-green
spec:
  replicas: 4
  selector:
    matchLabels:
      app: blue-green-deployment
  template:
    metadata:
      labels:
        app: blue-green-deployment
    spec:
      containers:
      - name: blue-green
        image: gauravhalnawar2705/blue-green-deployment:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 5000
        env:
        - name: html_name
          value: "app-v1.html"
  strategy:
    blueGreen:
      activeService: rollout-bluegreen-active
      previewService: rollout-bluegreen-preview
      autoPromotionEnabled: false
```

---

## Step 6: Services Configuration (`svc.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-bluegreen-active
  namespace: blue-green
spec:
  selector:
    app: blue-green-deployment
  ports:
  - port: 5000
    targetPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: rollout-bluegreen-preview
  namespace: blue-green
spec:
  selector:
    app: blue-green-deployment
  ports:
  - port: 5000
    targetPort: 5000
```

---

## Step 7: Ingress Configuration (`ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: blue-green-ingress
  namespace: blue-green
spec:
  ingressClassName: nginx
  rules:
  - host: blue-green.demo
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: rollout-bluegreen-active
            port:
              number: 5000
```

---

## Step 8: Apply All Manifests

```bash
kubectl apply -f svc.yaml
kubectl apply -f rollout.yaml
kubectl apply -f ingress.yaml
```

Verify:

```bash
kubectl get pods -n blue-green
kubectl get endpoints -n blue-green
kubectl get svc -n ingress-nginx
```

---

## Step 9: Access the Application (NodePort)

Get the NodePort:

```bash
kubectl get svc -n ingress-nginx
```

Example:

```text
80:31602/TCP
```

Test:

```bash
curl -H "Host: blue-green.demo" http://127.0.0.1:31602
```

You should see **Version 1 (Blue)**.

---

## Step 10: Deploy Version 2 (Green)

Update `rollout.yaml`:

```yaml
env:
- name: html_name
  value: "app-v2.html"
```

Apply:

```bash
kubectl apply -f rollout.yaml
```

At this stage:

* Preview Service → Version 2
* Active Service → Version 1

---

## Step 11: Promote Green to Active

```bash
kubectl argo rollouts promote blue-green-deployment -n blue-green
```

Verify:

```bash
curl -H "Host: blue-green.demo" http://127.0.0.1:31602
```

You should now see **Version 2 (Green)**.

---

## Rollouts Dashboard (Optional)

```bash
kubectl argo rollouts dashboard
```

Expose port **3100** using the Killercoda port preview to view the UI.

---

## Key Takeaways

* Argo Rollouts extends Kubernetes Deployments
* Blue-Green uses **Active** and **Preview** services
* Traffic switching is handled via **service selector manipulation**
* No downtime during promotion
* One image, multiple versions via configuration

---

## References

* [https://argo-rollouts.readthedocs.io](https://argo-rollouts.readthedocs.io)
* [https://kubernetes.github.io/ingress-nginx/](https://kubernetes.github.io/ingress-nginx/)
* [https://killercoda.com](https://killercoda.com)

---


