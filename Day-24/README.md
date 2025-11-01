
---

# 🧩 Day 24 — Kubernetes RBAC: ClusterRoles & ClusterRoleBindings



## 🧠 Overview

In Kubernetes, **RBAC (Role-Based Access Control)** is a powerful authorization mechanism that controls access to cluster resources.

Previously (Day 23), we learned that:

* **Roles** are namespace-scoped.
* **RoleBindings** grant those Role permissions to users or service accounts **within that namespace**.

Today (Day 24), we move beyond the namespace boundary and explore **ClusterRoles** and **ClusterRoleBindings** — the RBAC resources that govern **cluster-wide access**.

---

## ⚙️ Key Concepts

### 🔹 Roles (Namespace Scoped)

A **Role** defines permissions (verbs) for namespaced resources such as:

* Pods
* Services
* Deployments
* ReplicaSets

> 📍 These are limited to a **single namespace**.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

---

### 🔹 ClusterRoles (Cluster Scoped)

A **ClusterRole** provides permissions that are **not limited to a namespace**.

They can:

* Access **cluster-scoped resources** like Nodes, Namespaces, PersistentVolumes.
* Grant the same permissions across **all namespaces**.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
```

---

### 🔹 RoleBinding vs. ClusterRoleBinding

| Resource Type          | Scope        | Binds To    | Typical Use               |
| ---------------------- | ------------ | ----------- | ------------------------- |
| **RoleBinding**        | Namespace    | Role        | Namespace-specific access |
| **ClusterRoleBinding** | Cluster-wide | ClusterRole | Cluster-wide access       |

Example ClusterRoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: reader-binding-nodes
subjects:
- kind: User
  name: adam
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 🧩 Step-by-Step Implementation

### Step 1 — Identify Resource Scopes

To see which resources are **namespaced** and which are **cluster-scoped**:

```bash
# Namespaced resources
kubectl api-resources --namespaced=true

# Cluster-scoped resources
kubectl api-resources --namespaced=false
```

Example output:

```
NAMESPACED RESOURCES (true)
---------------------------------
pods, services, deployments, secrets, configmaps, jobs, etc.

CLUSTER-SCOPED RESOURCES (false)
---------------------------------
nodes, namespaces, clusterroles, persistentvolumes, storageclasses, etc.
```

---

### Step 2 — Create a ClusterRole

We’ll create a ClusterRole to allow **read-only access to all nodes** in the cluster.

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
```

Verify:

```bash
kubectl get clusterrole | grep node-reader
```

---

### Step 3 — Create a ClusterRoleBinding

Bind the new ClusterRole (`node-reader`) to a user (`adam`):

```bash
kubectl create clusterrolebinding reader-binding-nodes \
  --clusterrole=node-reader \
  --user=adam
```

Confirm the binding:

```bash
kubectl describe clusterrolebinding reader-binding-nodes
```

---

### Step 4 — Test User Permissions

Use the `kubectl auth` command to verify the new permissions:

```bash
kubectl auth can-i get nodes --as adam
```

✅ Output: `yes`

Now try deleting a node:

```bash
kubectl auth can-i delete nodes --as adam
```

❌ Output: `no`

> Adam has read-only access to nodes, following the **principle of least privilege**.

---

### Step 5 — Switch User Context (Optional)

If you’ve created an `adam` user with client certificates, you can switch context:

```bash
kubectl config use-context adam
kubectl auth whoami
```

Output:

```
Username: adam
Groups: [system:authenticated]
```

Now test commands directly as `adam`.

---

## 🧠 Key Takeaways

| Concept                | Scope        | Description                                                |
| ---------------------- | ------------ | ---------------------------------------------------------- |
| **Role**               | Namespace    | Defines access to namespaced resources                     |
| **RoleBinding**        | Namespace    | Assigns Role to user/group/service account                 |
| **ClusterRole**        | Cluster-wide | Defines access to cluster-level or all namespaces          |
| **ClusterRoleBinding** | Cluster-wide | Binds ClusterRole to a user/group/service account globally |

---

## 🧰 Useful Commands Reference

| Command                                            | Description                          |
| -------------------------------------------------- | ------------------------------------ |
| `kubectl auth whoami`                              | Identify the current Kubernetes user |
| `kubectl auth can-i <verb> <resource> --as <user>` | Check if a user has permission       |
| `kubectl api-resources --namespaced=true`          | List all namespaced resources        |
| `kubectl api-resources --namespaced=false`         | List all cluster-scoped resources    |
| `kubectl get clusterrolebindings`                  | View all cluster-wide bindings       |
| `kubectl describe clusterrole <name>`              | Inspect role permissions             |

---

## 🔒 Security Best Practices

1. **Follow the Principle of Least Privilege (PoLP)** — grant only what’s needed.
2. **Use separate service accounts** for automation and workloads.
3. **Audit RBAC policies regularly** using:

   ```bash
   kubectl get clusterrolebindings -A
   kubectl get roles,rolebindings -A
   ```
4. **Avoid binding cluster-admin roles** directly to users.
5. **Integrate with external identity systems** (like OIDC or LDAP) for secure access control.

---

## 🧰 Troubleshooting Tips

| Issue                                      | Likely Cause                            | Fix                                           |
| ------------------------------------------ | --------------------------------------- | --------------------------------------------- |
| `User cannot access resource`              | Role/Binding missing or incorrect scope | Check using `kubectl describe rolebinding`    |
| `resource is not namespace scoped` warning | Using RoleBinding for cluster resource  | Use `ClusterRoleBinding` instead              |
| `forbidden` errors                         | Role lacks verb                         | Add missing verbs like `get`, `list`, `watch` |

---

## 📘 Summary

Kubernetes RBAC provides a **fine-grained, flexible** way to manage access.
By separating **Roles** (namespace level) from **ClusterRoles** (cluster level), Kubernetes ensures that administrators can assign precise permissions — reducing security risks and maintaining scalability.

RBAC isn’t just about control — it’s about **trust, clarity, and consistency** across environments.

---

## 🙌 Credits

Special thanks to:

* **Piyush Sachdeva** — for insightful RBAC walkthroughs
* **The CloudOps Community** — for hands-on Kubernetes learning sessions

---

## 🧷 Related Resources

* [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
* [Kubernetes Authorization Concepts](https://kubernetes.io/docs/reference/access-authn-authz/authorization/)
* [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/overview/)

---

## 🏷️ Hashtags

`#Kubernetes` `#RBAC` `#DevOps` `#ClusterRole` `#CloudNative` `#Security` `#K8s` `#LearningJourney` `#OpenSource` `#CloudOps`

---

