# Pod Priority and Preemption in Kubernetes

This guide provides a clear explanation and hands-on demo for **Pod Priority** and **Preemption** in Kubernetes. When running workloads in a resource-constrained cluster, Kubernetes uses priorities to decide which pods should be scheduled first and which low-priority pods may be evicted to make space.

---

## 🧠 What Are Pod Priority and Preemption?

When you create a pod, it does not immediately run unless the scheduler finds enough resources on a node. In a heavily utilized cluster, new pods may remain in a **Pending** state.

Kubernetes solves this resource conflict using:

### ✔️ Pod Priority

Determines **which pod should be scheduled first**. Higher priority pods are favored over lower priority pods.

### ✔️ Preemption

When resources are insufficient, Kubernetes may **evict lower-priority pods** to free up space for higher-priority pods.

---

## 🎯 Priority Value Basics

Pod priority is determined by a numerical value:

* Higher number = Higher priority
* Example priority range: `0 → 200 → 500 → 1000 → 2000`

To standardize usage, we use **PriorityClasses**, instead of hardcoding values in every pod.

---

## 🏷️ PriorityClass Definition

A PriorityClass associates:

* A **name** (used by pods)
* A **numeric value** (actual priority)
* Whether it's the **global default**

In this demo, we use three priority classes:

* `1000000` → High
* `100000` → Medium
* `10000` → Low (global default)

---

## 🧪 Demo: Pod Priority & Preemption

Below is a full step-by-step demonstration.

---

## Step 1: Create Priority Classes

### **High Priority Class** (`high-priority.yaml`)

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "This priority class should be used for high priority service pods only."
```

### **Medium Priority Class** (`medium-priority.yaml`)

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 100000
globalDefault: false
description: "This priority class should be used for medium priority service pods."
```

### **Low Priority Class** (`low-priority.yaml`)

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 10000
globalDefault: true
description: "This priority class should be used for low priority service pods."
```

Apply the classes:

```bash
kubectl apply -f high-priority.yaml
kubectl apply -f medium-priority.yaml
kubectl apply -f low-priority.yaml
```

Verify:

```bash
kubectl get priorityclasses
```

---

## Step 2: Create Pods with Different Priorities

### High Priority Pod (`high-priority-pod.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: high-priority-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "128Mi"
        cpu: "500m"
  priorityClassName: high-priority
```

### Medium Priority Pod (`medium-priority-pod.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: medium-priority-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "128Mi"
        cpu: "500m"
  priorityClassName: medium-priority
```

### Low Priority Pod (`low-priority-pod.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: low-priority-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "128Mi"
        cpu: "500m"
  priorityClassName: low-priority
```

Apply the manifests:

```bash
kubectl apply -f low-priority-pod.yaml
kubectl apply -f medium-priority-pod.yaml
kubectl apply -f high-priority-pod.yaml
```

---

## Step 3: Create a Resource-Constrained Scenario

### Resource Hog Deployment (`resource-hog.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-hog
  labels:
    app: resource-hog
spec:
  replicas: 5
  selector:
    matchLabels:
      app: resource-hog
  template:
    metadata:
      labels:
        app: resource-hog
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
      priorityClassName: low-priority
```

Apply:

```bash
kubectl apply -f resource-hog.yaml
```

---

## Step 4: Deploy a Critical High-Priority Pod

### Critical Pod (`critical-pod.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "512Mi"
        cpu: "15000m"
  priorityClassName: high-priority
```

Apply:

```bash
kubectl apply -f critical-pod.yaml
```

---

## Step 5: Observe Preemption

Watch pods:

```bash
kubectl get pods -o wide -w
```

You should see **low-priority pods being terminated** to free resources.

Check event logs:

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## 🧹 Cleanup Resources

```bash
kubectl delete -f high-priority-pod.yaml
kubectl delete -f medium-priority-pod.yaml
kubectl delete -f low-priority-pod.yaml
kubectl delete -f resource-hog.yaml
kubectl delete -f critical-pod.yaml

kubectl delete -f high-priority.yaml
kubectl delete -f medium-priority.yaml
kubectl delete -f low-priority.yaml
```

---

## 📌 Summary

* Use **PriorityClass** to define pod scheduling importance.
* Higher priority pods can **preempt** lower priority pods.
* Useful for mission-critical workloads in tight-resource clusters.

This README acts as a complete reference for understanding and testing Kubernetes pod priority and preemption.
