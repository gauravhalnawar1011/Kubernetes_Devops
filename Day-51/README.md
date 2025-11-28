
---

# 📘 Kubernetes Admission Controllers — Deep Dive

*Day 51 — Advanced Kubernetes Internals*

## 🧩 Overview

Kubernetes Admission Controllers are one of the **most powerful mechanisms** for enforcing cluster governance, security, and automation. They intercept API requests **after authentication & authorization**, but **before the request is persisted to etcd**, allowing Kubernetes to validate or mutate resources dynamically.

This README provides a **clear conceptual overview**, an **expert-level explanation**, and **hands-on examples** of built-in admission plugins and webhooks.

---

## 📖 Table of Contents

* [What are Admission Controllers?](#what-are-admission-controllers)
* [How Admission Control Works](#how-admission-control-works)
* [Types of Admission Controllers](#types-of-admission-controllers)

  * [Mutating Admission Webhooks](#mutating-admission-webhooks)
  * [Validating Admission Webhooks](#validating-admission-webhooks)
  * [Validating Admission Policies (VAP)](#validating-admission-policies-vap)
* [Why Do We Need Admission Controllers?](#why-do-we-need-admission-controllers)
* [Webhook Call Mechanisms](#webhook-call-mechanisms)
* [Complete Request Flow](#complete-request-flow)
* [Checking Enabled Admission Plugins](#checking-enabled-admission-plugins)
* [Demo: NamespaceAutoProvision Plugin](#demo-namespaceautoprovision-plugin)
* [Hands-on Built-in Controllers](#hands-on-built-in-controllers)
* [References](#references)

---

## ❓ What Are Admission Controllers?

According to the official Kubernetes documentation:

> *“Admission controllers are software modules that intercept requests to the Kubernetes API server before the persistence of the object.”*
> — Kubernetes Docs

In simple terms:
An **Admission Controller** is the **gatekeeper** that checks and modifies resources *before* they are stored in etcd.

---

## 🔄 How Admission Control Works

### 📌 Request Path

```
Client Request
      ↓
[Authentication]
      ↓
[Authorization]
      ↓
[Admission Controllers]
  - Mutating Admission Webhooks
  - Validating Admission Webhooks
  - Validating Admission Policies
      ↓
[Object stored in etcd]
```

### 📌 Decision Outcomes

| Step             | Result    | Action                   |
| ---------------- | --------- | ------------------------ |
| Admission passes | ✅ Success | Object stored in etcd    |
| Admission fails  | ❌ Denied  | Error returned to client |

---

## 🧱 Types of Admission Controllers

### 1️⃣ **Mutating Admission Webhooks**

* Can **modify incoming objects**
* Example: Injecting sidecar containers (e.g., Istio)
* They run **before** validation webhooks
* Example use cases:

  * Auto-adding labels
  * Defaulting resource limits
  * Adding tolerations automatically

### 2️⃣ **Validating Admission Webhooks**

* Cannot modify the object
* Only **validate** whether the request is acceptable
* Example: Reject pod if namespace does not exist

Example error:

```
Error from server (NotFound): namespaces "dev" not found
```

### 3️⃣ **Validating Admission Policies (VAP)**

* Built-in Kubernetes validation framework using CEL expressions
* More lightweight than webhooks
* Example rule:

  * Deny pods running privileged containers

---

## 🎯 Why Do We Need Admission Controllers?

They allow cluster operators to enforce:

* Security policies
* Governance rules
* Resource constraints
* Namespace automation
* Multi-tenant isolation

Used heavily in:

* Gatekeeper (OPA)
* Kyverno
* Service Meshes (Istio, Linkerd)
* Enterprise security policies

---

## 🌐 Webhook Call Mechanisms

A webhook can be registered using:

### 🔹 **URL**

Direct HTTPS endpoint (external controllers)

### 🔹 **Service Reference**

Internal K8s service pointing to webhook pods:

```
Service -> Deployment -> Webhook server
```

This is the most common method.

---

## 🔁 Deep Request Flow (Advanced)

```
kubectl request
     ↓
Authentication
     ↓
Authorization (RBAC / ABAC)
     ↓
Mutating Webhooks
     ↓
Object Schema Validation
     ↓
Validating Admission Policies (VAP)
     ↓
Validating Webhooks
     ↓
Final Admission Decision
     ↓
etcd
```

If **any step fails**, the whole request is rejected.

---

## 🧪 Checking Enabled Admission Plugins

### **Method 1: Inspect API server pod**

```bash
kubectl get pod kube-apiserver-controlplane -n kube-system -o yaml | grep -i admission
```

### **Method 2: Check API server process**

```bash
ps aux | grep kube-apiserver | grep enable-admission-plugins
```

### **Method 3: Get help options**

```bash
kubectl exec -it kube-apiserver-controlplane -n kube-system -- kube-apiserver -h | grep enable-admission-plugins
```

Example output:

```
--enable-admission-plugins=NodeRestriction
```

---

## 🛠️ Demo: NamespaceAutoProvision Plugin

By default:

```
kubectl run nginx --image=nginx -n dev
```

➡️ Fails with:

```
Error from server (NotFound): namespaces "dev" not found
```

### Enable NamespaceAutoProvision

1. Backup API server manifest:

```bash
cp /etc/kubernetes/manifests/kube-apiserver.yaml kube-apiserver.yaml_bkp
```

2. Edit:

```yaml
- --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
```

3. API server auto-restarts.

4. Test again:

```bash
kubectl run nginx --image=nginx -n dev
```

✔ Namespace auto-created
✔ Pod deployed successfully

---

## 🧪 Hands-on With Other Built-in Admission Controllers

### 1️⃣ **ResourceQuota (Validating Controller)**

Prevents overconsumption:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: quota-demo
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
```

Creating a pod exceeding the quota returns:

```
Error: exceeded quota
```

---

### 2️⃣ **LimitRanger (Mutating Controller)**

Auto-adds default limits:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - default:
      memory: "512Mi"
      cpu: "200m"
```

Create a pod with no resources → Kubernetes injects them automatically.

---

## 📚 References

* **Kubernetes Official Docs — Admission Controllers**
  [https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

* **Kubernetes Admission Webhooks**
  [https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)

* **Medium Articles**

  * *"Understanding Kubernetes Admission Controllers"*
    [https://medium.com/kubernetes-tutorials](https://medium.com/kubernetes-tutorials)
  * *"Mutating vs Validating Admission Webhooks"*

* **SIG-Auth Community Discussions**
  [https://github.com/kubernetes/community/tree/master/sig-auth](https://github.com/kubernetes/community/tree/master/sig-auth)

---

