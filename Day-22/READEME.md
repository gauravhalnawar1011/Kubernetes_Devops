
---

# 🚀 Day-22 — Deep Dive into Kubernetes Authentication & Authorization

Welcome to **Day 22** of our DevOps & Kubernetes learning series! 🎯
Today we’re going to explore **how `kubectl` communicates with the Kubernetes API server**, how it authenticates and authorizes access, and how mechanisms like **RBAC**, **Node Authorization**, and **Webhooks** come into play.

---

## 🧠 What Happens When You Run `kubectl get pods`?

When you execute:

```bash
kubectl get pods
```

✨ A lot happens behind the scenes:

* `kubectl` interacts with the **API Server** of your Kubernetes cluster.
* It needs to **authenticate** (prove who you are) and **authorize** (check what you’re allowed to do).

But wait — we never specify the API server or certificates manually in the command. So, how does it know? 🤔

That’s because `kubectl` automatically uses a configuration file called **`kubeconfig`**.

---

## ⚙️ The Kubeconfig File

By default, `kubectl` looks for this file in:

```bash
~/.kube/config
```

You can list it:

```bash
ls ~/.kube
```

And specify a custom one like this:

```bash
kubectl get pods --kubeconfig=myconfig.yaml
```

This is especially useful when you manage **multiple clusters** 🌎.

---

### 🧩 Example `kubeconfig` Structure

```yaml
apiVersion: v1
kind: Config

clusters:
  - name: development
    cluster:
      server: https://dev.example.com
      certificate-authority: /path/to/ca.crt

  - name: testing
    cluster:
      server: https://test.example.com
      certificate-authority: /path/to/ca.crt

users:
  - name: developer
    user:
      client-certificate: /path/to/client.crt
      client-key: /path/to/client.key

  - name: experimenter
    user:
      client-certificate: /path/to/experimenter.crt
      client-key: /path/to/experimenter.key

contexts:
  - name: dev-frontend
    context:
      cluster: development
      user: developer

  - name: test-storage
    context:
      cluster: testing
      user: experimenter
```

A **context** binds a **user** to a **cluster** 🧩
You can switch contexts with:

```bash
kubectl config use-context dev-frontend
```

---

## 🔐 Authentication vs Authorization

### ✅ Authentication — *Who are you?*

This determines **identity**.
Common methods:

* 🔑 **Certificates**
* 🔁 **Symmetric & Asymmetric Key Encryption**
* 🧾 **Service Accounts / Tokens**

---

### 🛡️ Authorization — *What can you do?*

Once you’re authenticated, Kubernetes checks **what actions you’re allowed** to perform.

#### 1️⃣ **ABAC (Attribute-Based Access Control)**

* Uses **policy files** to define permissions.
* Requires **API server restarts** after changes 😓
* Difficult to scale in production clusters.

#### 2️⃣ **RBAC (Role-Based Access Control)** 🧩

* Modern and widely used approach.
* You define **Roles** with permissions (e.g., `get`, `list`, `delete` pods).
* Then you create **RoleBindings** or **ClusterRoleBindings** to assign those roles to users or groups.

Example:

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

Then bind it:

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
subjects:
  - kind: User
    name: jane
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

If you update a role, permissions change instantly — **no restarts needed!** ⚡

---

## 🧩 Node Authorization

Nodes (via `kubelet`) also need to access the API server.
Kubernetes uses **Node Authorization** to determine what actions a node can perform — for example, managing pods scheduled on it.

This mode is configured in the API server like so:

```yaml
--authorization-mode=Node,RBAC
```

➡️ It first checks **Node** authorization,
➡️ then falls back to **RBAC** if needed.

---

## 🌐 Webhook Authorization

You can integrate **external systems** for authorization decisions (e.g., **OPA - Open Policy Agent** 🧠).

When a request hits the API server:

1. It’s forwarded to the OPA webhook.
2. OPA evaluates the policy.
3. It returns **allow** ✅ or **deny** ❌.

This enables **centralized, dynamic, and programmable** policy enforcement.

---

## 📂 Important File Locations

Most certificates and keys live under:

```bash
/etc/kubernetes/pki
```

Example:

```
ca.crt
ca.key
apiserver.crt
apiserver.key
apiserver-etcd-client.crt
apiserver-etcd-client.key
front-proxy-client.crt
front-proxy-client.key
sa.key
sa.pub
```

These are used for secure communication 🔒 between:

* The **API server**
* **etcd**
* **kubelet**
* **controller-manager**
* **scheduler**

---

## 🧭 Default Authorization Modes

If not specified, Kubernetes defaults to:

```yaml
--authorization-mode=AlwaysAllow
```

⚠️ This means **everyone can do everything** — not safe for production!
You can also set:

```yaml
--authorization-mode=AlwaysDeny
```

for debugging or restricted scenarios.

---

## 🧰 Recap

| Concept           | Purpose                | Example              |
| ----------------- | ---------------------- | -------------------- |
| 🪪 Authentication | Identify the user      | Certificates, Tokens |
| 🛡️ Authorization | Determine permissions  | RBAC, Node, Webhook  |
| 🧩 RBAC           | Role-based access      | Roles & Bindings     |
| 🌐 Webhook        | External policy engine | OPA                  |
| ⚙️ Node Auth      | Node access control    | kubelet API access   |

---

## 🧠 Pro Tip

When working inside Kubernetes-managed Docker containers, use:

```bash
kubectl exec -it <pod-name> -- /bin/bash
```

instead of SSH.
Kubernetes handles exec requests securely through the API server itself 🧩.

---
