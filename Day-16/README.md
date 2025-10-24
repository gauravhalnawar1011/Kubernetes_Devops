
# Kubernetes Resource Management Demonstrations

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)

A practical guide and collection of examples demonstrating how Kubernetes manages CPU and Memory `requests` and `limits`. This repository provides hands-on examples to help operators and developers understand the real-world behavior of resource allocation, scheduler decisions, `OOMKilled` events, and CPU `throttling`.

---

## Table of Contents

- [Kubernetes Resource Management Demonstrations](#kubernetes-resource-management-demonstrations)
  - [Table of Contents](#table-of-contents)
  - [Core Concepts](#core-concepts)
    - [Requests vs. Limits](#requests-vs-limits)
    - [Resource Units Explained](#resource-units-explained)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage: Running the Examples](#usage-running-the-examples)
    - [Part 1: Memory Requests and Limits](#part-1-memory-requests-and-limits)
      - [Example 1: Pod Runs Within Limits](#example-1-pod-runs-within-limits)
      - [Example 2: Pod Exceeds Memory Limit (OOMKilled)](#example-2-pod-exceeds-memory-limit-oomkilled)
      - [Example 3: Pod Request Exceeds Node Capacity (Pending)](#example-3-pod-request-exceeds-node-capacity-pending)
    - [Part 2: CPU Requests and Limits](#part-2-cpu-requests-and-limits)
      - [Example 4: Pod Runs Within CPU Limits](#example-4-pod-runs-within-cpu-limits)
      - [Example 5: Pod Exceeds CPU Limit (Throttled)](#example-5-pod-exceeds-cpu-limit-throttled)
      - [Example 6: Pod Request Exceeds Node Capacity (Pending)](#example-6-pod-request-exceeds-node-capacity-pending)
  - [Configuration](#configuration)
  - [Deployment](#deployment)
  - [Troubleshooting and Monitoring](#troubleshooting-and-monitoring)
  - [Contributing](#contributing)
  - [License](#license)

---

## Core Concepts

Before running the examples, it's essential to understand the two types of resource constraints you can set on a container.

### Requests vs. Limits

Kubernetes allows you to specify resource `requests` and `limits` for CPU and Memory.

| Type | Meaning | Purpose |
| :--- | :--- | :--- |
| **Request** | The **minimum** amount of CPU/Memory the container requires to start. | Used by the **Scheduler** to find a node with enough available capacity to place the Pod. |
| **Limit** | The **maximum** amount of CPU/Memory the container is allowed to use. | Used by the **Kubelet** (via cgroups) to enforce runtime restrictions. |

**Key Behaviors:**
* If a container exceeds its **Memory Limit**, it is terminated (**OOMKilled**).
* If a container exceeds its **CPU Limit**, it is **throttled** (its CPU usage is capped), but it is *not* killed.

### Resource Units Explained

#### Memory Units

| Unit | Meaning | Notes |
| :--- | :--- | :--- |
| `Ki` | Kibibyte ($1024^1$ bytes) | Rarely used |
| `Mi` | Mebibyte ($1024^2$ bytes) | **Best Practice** |
| `Gi` | Gibibyte ($1024^3$ bytes) | **Best Practice** |
| `M` | Megabyte ($1000^2$ bytes) | Decimal multiple |
| `G` | Gigabyte ($1000^3$ bytes) | Decimal multiple |

✅ **Best Practice:** Always use binary multiples (`Mi`, `Gi`) as these align with how system memory is allocated and reported.

#### CPU Units

| Unit | Meaning | Notes |
| :--- | :--- | :--- |
| `1` | One full CPU core | Can be a vCPU on a cloud provider |
| `500m` | 500 millicores (or millicpu) | `0.5` CPU cores |
| `100m` | 100 millicores | `0.1` CPU cores |

✅ **Best Practice:** Define CPU in millicores (`m`) for clarity, even for values greater than 1 (e.g., `1500m` instead of `1.5`).

---

## Prerequisites

To run these examples, you will need:
* A running Kubernetes cluster (e.g., [Minikube](https://minikube.sigs.k8s.io/docs/start/), [kind](https://kind.sigs.k8s.io/), [Docker Desktop](https://www.docker.com/products/docker-desktop/)).
* The `kubectl` command-line tool configured to communicate with your cluster.
* The [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) installed on your cluster. This is required for `kubectl top` commands to function.

---

## Installation

1.  Clone this repository to your local machine:
    ```bash
    git clone [https://github.com/your-username/k8s-resource-demos.git](https://github.com/your-username/k8s-resource-demos.git)
    cd k8s-resource-demos
    ```

2.  If you do not have the Metrics Server installed, you can typically install it with:
    ```bash
    kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)
    ```
    *Note: This may require modification for some environments (like Minikube with insecure TLS). Check your cluster's documentation.*

3.  Verify the Metrics Server is running:
    ```bash
    kubectl get pods -n kube-system | grep metrics-server
    ```

---

## Usage: Running the Examples

The examples are split into two parts: Memory and CPU. We recommend creating separate namespaces for each set of examples to keep monitoring clean.

```bash
# Create namespaces for the examples
kubectl create namespace mem-example
kubectl create namespace cpu-example
````

### Part 1: Memory Requests and Limits

These examples demonstrate how the scheduler and kubelet handle memory allocation.

#### Example 1: Pod Runs Within Limits

This Pod requests `100Mi` and sets a limit of `200Mi`. It then runs a stress test that consumes `150Mi`, which is within the allowed limit.

**File: `memory-demo-1.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "100Mi"
      limits:
        memory: "200Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```

**Run Commands:**

```bash
# Apply the manifest
kubectl apply -f memory-demo-1.yaml

# Check the pod's status (should be "Running")
kubectl get pod -n mem-example -l app=memory-demo

# Check its real-time resource usage
kubectl top pod -n mem-example
```

**Expected Output:**

```
NAME          CPU(cores)   MEMORY(bytes)
memory-demo   1m           151Mi
```

✅ **Explanation:** The Pod runs successfully because its usage (`~150Mi`) is greater than its request (`100Mi`) but less than its limit (`200Mi`).

-----

#### Example 2: Pod Exceeds Memory Limit (OOMKilled)

This Pod sets a hard limit of `100Mi` but attempts to allocate `250M`. This will trigger the Linux OOM (Out of Memory) Killer.

**File: `memory-demo-2.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo2
  namespace: mem-example
spec:
  containers:
  - name: memory-demo2-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
```

**Run Commands:**

```bash
# Apply the manifest
kubectl apply -f memory-demo-2.yaml

# Watch the pod's status
kubectl get pod -n mem-example -w
```

**Expected Output:**
The Pod will repeatedly try to start, fail, and restart.

```
NAME           READY   STATUS             RESTARTS   AGE
memory-demo2   0/1     ContainerCreating   0          2s
memory-demo2   0/1     OOMKilled           0          5s
memory-demo2   0/1     CrashLoopBackOff    1          10s
```

**Check Details:**

```bash
kubectl describe pod memory-demo2 -n mem-example
```

✅ **Explanation:** The `describe` command will show `State: Waiting` with `Reason: CrashLoopBackOff`, and the `Last State` will be `Terminated` with `Reason: OOMKilled`. The container was killed by the system because it violated its `100Mi` memory limit.

-----

#### Example 3: Pod Request Exceeds Node Capacity (Pending)

This Pod requests `1000Gi` of memory, which (presumably) no node in the cluster can fulfill.

**File: `memory-demo-3.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo3
  namespace: mem-example
spec:
  containers:
  - name: memory-demo3-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "1000Gi"
      limits:
        memory: "1000Gi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "1M", "--vm-hang", "1"]
```

**Run Commands:**

```bash
# Apply the manifest
kubectl apply -f memory-demo-3.yaml

# Check the pod's status
kubectl get pod memory-demo3 -n mem-example
```

**Expected Output:**

```
NAME           READY   STATUS    RESTARTS   AGE
memory-demo3   0/1     Pending   0          10s
```

**Check Events:**

```bash
kubectl describe pod memory-demo3 -n mem-example
```

✅ **Explanation:** The Pod remains `Pending`. The `describe` command will show a `FailedScheduling` event with the message `0/2 nodes are available: 2 Insufficient memory`. The scheduler could not find any node that satisfied the `1000Gi` request, so the Pod was never scheduled to run.

-----

### Part 2: CPU Requests and Limits

These examples demonstrate CPU allocation, which differs from memory in one key way: **exceeding CPU limits results in throttling, not termination.**

#### Example 4: Pod Runs Within CPU Limits

This Pod requests `200m` and limits to `500m`. It runs a stress test that consumes `0.3` CPU (`300m`), which is within the allowed limit.

**File: `cpu-demo-1.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo
  namespace: cpu-example
spec:
  containers:
  - name: cpu-demo-ctr
    image: vish/stress
    resources:
      requests:
        cpu: "200m"
      limits:
        cpu: "500m"
    args:
      - -cpus
      - "0.3"
```

**Run Commands:**

```bash
# Apply the manifest
kubectl apply -f cpu-demo-1.yaml

# Check its real-time resource usage
kubectl top pod -n cpu-example
```

**Expected Output:**

```
NAME       CPU(cores)   MEMORY(bytes)
cpu-demo   300m         1Mi
```

✅ **Explanation:** The Pod runs successfully, consuming `300m` of CPU, which is below its `500m` limit.

-----

#### Example 5: Pod Exceeds CPU Limit (Throttled)

This Pod sets a limit of `300m` but attempts to use 1 full CPU (`1000m`). The container will not be killed; it will simply be "throttled" and not allowed to use more than `300m` of CPU.

**File: `cpu-demo-2.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo2
  namespace: cpu-example
spec:
  containers:
  - name: cpu-demo2-ctr
    image: vish/stress
    resources:
      requests:
        cpu: "200m"
      limits:
        cpu: "300m"
    args:
      - -cpus
      - "1"
```

**Run Commands:**

```bash
# Apply the manifest
kubectl apply -f cpu-demo-2.yaml

# Check its resource usage (it may fluctuate slightly)
kubectl top pod cpu-demo2 -n cpu-example
```

**Expected Output:**

```
NAME        CPU(cores)   MEMORY(bytes)
cpu-demo2   300m         1Mi
```

✅ **Explanation:** Even though the application *tries* to use 1 CPU (`1000m`), `kubectl top` shows its usage is capped at `300m`. The Pod remains in a `Running` state but its performance is restricted by the CPU limit.

-----

#### Example 6: Pod Request Exceeds Node Capacity (Pending)

This Pod requests `10` full CPU cores, which is more than any single node can provide.

**File: `cpu-demo-3.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo3
  namespace: cpu-example
spec:
  containers:
  - name: cpu-demo3-ctr
    image: vish/stress
    resources:
      requests:
        cpu: "10"
      limits:
        cpu: "10"
    args:
      - -cpus
      - "2"
```

**Run Commands:**

```bash
# Apply the manifest
kubectl apply -f cpu-demo-3.yaml

# Check the pod's status
kubectl get pod cpu-demo3 -n cpu-example
```

**Expected Output:**

```
NAME        READY   STATUS    RESTARTS   AGE
cpu-demo3   0/1     Pending   0          5s
```

**Check Events:**

```bash
kubectl describe pod cpu-demo3 -n cpu-example
```

✅ **Explanation:** The Pod remains `Pending`. The `describe` command will show a `FailedScheduling` event with the message `0/2 nodes are available: 2 Insufficient cpu`. The scheduler could not find a node to satisfy the `10` CPU request.

-----

## Configuration

All configuration for these examples is contained within the YAML manifests (`.yaml` files) in this repository. You can modify the `resources.requests` and `resources.limits` blocks within these files to experiment with different values.

-----

## Deployment

The examples in this repository are designed for local or development cluster deployment. They are applied directly to the cluster using `kubectl`.

```bash
# To apply a specific example
kubectl apply -f <filename>.yaml

# To delete a specific example
kubectl delete -f <filename>.yaml
```

-----

## Troubleshooting and Monitoring

Here are the key commands for observing the behavior of these resource-constrained Pods.

```bash
# Check if the metrics-server is running
kubectl get pods -n kube-system | grep metrics-server

# View resource usage (CPU/Memory) for all nodes
kubectl top nodes

# View resource usage for all pods in a namespace
kubectl top pods -n <namespace>

# Get a detailed description and event log for a pod
kubectl describe pod <pod-name> -n <namespace>

# Watch a pod's status in real-time
kubectl get pod <pod-name> -n <namespace> -w
```

| Summary (Memory) | Request | Limit | Behavior |
| :--- | :--- | :--- | :--- |
| ✅ Within limit | `100Mi` | `200Mi` | **Runs fine** |
| ⚠️ Exceed limit | `50Mi` | `100Mi` | **OOMKilled** |
| 🚫 Exceed node | `1000Gi` | `1000Gi`| **Pending** (Unschedulable)|

<br>

| Summary (CPU) | Request | Limit | Behavior |
| :--- | :--- | :--- | :--- |
| ✅ Within limit | `200m` | `500m` | **Runs fine** |
| ⚠️ Exceed limit | `200m` | `300m` | **Throttled** (no crash) |
| 🚫 Exceed node | `10` | `10` | **Pending** (Unschedulable)|

```
```