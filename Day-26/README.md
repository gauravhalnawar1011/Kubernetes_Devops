
# 🚀 Day 26: Mastering Kubernetes Network Policies

A production-grade guide to securing cluster communication using Kubernetes Network Policies. This document covers the "what," "why," and "how" of implementing network security within your cluster.

---

## 🧩 Overview: What Are Network Policies?

By default, Kubernetes networking is **flat and open**. This means any Pod can communicate with any other Pod within the cluster, regardless of namespace. While simple, this is a significant security risk in a production environment.

**Network Policies** are Kubernetes resources that act as a virtual firewall for your Pods. They allow you to control the flow of network traffic at the L3/L4 (IP/TCP/UDP) layer.

### Why Do We Need Them?

Consider a standard 3-tier application:

1.  **Frontend:** Public-facing web server (e.g., Nginx, React)
2.  **Backend:** Internal API logic (e.g., Node.js, Python)
3.  **Database:** Data persistence (e.g., MySQL, PostgreSQL)



In a default cluster, if your **Frontend** Pod is compromised, the attacker can scan the internal network and connect *directly* to the **Database** Pod, bypassing the API layer entirely.

Network Policies prevent this by enforcing strict rules, such as:
* **Ingress:** Incoming traffic. (e.g., "Only allow traffic *into* the Database Pod if it comes *from* the Backend Pod").
* **Egress:** Outgoing traffic. (e.g., "Only allow traffic *out of* the Backend Pod if it's going *to* the Database Pod").

---

## 🌐 Kubernetes Networking Basics

### Default Pod Communication
When a Pod is created, it's assigned an IP address from a private network range (the Pod CIDR). Every Pod can route to every other Pod's IP address directly, even across different nodes.

### The Role of the CNI
This "magic" is handled by the **CNI (Container Network Interface)** plugin. Kubernetes itself does *not* manage network routing; it delegates this responsibility to a CNI plugin.

* A CNI plugin is typically deployed as a **DaemonSet**, meaning a copy of its agent runs on every single node in the cluster.
* When `kubelet` (the node agent) creates a Pod, it calls the CNI plugin to:
    1.  Assign an IP address to the Pod.
    2.  Set up the necessary network routes, virtual interfaces (veth pairs), and firewall rules to connect the Pod to the cluster network.

### Common CNI Plugins
Not all CNI plugins are created equal. Crucially, **not all CNIs support or enforce `NetworkPolicy` resources.**

| CNI Plugin | Supports NetworkPolicy? | Common Use Case |
| :--- | :---: | :--- |
| **Flannel** | ❌ No | Simplicity, learning environments |
| **Kindnet** | ❌ No | Default CNI for `kind` (local clusters) |
| **Weave Net** | ✅ Yes | Simple to set up, includes policy support |
| **Calico** | ✅ Yes | High-performance, rich policy features |
| **Cilium** | ✅ Yes | eBPF-based, advanced networking & security |

> **Key Takeaway:** If you intend to use Network Policies, you **must** choose a CNI that enforces them, such as Calico, Cilium, or Weave Net.

---

## ⚙️ Production Scenario Example

As discussed, our 3-tier app has a major security flaw with default networking.

* **The Risk:** `Frontend Pod` -> `Database Pod` = 💀 **COMPROMISED**
* **The Goal:**
    * `Frontend Pod` -> `Backend Pod` (Port 80) = ✅ **ALLOWED**
    * `Backend Pod` -> `Database Pod` (Port 3306) = ✅ **ALLOWED**
    * `Frontend Pod` -> `Database Pod` (Port 3306) = ❌ **DENIED**

We will implement this logic using Network Policies.

---

## 🧱 Hands-on: CNI Setup (The Foundation)

Before we can apply policies, we need a cluster running a CNI that supports them. If you're using `kind`, the default `kindnet` plugin **does not** support NetworkPolicy.

We must create a cluster *without* the default CNI and install one that does.

### Step 1: Create a `kind` Cluster with Default CNI Disabled

Create a file named `kind-multinode.yaml`:

