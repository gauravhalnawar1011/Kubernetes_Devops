
---

# 📦 Kubernetes Storage Classes, Static & Dynamic Provisioning

*Day-52 | Open Source Learning Project*

This repository provides a clean, practical reference for understanding **Kubernetes Storage Classes** and how **static** and **dynamic volume provisioning** work in real-world environments.
Designed for DevOps engineers, Kubernetes administrators, and platform teams.

---

## 📘 Table of Contents

* [Introduction](#introduction)
* [Key Concepts](#key-concepts)
* [Static Provisioning](#static-provisioning)
* [Dynamic Provisioning](#dynamic-provisioning)
* [How Storage Classes Work](#how-storage-classes-work)
* [Reclaim Policies](#reclaim-policies)
* [Supported Storage Backends](#supported-storage-backends)
* [Examples](#examples)
* [Useful Commands](#useful-commands)
* [Official Documentation](#official-documentation)

---

## 🧭 Introduction

Storage is a central component in Kubernetes, enabling workloads to persist data beyond the lifetime of pods. Kubernetes supports multiple storage backends through **Persistent Volumes (PV)**, **Persistent Volume Claims (PVC)**, and **Storage Classes (SC)**.

This guide explains:

* How storage is provisioned
* The difference between static and dynamic provisioning
* How Storage Classes automate provisioning
* When and why to use each approach

---

## 🔑 Key Concepts

### **Persistent Volume (PV)**

A *cluster-wide* storage resource representing actual physical storage (disk, NFS, cloud disk, etc.).

### **Persistent Volume Claim (PVC)**

A request for storage by a user/workload, similar to requesting CPU/Memory.

### **Storage Class (SC)**

A template that defines *how* Kubernetes should create volumes, including:

* Provisioner (e.g. AWS EBS, GCP PD, Azure Disk, NFS)
* Storage type (SSD/HDD)
* Parameters (performance, replication, filesystem)
* Reclaim policy
* Binding mode

StorageClass enables **Dynamic Provisioning**.

---

## 🗂️ Static Provisioning

Static provisioning requires **manual setup** of Persistent Volumes.
Typically performed by a *storage administrator* or DevOps engineer.

### **How It Works**

1. Admin creates a **PV** with a fixed size, access mode, and backend.
2. Developer creates a **PVC** requesting capacity.
3. Kubernetes tries to match the PVC to an existing PV.
4. If parameters match (size, access mode, storage class), they are *bound*.

### Example Flow

* Admin creates PV → 80Gi, `ReadWriteOnce (RWO)`
* Developer requests PVC → 10Gi, `RWO`
* Kubernetes binds PVC → PV (if requirements match)

### **Pros**

* Predictable
* Full control over volumes
* Good for pre-allocated enterprise storage

### **Cons**

* Manual
* Risk of unused PVs (wasted cost)
* Not scalable for cloud-native environments

---

## ⚙️ Dynamic Provisioning

Dynamic provisioning allows Kubernetes to **automatically create persistent volumes** when a PVC is submitted.

### **How It Works**

1. Developer creates a PVC referencing a **StorageClass**
2. K8s uses the StorageClass **provisioner**
3. A new PV is automatically created and bound
4. Storage is created *on demand* and deleted when no longer needed

### **Pros**

* Automatic & scalable
* Cost-efficient
* Different StorageClasses for different workloads (SSD/HDD/Network Storage)
* No manual PV creation required

### **Cons**

* Requires a cloud provider or storage plugin that supports provisioning
* Not all on-prem storage supports dynamic provisioning without CSI drivers

---

## 🧩 How Storage Classes Work

A StorageClass links Kubernetes to a storage backend using:

### **1️⃣ Provisioner**

Defines “*how to create the disk*”. Examples:

* `kubernetes.io/gce-pd` (GCP Persistent Disk)
* `kubernetes.io/aws-ebs` (AWS EBS)
* `disk.csi.azure.com` (Azure Disk CSI)
* `nfs.csi.k8s.io` (NFS CSI)

### **2️⃣ Parameters**

Backend-specific options, such as:

* Disk type (SSD/HDD)
* Replication level
* Filesystem type
* Zones/regions
* Performance profile

### **3️⃣ Reclaim Policy**

What happens when the PVC is deleted:

* **Retain** → keep data
* **Delete** → delete underlying storage
* **Recycle** *(deprecated)*

### **4️⃣ VolumeBindingMode**

* **Immediate**: PV is created instantly
* **WaitForFirstConsumer**: PV created only when a Pod using PVC is scheduled

  * Prevents creating PV in the wrong zone

---

## 🧱 Supported Storage Backends

Examples of storage options commonly used:

| Storage Type             | Examples                                 |
| ------------------------ | ---------------------------------------- |
| **Cloud disks**          | GCP Persistent Disk, AWS EBS, Azure Disk |
| **Network file systems** | NFS, Azure Files, Filestore              |
| **Local storage**        | local-path provisioner                   |
| **Enterprise storage**   | NetApp, Ceph, Portworx, Dell EMC         |
| **SSD / HDD**            | Based on cloud provider or hardware      |

---

## 📂 Examples

### **1. StorageClass (SSD — High Performance)**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: high-performance
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  fsType: ext4
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

---

### **2. StorageClass (Standard HDD — Cost Efficient)**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cost-effective
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
  fsType: ext4
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

---

### **3. PVC using a StorageClass (Dynamic Provisioning)**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: high-performance
  resources:
    requests:
      storage: 20Gi
```

---

## 🧪 How Dynamic Provisioning Behaves

Scenario: Developer creates PVC → 70Gi, AccessMode: `RWX`.

If:

* No matching PV exists
* StorageClass is available

Then:

* Kubernetes **creates a new PV** with matching requirements
* PVC is immediately bound
* Volume is created **on-demand**

---

## 🛠 Useful Commands

```bash
# List all Storage Classes
kubectl get storageclass

# View default StorageClass
kubectl get sc | grep "(default)"

# Describe a StorageClass
kubectl describe sc <name>

# Patch default StorageClass
kubectl patch storageclass <name> \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Remove default annotation
kubectl patch storageclass <name> \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Check PVCs
kubectl get pvc

# Troubleshoot PVC
kubectl describe pvc <pvc-name>

# Inspect auto-created PVs
kubectl get pv
```

---

## 🔗 Official Documentation

* Kubernetes Storage Concepts
  [https://kubernetes.io/docs/concepts/storage/](https://kubernetes.io/docs/concepts/storage/)

* Persistent Volumes
  [https://kubernetes.io/docs/concepts/storage/persistent-volumes/](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

* Storage Classes
  [https://kubernetes.io/docs/concepts/storage/storage-classes/](https://kubernetes.io/docs/concepts/storage/storage-classes/)

* Dynamic Provisioning
  [https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

---


