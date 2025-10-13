
---

# Day-06: Kubernetes Local Setup using Kind – Full Component Breakdown

## Overview

In this session, we will:

1. Install Kubernetes locally using **Kind (Kubernetes in Docker)**.
2. Understand Kubernetes cluster components.
3. Create **single-node** and **multi-node** clusters.
4. Manage clusters using `kubectl`.
5. Prepare for cloud-managed Kubernetes (GKE, AKS, EKS).

**Goal:** Learn Kubernetes fundamentals locally before moving to cloud environments.

---

## Prerequisites

* Docker installed and running.
* Ubuntu 24.04 or similar Linux distribution.
* Basic understanding of Kubernetes concepts like pods, nodes, control plane, worker nodes.
* Basic terminal and YAML knowledge.

Check your environment:

```bash
docker -v       # Docker client version
docker version  # Detailed client/server info
lsb_release -a  # OS info
```

---

## Why Kind?

**Kind (Kubernetes in Docker)** runs Kubernetes clusters in Docker containers.

**Key advantages:**

* Lightweight and portable.
* Useful for development and testing.
* Supports **multi-node clusters** locally.
* Easy to delete and recreate clusters.

**Other local Kubernetes options:**

* Minikube
* K3s
* K3d

Kind is ideal for testing Kubernetes cluster setup before using managed services like **GKE, AKS, or EKS**.

---

## Kubernetes Components Overview

Here’s a breakdown of the key Kubernetes components that you will interact with:

### 1. **Control Plane Components**

The **control plane** manages the cluster. In Kind, a control-plane node is a Docker container.

| Component                    | Role                                                             |
| ---------------------------- | ---------------------------------------------------------------- |
| **kube-apiserver**           | Frontend for the Kubernetes control plane. Handles API requests. |
| **etcd**                     | Key-value store storing all cluster data (state, config).        |
| **kube-scheduler**           | Schedules pods onto nodes based on resource availability.        |
| **kube-controller-manager**  | Maintains cluster state (replicas, endpoints, etc.).             |
| **cloud-controller-manager** | Optional in local setup, interacts with cloud APIs.              |

### 2. **Node Components (Worker Nodes)**

Worker nodes run your application workloads.

| Component                      | Role                                                          |
| ------------------------------ | ------------------------------------------------------------- |
| **kubelet**                    | Ensures containers are running in pods as per specifications. |
| **kube-proxy**                 | Handles network routing for services and pods.                |
| **Container Runtime (Docker)** | Runs containers (pods) on the node.                           |

### 3. **Kubectl**

The CLI tool to interact with Kubernetes clusters:

* `kubectl get nodes` → List cluster nodes.
* `kubectl cluster-info` → Cluster endpoint info.
* `kubectl config` → Manage contexts and clusters.

---

## Installation Steps

### Step 1: Install Kind

**For AMD64 (x86_64)**:

```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
```

**For ARM64 (aarch64)**:

```bash
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-arm64
```

Make executable and move to system path:

```bash
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Verify installation:

```bash
kind version
```

---

### Step 2: Create a Cluster

#### Single-node Cluster

```bash
kind create cluster --name space9
kubectl cluster-info --context kind-space9
kubectl get nodes
```

* By default, the **control plane and worker roles** are combined into a single node.
* Node name example: `space9-control-plane`.

#### Multi-node Cluster

Create a YAML configuration file `config.yaml`:

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

Create the cluster:

```bash
kind create cluster --name space9-v2 --image kindest/node:v1.33.4 --config config.yaml
kubectl get nodes
```

**Explanation:**

* `role: control-plane` → Master node running the API server, etcd, and controllers.
* `role: worker` → Node running workloads.
* `kubeadmConfigPatches` → Optional node-level configuration.

---

### Step 3: Manage Contexts

Kubernetes supports multiple clusters. Contexts allow you to switch easily.

* List contexts:

```bash
kubectl config get-contexts
```

* Set default context:

```bash
kubectl config use-context kind-space9-v2
```

* Check current context:

```bash
kubectl config current-context
```

<img width="1199" height="599" alt="Image" src="https://github.com/user-attachments/assets/b5a34272-554a-44b2-a7c4-51fad84b0de9" />

---

### Step 4: Certificates (Optional for e2e tests)

```bash
kubectl config view --raw -o jsonpath='{.users[?(.name == "e2e")].user.client-certificate-data}' | base64 -d
```

---

## Docker Networking in Kind

* Each node is a **Docker container**.
* Docker provides an isolated network.
* Retrieve control-plane container IP:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' space9-v2-control-plane
```

* Useful for custom kubeconfig entries.

---

## Advanced Cluster Configurations

* **Multi-Control Plane HA:** For production-like setups, create clusters with multiple control-plane nodes.
* **Custom containerd settings:** Enable systemd cgroups, configure registries, or patch kubeadm.

---

## Troubleshooting

* Check Docker logs:

```bash
docker logs <container_name>
```

* Delete a cluster and recreate:

```bash
kind delete cluster --name space9-v2
```

* Kind GitHub issues page: [https://github.com/kubernetes-sigs/kind/issues](https://github.com/kubernetes-sigs/kind/issues)

---

## References

* [Kind Official Documentation](https://kind.sigs.k8s.io/)
* [Kubernetes Official Docs](https://kubernetes.io/docs/)

---

This explanation now includes:

1. **Every component** (control plane, worker nodes, kubectl).
2. **Commands explained** with their purpose.
3. **Docker networking explanation**.
4. **Advanced configurations** for multi-node and multi-control plane clusters.

---

