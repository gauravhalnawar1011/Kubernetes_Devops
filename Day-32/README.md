
---

# 🚀 Kubernetes Networking Explained | Container Network Interface (CNI) with @Kubesimplify

Learn how **Kubernetes networking** works under the hood — from container runtimes to **CNI (Container Network Interface)**, namespaces, bridges, and veth pairs — all explained clearly with live demos and command outputs.
This repository is part of the **KubeSimplify Learning Series (Day 32)** and aims to demystify one of the most complex topics in Kubernetes: **how Pods actually talk to each other**.

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Evolution of Container Runtimes](#-evolution-of-container-runtimes)
3. [Kubernetes Networking and the CNI Spec](#-kubernetes-networking-and-the-cni-spec)
4. [How Pods, Network Namespaces, and veth Pairs Work](#-how-pods-network-namespaces-and-veth-pairs-work)
5. [Architecture Diagram](#-architecture-diagram)
6. [CNI Operations](#-cni-operations)
7. [Popular CNI Plugins](#-popular-cni-plugins)
8. [Example Pod YAML](#-example-pod-yaml)
9. [Demo Walkthrough](#-demo-walkthrough)
10. [Pause Containers Explained](#-pause-containers-explained)
11. [Pod Communication (Intra, Inter, and Inter-node)](#-pod-communication-intra-inter-and-inter-node)
12. [Kube-Proxy, CoreDNS & Service Discovery](#-kube-proxy-coredns--service-discovery)
13. [🧩 Prerequisites](#-prerequisites)
14. [⚙️ Setup / Usage Instructions](#️-setup--usage-instructions)
15. [🤝 Contributing](#-contributing)
16. [📜 License](#-license)
17. [📚 Key Takeaways](#-key-takeaways)
18. [🔗 Further Reading / References](#-further-reading--references)

---

## 🌐 Overview

When Kubernetes was born, **Docker** was the only container runtime available.
Over the years, Kubernetes evolved to support multiple runtimes (like `containerd`, `CRI-O`, `Kata`, and `Wasmtime`) — thanks to the **Open Container Initiative (OCI)** and **Container Runtime Interface (CRI)**.

This repository explains:

* How **container runtimes** evolved in Kubernetes.
* How the **Container Network Interface (CNI)** standardizes networking.
* How **Pods communicate** within and across nodes.
* Real-world examples of inspecting **network namespaces, bridges, and veth pairs**.

---

## ⚙️ Evolution of Container Runtimes

### 🧱 The Early Days: Docker in Kubernetes

* Initially, **Kubernetes bundled Docker** directly into its codebase.
* Docker wasn’t just a runtime — it included a full ecosystem (CLI, Daemon, UI, and image builder).
* Managing multiple runtimes was difficult as alternatives like **rkt** (Rocket) emerged.

### 🌍 Standardization: The Birth of OCI (2016)

To avoid tight coupling between Kubernetes and Docker, the **Open Container Initiative (OCI)** was created, defining:

* **Image specification** (how container images look and are distributed)
* **Runtime specification** (how containers are executed)

Docker wasn’t initially OCI-compliant (it predated OCI), but contributed heavily to the standard.

### 🧩 The CRI and Modern Runtimes

Kubernetes introduced the **Container Runtime Interface (CRI)**, allowing flexibility:

* **CRI** → abstraction layer between kubelet and container runtime
* Supported runtimes:

  * `containerd` (lightweight runtime from Docker)
  * `CRI-O` (purpose-built for Kubernetes)
  * `Docker` (deprecated in K8s v1.24+)
  * Others via shims (e.g., `runwasi` for WebAssembly)

---

## 🌐 Kubernetes Networking and the CNI Spec

When you initialize a cluster using `kubeadm init`, your nodes aren’t *Ready* — because Kubernetes doesn’t include a default network implementation.

This is where **CNI (Container Network Interface)** comes in.

> 🧠 **CNI** defines *how* network interfaces should be created, configured, and managed for containers — not *how* they’re implemented.

Each Pod gets a **unique IP** (even across nodes) via a CNI plugin that:

* Allocates IPs
* Configures veth pairs
* Connects Pods to the cluster network
* Ensures inter-Pod communication across nodes

---

## 🔌 How Pods, Network Namespaces, and veth Pairs Work

Every Pod consists of:

* **One pause container** (holds the network namespace)
* **User containers** (share that namespace)

When you deploy a multi-container Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: p1
      image: nginx
    - name: p2
      image: busybox
      command: ["sh", "-c", "sleep 10000"]
```

Kubernetes creates **three containers**:

1. `pause` — network namespace holder
2. `p1` — nginx
3. `p2` — busybox

All containers share the same IP and network namespace.

> 🧩 Check namespaces:

```bash
ip netns list
```

> 🧠 Inside the Pod:

```bash
kubectl exec -it mypod -- ifconfig
```

---

## 🧭 Architecture Diagram

> 📊 *Diagram Placeholder*

![Architecture Diagram](path/to/image.png)

---

## ⚙️ CNI Operations

CNI defines **five core operations**:
(Ref: [CNI Specification](https://github.com/containernetworking/cni/blob/main/SPEC.md#container-network-interface-cni-specification))

| Operation   | Description                                              |
| ----------- | -------------------------------------------------------- |
| **ADD**     | Add container to a network (create interface, assign IP) |
| **DEL**     | Remove container from a network                          |
| **CHECK**   | Verify existing container network configuration          |
| **GC**      | Garbage collect unused resources                         |
| **VERSION** | Return plugin version and capabilities                   |

Environment variables used:

```
CNI_COMMAND, CNI_CONTAINERID, CNI_NETNS, CNI_IFNAME
```

---

## 🧩 Popular CNI Plugins

| Plugin        | Description                                                      |
| ------------- | ---------------------------------------------------------------- |
| **Flannel**   | Simple overlay network using VXLAN; great for basic setups       |
| **Calico**    | Layer 3 networking with network policies and BGP support         |
| **Weave Net** | Mesh-based networking; simple to set up                          |
| **Cilium**    | eBPF-powered networking with advanced observability and security |

---

## 🧱 Example Pod YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-namespace
spec:
  containers:
    - name: p1
      image: busybox
      command: ['sh', '-c', 'sleep 10000']
    - name: p2
      image: nginx
```

---

## 🧪 Demo Walkthrough

### 1️⃣ Create the Pod

```bash
kubectl apply -f pod.yaml
kubectl get po -o wide
```

### 2️⃣ Inspect Network Namespaces

```bash
ssh node01
ip netns list
```

### 3️⃣ View veth Pairs on Host

```bash
ip link show | grep cali
```

### 4️⃣ Enter Pod Network Namespace

```bash
sudo ip netns exec <namespace-id> ip link
```

### 5️⃣ Validate Pod Interface

```bash
kubectl exec -it shared-namespace -- ip addr
```

> Output shows `eth0@if9` with assigned Pod IP, proving CNI-attached interface.

---

## 🐳 Pause Containers Explained

The **pause container**:

* Holds the Pod’s **network namespace**
* Ensures all containers share the same networking context
* Stays alive as long as the Pod exists

```bash
lsns -p <pause-pid>
```

---

## 🌉 Pod Communication (Intra, Inter, and Inter-node)

### 🧩 Intra-Pod

* Containers share same namespace → communicate via `localhost`.

### 🔄 Inter-Pod (same node)

* Virtual Ethernet pairs (veth) connect Pod namespaces to host bridges.

### 🌐 Inter-Node

* CNI plugin routes packets via encapsulation (VXLAN, BGP, etc.)
* `kube-proxy` manages iptables/IPVS for Service communication.

---

## 🧭 Kube-Proxy, CoreDNS & Service Discovery

* **kube-proxy**: Manages network rules that route traffic to Pods.
* **CoreDNS**: Provides internal DNS resolution (`<service>.<namespace>.svc.cluster.local`).
* **Services**: Abstract Pod IPs for stable communication endpoints.

---

## 🧩 Prerequisites

* Kubernetes Cluster (v1.24+)
* Installed CNI Plugin (Calico/Flannel/Cilium)
* `kubectl`, `ip`, and `ethtool` CLI tools
* SSH access to worker nodes

---

## ⚙️ Setup / Usage Instructions

```bash
# Clone the repo
git clone https://github.com/<your-org>/kubernetes-networking-explained.git
cd kubernetes-networking-explained

# Apply Pod YAML
kubectl apply -f manifests/shared-namespace.yaml

# Observe CNI behavior
kubectl get po -o wide
ssh <node> "ip netns list"
```

---

## 🤝 Contributing

Contributions are welcome!

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add new section'`)
4. Push and open a Pull Request

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 📚 Key Takeaways

✅ Kubernetes is runtime-agnostic thanks to **CRI** and **OCI**.
✅ **CNI** enables Pod networking through well-defined specs.
✅ Every Pod has a unique IP, assigned by the CNI plugin.
✅ **Pause containers** hold the shared network namespace.
✅ Inter-node communication depends on **CNI routing mechanisms**.
✅ **CoreDNS** and **kube-proxy** enable service discovery and traffic routing.

---

## 🔗 Further Reading / References

* 📘 [CNI Specification (CNCF)](https://github.com/containernetworking/cni/blob/main/SPEC.md)
* 🎥 [YouTube: Kubernetes Networking Explained by @Kubesimplify](https://www.youtube.com/watch?v=zmYxdtFzK6s)
* 🧩 [Kubernetes Docs: Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
* 🐳 [OCI Runtime Spec](https://github.com/opencontainers/runtime-spec)

---