```yaml
# kind-multinode.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true # Important! Disables kindnet
nodes:
- role: control-plane
- role: worker
- role: worker
````

Now, create the cluster using this config:

```sh
kind create cluster --config kind-multinode.yaml
```

If you run `kubectl get nodes`, you'll see them in a `NotReady` state. This is expected\! No CNI is running, so the nodes can't communicate properly.

### Step 2: Install a Policy-Enabled CNI (Calico)

We will install Calico, a popular CNI known for its robust policy enforcement.

```sh
# Apply the Calico manifests
kubectl apply -f [https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml)
```

*(**Note:** You could also use Weave Net: `kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml`)*

### Step 3: Verify the CNI Installation

Wait a minute or two for the CNI pods to deploy in the `kube-system` namespace.

```sh
# Look for calico-node pods (one per node) and calico-kube-controllers
kubectl get pods -n kube-system
```

Once the `calico-node-xxxxx` pods are `Running`, your cluster's nodes will transition to the `Ready` state.

```sh
kubectl get nodes
# NAME                 STATUS   ROLES           AGE   VERSION
# kind-control-plane   Ready    control-plane   2m    v1.29.2
# kind-worker          Ready    <none>          90s   v1.29.2
# kind-worker2         Ready    <none>          90s   v1.29.2
```

Your cluster is now ready to enforce Network Policies\!

-----

## 📦 Application Deployment Example

Let's deploy our 3-tier application. We'll use simple Pods and Services.

**Important:** Note the `labels` on each Pod. Network Policies use labels to select which Pods a policy applies to.

### 1\. Database (MySQL)

The DB Pod has the label `name: mysql`. The Service is named `db-service`.

```yaml
# 1-db-tier.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mysql-db
  labels:
    name: mysql # <-- This label is used by the policy
spec:
  containers:
  - name: mysql
    image: mysql:5.7
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: "password" # Don't do this in prod!
---
apiVersion: v1
kind: Service
metadata:
  name: db-service # <-- This is the DNS name other pods will use
spec:
  ports:
  - port: 3306
  selector:
    name: mysql
```

### 2\. Backend (API)

The Backend Pod has the label `role: backend`.

```yaml
# 2-backend-tier.yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-api
  labels:
    role: backend # <-- This label is used by the policy
spec:
  containers:
  - name: backend
    image: nicolaka/netshoot # A debug image with 'curl', 'telnet', etc.
    command: ["sleep", "3600"] # Keep the container running
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  ports:
  - port: 80
  selector:
    role: backend
```

### 3\. Frontend (Web)

The Frontend Pod has the label `role: frontend`.

```yaml
# 3-frontend-tier.yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-web
  labels:
    role: frontend # <-- This label is used by the policy
spec:
  containers:
  - name: frontend
    image: nicolaka/netshoot # A debug image for testing
    command: ["sleep", "3600"] # Keep the container running
```

Apply all three files:

```sh
kubectl apply -f 1-db-tier.yaml
kubectl apply -f 2-backend-tier.yaml
kubectl apply -f 3-frontend-tier.yaml
```

### Connectivity Test (Before Policy)

Let's verify that **everything can talk to everything**.

**Test 1: Can Backend talk to DB? (Should be YES)**

```sh
# Get a shell inside the backend-api pod
kubectl exec -it backend-api -- /bin/bash

# Inside the pod, test connection to the db-service on port 3306
telnet db-service 3306
# Expected Output:
# Trying 10.96.110.150...
# Connected to db-service.
# ^C (Press Ctrl+C to exit telnet)
exit
```

**Test 2: Can Frontend talk to DB? (This is the security risk\!)**

```sh
# Get a shell inside the frontend-web pod
kubectl exec -it frontend-web -- /bin/bash

# Inside the pod, test connection to the db-service
telnet db-service 3306
# Expected Output:
# Trying 10.96.110.150...
# Connected to db-service.  <-- 😱 SECURITY RISK!
# ^C
exit
```

As expected, our cluster is wide open. Let's fix it.

-----

## 🔐 Applying Network Policies

We will now apply a policy that **only allows Ingress to the DB from the Backend.**

Create a file named `db-policy.yaml`:

```yaml
# db-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-ingress-from-backend
spec:
  # 1. POD SELECTOR: Which pods does this policy apply to?
  podSelector:
    matchLabels:
      name: mysql # <-- Applies to our DB Pod

  # 2. POLICY TYPES: What kind of traffic are we filtering?
  policyTypes:
  - Ingress # We only care about INCOMING traffic

  # 3. INGRESS RULES: What traffic is allowed IN?
  ingress:
  - from: # Allow traffic FROM...
    - podSelector:
        matchLabels:
          role: backend # ...pods with the label 'role: backend'
    ports: # ...TO this port
    - port: 3306
      protocol: TCP
