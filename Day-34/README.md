
---

# 🧠 Day-34 — Upgrading a Multi-Node Kubernetes Cluster (1 Master + 4 Workers)

## 📘 Overview

This guide demonstrates **how to upgrade a multi-node Kubernetes cluster** (with one control plane node and four worker nodes) while ensuring **zero downtime** and maintaining **cluster stability**.

We will discuss upgrade strategies, version compatibility rules, and real command examples for both **control plane** and **worker node** upgrades.

---

## ⚙️ Cluster Topology

| Role         | Count                                | Description                                                                |
| ------------ | ------------------------------------ | -------------------------------------------------------------------------- |
| Master Node  | 1                                    | Hosts control plane components (API Server, Controller Manager, Scheduler) |
| Worker Nodes | 4                                    | Run workloads and managed pods                                             |
| Workloads    | 1 Deployment + 1 unmanaged MySQL Pod | Deployment managed via ReplicaSet; MySQL Pod not managed                   |

---

## 📍 Scenario

Suppose we need to **perform maintenance** on `worker-1`.
Before shutting it down, we must **drain** it to safely evict workloads and mark it **unschedulable**.

```bash
kubectl drain worker-1 --ignore-daemonsets
```

This will:

* Evict all pods managed by controllers (like Deployments)
* Prevent new pods from being scheduled on the node (`cordon`)

> ⚠️ **Note:** Any standalone (unmanaged) pods, such as a manually created MySQL pod, will be deleted and **not recreated**.
> Always use Deployments, StatefulSets, or DaemonSets for persistent workloads.

After maintenance, bring the node back:

```bash
kubectl uncordon worker-1
```

---

## 🧩 Kubernetes Versioning Policy

Kubernetes follows **semantic versioning (MAJOR.MINOR.PATCH)**:

* **MAJOR (1):** Backward-incompatible changes
* **MINOR (34):** Feature updates (every 2–3 months)
* **PATCH (1):** Bug fixes and security patches

### Example

You’re running Kubernetes `v1.32.2` and want to upgrade to `v1.34.2`.
You **cannot skip** minor versions. You must upgrade sequentially:

```
1.32.2 → 1.33.2 → 1.34.2
```

Kubernetes only supports **three minor versions at a time**.

---

## 🧱 High-Level Upgrade Workflow

1. Upgrade a **primary control plane node**
2. Upgrade **additional control plane nodes** (if HA setup)
3. Upgrade **worker nodes**

---

## 🕹️ Worker Node Upgrade Strategies

### Option 1: **All-at-Once Upgrade**

* Drain all worker nodes simultaneously
* Upgrade all components
* Brings downtime risk (⚠️ not recommended for production)

### Option 2: **Rolling Upgrade (Recommended)**

* Upgrade one node at a time
* Workloads continue to run on remaining nodes
* Ensures minimal to zero disruption

### Option 3: **Blue-Green Strategy**

* Spin up a parallel (new) cluster
* Migrate workloads gradually
* Safest for **managed clusters** (EKS, AKS, GKE)

---

## 🧮 Component Version Compatibility

| Component                      | Version Relation |
| ------------------------------ | ---------------- |
| Kube-API Server                | `x`              |
| Controller Manager / Scheduler | `x-1`            |
| Kubelet / Kubectl              | `x-2`            |

> ✅ **Best Practice:** Keep all components on the **same version**.

---

## 🧰 Pre-Checks

```bash
# Check OS version
cat /etc/os-release

# Verify current Kubernetes version
kubectl version --short
```

---

## 🚀 Step-by-Step Upgrade Guide

### Step 1: Determine Target Version

```bash
sudo apt update
sudo apt-cache madison kubeadm
```

Choose the latest stable version, e.g. `1.34.x-*`.

---

### Step 2: Upgrade Control Plane Node

#### 1️⃣ Update `kubeadm`

```bash
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.34.x-*' && \
sudo apt-mark hold kubeadm
```

#### 2️⃣ Verify Version and Plan

```bash
kubeadm version
sudo kubeadm upgrade plan
```

#### 3️⃣ Apply Upgrade

```bash
sudo kubeadm upgrade apply v1.34.x
```

Expected Output:

```
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.34.x". Enjoy!
```

#### 4️⃣ Update Kubelet and Kubectl

```bash
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y kubelet='1.34.x-*' kubectl='1.34.x-*' && \
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

#### 5️⃣ Verify and Uncordon Node

```bash
kubectl get nodes
kubectl uncordon <control-plane-node>
```

---

### Step 3: Upgrade Worker Nodes

Perform this **one node at a time**:

#### 1️⃣ Drain Node

```bash
kubectl drain <worker-node> --ignore-daemonsets
```

#### 2️⃣ Update Kubeadm

```bash
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.34.x-*' && \
sudo apt-mark hold kubeadm
```

#### 3️⃣ Upgrade Node Components

```bash
sudo kubeadm upgrade node
```

#### 4️⃣ Update Kubelet and Kubectl

```bash
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y kubelet='1.34.x-*' kubectl='1.34.x-*' && \
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

#### 5️⃣ Bring Node Back Online

```bash
kubectl uncordon <worker-node>
```

Repeat for all worker nodes.

---

## 🧩 Post-Upgrade Validation

```bash
kubectl get nodes
kubectl get pods -A
kubectl get cs
```

Ensure all nodes show `Ready` status and workloads are healthy.

---

## 🌐 References & Official Sources

* [Kubernetes Documentation – Upgrade Clusters](https://kubernetes.io/docs/tasks/administer-cluster/cluster-upgrade/)
* [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
* [Kubernetes Packages (pkgs.k8s.io)](https://pkgs.k8s.io/)
* [kubeadm Upgrade Guide](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-upgrade/)
* [Best Practices for Node Maintenance](https://kubernetes.io/docs/concepts/architecture/nodes/#manual-node-administration)

---

## 🧠 Key Takeaways

* Always drain and cordon nodes before maintenance.
* Never run critical workloads as unmanaged pods.
* Upgrade control plane before worker nodes.
* Follow the **version skew policy** strictly.
* Validate cluster health post-upgrade.

---

## 🏁 Summary

This guide provided a **structured and production-grade workflow** for upgrading a Kubernetes multi-node cluster with minimal downtime, focusing on **best practices**, **safe drain/uncordon procedures**, and **sequential version upgrades**.

> 💡 **Pro Tip:** Always test your upgrade process in a staging cluster before production!

---

