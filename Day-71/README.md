
---

# Canary Deployment Strategy in Kubernetes (Argo Rollouts)

This repository demonstrates **Canary deployment strategies in Kubernetes** using **Argo Rollouts**.
It focuses on **Rolling Update–based Canary deployments**, explaining how traffic is gradually shifted from an old version of an application to a new one with controlled risk.

---

## 📌 What Is a Canary Deployment?

A **Canary deployment** exposes a **subset of users** to a new version of an application while the remaining traffic continues to be served by the stable version. Once the new version is validated, it progressively replaces the old version.

### Benefits

* Reduced deployment risk
* Controlled rollouts
* Faster rollback in case of failure
* Improved production confidence

---

## 🧭 Canary Deployment Strategies Covered

This repository covers **three primary ways** to implement Canary deployments:

1. **Rolling Update (Primary Focus)**
2. **SetWeight with Argo Rollouts**
3. **Traffic Management (Traffic Routing)**

> This repository mainly focuses on **Rolling Update–based Canary deployments** using Argo Rollouts.

---

## 🔄 Canary Strategy Using Rolling Update

Kubernetes supports Rolling Updates natively, and **Argo Rollouts extends this functionality** under the **Canary strategy**.

### Key Parameters

#### 1. `maxSurge`

* Maximum number of **extra pods** that can be created during an update
* Helps control resource usage

#### 2. `maxUnavailable`

* Maximum number of pods that can be **unavailable** during an update
* Ensures application availability

> Both values can be specified as an **absolute number** or a **percentage**.

---

## 📊 Example Scenario

**Configuration**

* Replicas: `5`
* `maxSurge: 1`
* `maxUnavailable: 2`

**Behavior**

* Minimum available pods: `3`
* Maximum pods during update: `6`
* Kubernetes safely replaces old pods with new ones without downtime

---

## 🚀 Argo Rollouts Features

Argo Rollouts enhances Canary deployments with:

* Fine-grained rollout control
* Clear visualization via dashboard
* Canary-specific features such as:

  * `setWeight` (traffic percentage control)

### `setWeight`

* Controls the percentage of traffic routed to the Canary version
* Commonly used with:

  * NGINX Ingress
  * Istio
  * AWS ALB

---

## 🌐 Traffic Management (Traffic Routing)

Traffic routing enables **precise control** over how requests reach Canary and stable versions.

This repository uses **NGINX Ingress Controller**, which supports:

* Percentage-based routing
* Header-based routing
* Cookie-based routing
* Canary annotations

---

## 🧱 Example Architecture

### Rollout Configuration

* **Kind:** `Rollout`
* **Name:** `rolling-update`
* **Replicas:** 5
* **Strategy:** Canary
* **Parameters:** `maxSurge`, `maxUnavailable`
* **Image:** Retagged Canary image
* **Environment Variable:**

  * `HTML_NAME=f-v1.html` (Version 1)
  * Change to `f-v2.html` for Version 2

### Service

* Selector: `app=rolling-update`
* Routes traffic to rollout pods

### Ingress

* Controller: NGINX
* Host: `rolling-update.demo`
* Backend Service: `rolling-update`

---

## 🗂 Namespace Setup

All resources are deployed into a dedicated namespace:

```bash
kubectl create namespace canary
kubectl config set-context --current --namespace=canary
```

---

## 🧪 Example 1: Rolling Update with Ingress

### Apply Manifests

```bash
kubectl apply -f example1.yaml
kubectl apply -f example1-ingress.yaml
```

### Access Argo Rollouts Dashboard

```bash
kubectl argo rollouts dashboard
```

You can observe:

* Rollout name
* Revision number
* Strategy type
* Replica counts

### Access Application

```text
http://rolling-update.demo
```

---

## 🔁 Triggering a New Revision

Any change inside `spec.template` triggers a new ReplicaSet.

Example:

```yaml
env:
- name: HTML_NAME
  value: f-v2.html
```

Apply the change:

```bash
kubectl apply -f example1.yaml
```

---

## 📈 Rolling Update Behavior Examples

### Example 1

**Replicas:** 5
**maxSurge:** 2
**maxUnavailable:** 2

| Phase | Old Pods | New Pods | Total |
| ----- | -------- | -------- | ----- |
| Start | 3        | 4        | 7     |
| End   | 0        | 5        | 5     |

---

### Example 2 (Zero Downtime)

**Replicas:** 5
**maxSurge:** 2
**maxUnavailable:** 0

| Phase | Old Pods | New Pods | Total |
| ----- | -------- | -------- | ----- |
| Start | 5        | 2        | 7     |
| End   | 0        | 5        | 5     |

**Best for mission-critical workloads.**

---

### Example 3 (Balanced Rollout)

**Replicas:** 3
**maxSurge:** 1
**maxUnavailable:** 1

| Phase | Old Pods | New Pods | Total |
| ----- | -------- | -------- | ----- |
| Start | 2        | 2        | 4     |
| End   | 0        | 3        | 3     |

---

## ✅ Key Takeaways

* `maxSurge` controls how many new pods can be added
* `maxUnavailable` controls how many old pods can be removed
* Changes to `spec.template` always create a new ReplicaSet
* Argo Rollouts provides excellent rollout visibility
* NGINX Ingress enables smooth traffic transitions

---

## 📚 What’s Next?

Future extensions may include:

* Canary deployments using `setWeight`
* Advanced NGINX Canary annotations
* Service mesh–based traffic shifting
* Rollback and failure simulations

---