```

### Understanding the Policy

  * `spec.podSelector`: Selects the Pods to "protect." In this case, any Pod with the label `name: mysql`.
  * `spec.policyTypes`: Specifies that this policy will enforce `Ingress` (inbound) rules.
  * `spec.ingress.from`: This is a whitelist. It says "allow traffic *from* pods that match this selector."
  * `spec.ingress.from.podSelector`: The source of allowed traffic. Here, Pods with the label `role: backend`.
  * `spec.ingress.ports`: The traffic is only allowed if it's destined for port `3306`.

**A critical concept:** The moment you apply *any* policy to a Pod, it becomes **"default deny."** This means all other traffic (Ingress, in this case) that *doesn't* match this policy will be **blocked**.

### Apply the Policy

```sh
kubectl apply -f db-policy.yaml
```

### Connectivity Test (After Policy)

Let's run the exact same tests again.

**Test 1: Can Backend talk to DB? (Should still be YES)**

```sh
# Get a shell inside the backend-api pod
kubectl exec -it backend-api -- /bin/bash

# Inside the pod, test connection
telnet db-service 3306
# Expected Output:
# Trying 10.96.110.150...
# Connected to db-service.  <-- ✅ ALLOWED (Matches policy)
# ^C
exit
```

**Test 2: Can Frontend talk to DB? (Should now be NO)**

```sh
# Get a shell inside the frontend-web pod
kubectl exec -it frontend-web -- /bin/bash

# Inside the pod, test connection
telnet db-service 3306
# Expected Output:
# Trying 10.96.110.150...
# (Hangs for a few seconds...)
# telnet: connect to address 10.96.110.150: Connection timed out <-- ❌ DENIED!
exit
```

**Success\!** We have successfully isolated our database. The Frontend Pod, which has the label `role: frontend`, does not match the policy's `from` selector (`role: backend`) and is therefore blocked.

-----

## 🏗️ Production-Grade Best Practices

1.  **Start with "Default Deny":** The safest approach is to apply a "deny all" policy to an entire namespace and then explicitly whitelist *only* the traffic you need.

    ```yaml
    # default-deny-all-ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: default-deny-all-ingress
    spec:
      podSelector: {} # Selects ALL pods in the namespace
      policyTypes:
      - Ingress
      # An empty 'ingress' block means NO ingress is allowed
    ```

2.  **Use Namespaces:** Isolate environments (e.g., `dev`, `staging`, `prod`) and applications using separate namespaces. Apply default-deny policies to each production namespace.

3.  **Use Labels Logically:** A good labeling strategy (e.g., `app: myapp`, `tier: frontend`) is the foundation of effective policies.

4.  **Choose the Right CNI:** Re-iterating: **Do not** use Flannel or `kindnet` in production if you need network security. Use **Calico**, **Cilium**, or another policy-enforcing CNI.

5.  **Layer Your Security:** NetworkPolicy is one layer. Combine it with **RBAC** (who can create/modify policies), **Service Accounts** (controlling pod-to-API-server access), and **PodSecurityStandards**.

-----

## 🧰 Troubleshooting Tips

  * **"My policy doesn't seem to work\!"**

      * **Check your CNI:** This is the \#1 mistake. Run `kubectl get ds -n kube-system`. Do you see `calico-node`, `cilium`, or `weave-net`? If you see `flannel` or `kindnet`, your policies are not being enforced.
      * **Check Labels:** Use `kubectl get pod <pod-name> --show-labels`. Do your pod's labels *exactly* match the `podSelector` in your policy? A typo (`role: backend` vs. `role: back-end`) will cause it to fail.
      * **Check Namespaces:** Is your `NetworkPolicy` resource in the *same namespace* as the Pods you are trying to protect? Policies are namespace-scoped.

  * **Useful Debug Commands:**

      * `kubectl describe networkpolicy <policy-name>`: Shows details about the policy and which pods it selects.
      * `kubectl get pods -n kube-system`: Check that your CNI pods are running.
      * `kubectl logs -n kube-system -l k8s-app=calico-node`: Check the logs of the CNI agent itself (replace `calico-node` with your CNI's pod label).

-----

## 🚀 Key Takeaways

  * Kubernetes networking is **default allow**. This is dangerous for production.
  * `NetworkPolicy` resources act as firewalls for your Pods.
  * Network policies are **not** enforced by Kubernetes itself, but by the **CNI plugin**.
  * You **must** choose a CNI like Calico, Cilium, or Weave Net to use policies.
  * Use a **default-deny** strategy (block all, then whitelist) for maximum security.
  * Combine Network Policies with RBAC and other security controls for a strong **defense-in-depth** posture.

-----

## 📚 Further Reading

  * [**Kubernetes Official Docs:** Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
  * [**Calico Project:** Calico Network Policy](https://docs.tigera.io/calico/latest/network-policy/)
  * [**Cilium Project:** Network Policy Overview](https://cilium.io/docs/stable/network/policy/)

<!-- end list -->

```
```