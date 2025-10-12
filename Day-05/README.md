---

#  Day 05: Kubernetes Architecture

### DevOps Learning Series

---

##  Introduction

In the previous sessions, we explored **containers**, **Docker**, and how containerization helps in building portable, consistent environments.
Now, it’s time to understand **how Kubernetes (K8s)** orchestrates and manages those containers at scale.

Kubernetes may look complex at first — but once you understand its **architecture** and how the **control plane** communicates with **worker nodes**, it becomes much clearer.
This session dives deep into each component, its role, and how everything works together to keep your applications running reliably.

---

##  Understanding the Kubernetes Architecture

Kubernetes follows a **master-worker (control plane–node)** architecture:

* **Control Plane (Master Node):**
  The “brain” of the cluster — makes global decisions, maintains cluster state, and handles orchestration logic.

* **Worker Nodes:**
  The “hands” of the cluster — actually run the containerized workloads (your applications) in **Pods**.

Each **node** (control or worker) is typically a **virtual machine (VM)** or a **physical server** with Kubernetes components installed.

A simplified diagram (placeholder):

```
[ User (kubectl) ] --> [ API Server ] --> [ etcd | Scheduler | Controller Manager ]
                                ↓
                           [ Kubelet ]
                                ↓
                             [ Pods ]
```

<img width="1024" height="1024" alt="Image" src="https://github.com/user-attachments/assets/199fd40c-9c4f-4201-bbf7-6b527d17287a" />

---

## ⚙️ Control Plane Components

The **control plane** manages the cluster — it decides **what** should run and **where**.
Let’s break down each component:

### 1. **API Server (`kube-apiserver`)**

* Acts as the **entry point** for all administrative commands and cluster communication.
* Validates and processes requests (from `kubectl`, other control plane components, or external systems).
* Serves as the **gateway** to the cluster — all other components interact through it.
* Only the API Server communicates directly with **etcd**.

 *Analogy:* Think of it as the “front desk” of Kubernetes — everything goes through it.

---

### 2. **etcd**

* A **distributed, consistent key-value store** used by Kubernetes to store **cluster state and configuration**.
* Keeps track of everything — Pods, Nodes, ConfigMaps, Secrets, and more.
* The API Server is the **only component** allowed to read/write to etcd directly.

 *If etcd goes down, the cluster loses its source of truth.*

---

### 3. **Scheduler (`kube-scheduler`)**

* Responsible for **assigning newly created Pods** to appropriate Worker Nodes.
* Makes scheduling decisions based on:

  * Resource requirements (CPU, memory)
  * Node affinity/taints
  * Constraints and policies
* Once a node is selected, the Scheduler informs the API Server of the placement decision.

 *It ensures workloads are balanced across nodes.*

---

### 4. **Controller Manager (`kube-controller-manager`)**

* Runs multiple **controllers**, each responsible for maintaining a specific part of cluster state:

  * **Node Controller:** Manages node health.
  * **Replication Controller:** Ensures desired number of Pods are running.
  * **Namespace Controller:** Handles namespace creation/deletion.
* Continuously monitors objects and takes corrective action if the actual state diverges from the desired state.

 *Think of it as the cluster’s “autopilot” — it keeps everything in sync.*

---

##  Worker Node Components

Worker nodes are where **applications actually run**.
Each node runs a few key components to communicate with the control plane and execute tasks.

### 1. **Kubelet**

* An **agent** that runs on every node.
* Listens for instructions from the API Server.
* Ensures that containers described in Pod manifests are running and healthy.
* Reports node and Pod status back to the control plane.

 *Kubelet = Executor and reporter.*

---

### 2. **Kube-Proxy**

* Manages **networking** and **load balancing** for Pods and Services.
* Maintains network rules on nodes (using iptables or IPVS) to enable **Pod-to-Pod** and **Pod-to-Service** communication.
* Ensures traffic is routed correctly inside and outside the cluster.

 *It’s the traffic manager of your node.*

---

### 3. **Pods**

* The **smallest deployable unit** in Kubernetes.
* Encapsulates one or more containers that share storage and network resources.
* Each Pod runs on a **single node**.
* Typically hosts one main application container, plus optional sidecars (e.g., for logging or monitoring).

 *A Pod is like a wrapper that protects and runs your containerized app.*

---

##  How Kubernetes Works (Step-by-Step Flow)

Let’s trace what happens when you run a simple command:

```bash
kubectl apply -f pod.yaml
```

Here’s the simplified flow:

1. **User Interaction:**
   You (the user) send a request using `kubectl` — this talks to the **API Server**.

2. **API Server Validation:**
   The API Server authenticates, validates, and authorizes the request.

3. **Persisting State in etcd:**
   The API Server records the new “desired state” (e.g., a Pod definition) into **etcd**.

4. **Scheduling Decision:**
   The **Scheduler** notices a new unscheduled Pod and decides which **Worker Node** should host it.

5. **Kubelet Execution:**
   The **Kubelet** on that node receives instructions from the API Server and starts the Pod using the container runtime (like containerd or Docker).

6. **Pod Running:**
   Once the Pod is up, its status is reported back to the API Server → etcd is updated → you see it as “Running” when you check with:

   ```bash
   kubectl get pods
   ```

 **In short:**
`kubectl` → **API Server** → **etcd** → **Scheduler** → **Kubelet** → **Pod Running**

---

## 🗝️ Key Takeaways

* **Control Plane** = Brain of Kubernetes (makes global decisions).
* **Worker Nodes** = Executors (run workloads).
* **API Server** = Gateway for all cluster communication.
* **etcd** = Central data store (source of truth).
* **Scheduler** = Finds the best node for workloads.
* **Controller Manager** = Keeps cluster state in sync.
* **Kubelet** = Executes instructions on nodes.
* **Kube-Proxy** = Enables service and pod networking.
* **Pods** = Smallest deployable units in Kubernetes.

 Together, these components ensure that Kubernetes provides **self-healing**, **scalable**, and **automated orchestration** for modern cloud-native applications.

---

##  References / Next Steps

* [Official Kubernetes Documentation – Architecture](https://kubernetes.io/docs/concepts/overview/components/)
* [Learn Kubernetes Basics (Interactive Tutorial)](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
* **Next Lesson →** *Day 06: Deployments, ReplicaSets & Services in Kubernetes*

---

 *Tip:* Don’t worry if it feels like a lot. Once you start deploying and observing workloads, these components will make perfect sense in action.

---
