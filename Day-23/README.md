
---

# 🧩 Day 23 — Kubernetes RBAC (Role-Based Access Control)

### 🎯 Objective

Understand how to manage Kubernetes **permissions** using **Roles** and **RoleBindings**.

---

## 🧠 What is RBAC?

**RBAC (Role-Based Access Control)** defines **who** can perform **what actions** on Kubernetes resources.

* **Role** → Defines *permissions* within a specific namespace
* **RoleBinding** → Assigns those permissions to a *user*, *group*, or *service account*

---

## 🔍 Step 1 — Check Current User & Permissions

To check which user you’re authenticated as:

```bash
kubectl auth whoami
```

Example output:

```
ATTRIBUTE                                           VALUE
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
```

To check if you can get pods:

```bash
kubectl auth can-i get pods
```

✅ Output: `yes` means you have permission
❌ Output: `no` means permission denied

---

## 🧍‍♂️ Step 2 — Check Permissions for Another User

Let’s test for user **adam**:

```bash
kubectl auth can-i get pods --as adam
```

Output:

```
no
```

So, Adam currently **does not have permission** to read pods.

---

## 🧾 Step 3 — Create a Role

We’ll create a **Role** that allows users to **read pods** in the `default` namespace.

### `role.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]               # "" indicates the core API group (e.g., Pods)
  resources: ["pods"]
  verbs: ["get", "watch", "list"]  # Read-only permissions
```

Apply the Role:

```bash
kubectl apply -f role.yaml
kubectl get roles
kubectl describe role pod-reader
```

Example output:

```
Name:         pod-reader
PolicyRule:
  Resources  Verbs
  ---------  -----
  pods       [get watch list]
```

---

## 🧩 Step 4 — Create a RoleBinding

Now, bind the `pod-reader` Role to user **adam**.

### `rolebinding.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: adam                      # Case-sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role                      # Can also be ClusterRole
  name: pod-reader                # Must match Role name
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```bash
kubectl apply -f rolebinding.yaml
kubectl get rolebinding
kubectl describe rolebinding read-pods
```

---

## 🧠 Step 5 — Verify Permissions

Now Adam should have access:

```bash
kubectl auth can-i get pods --as adam
```

✅ Output: `yes`

---

## 🔍 Step 6 — View All Roles in the Cluster

To list all Roles across namespaces:

```bash
kubectl get roles -A
```

To count how many exist:

```bash
kubectl get roles -A --no-headers | wc -l
```

---

## 🧾 Step 7 — Configure Credentials for Adam

Set Adam’s credentials and context:

```bash
kubectl config set-credentials adam \
  --client-key=/path/to/adam.key \
  --client-certificate=/path/to/adam.crt

kubectl config set-context adam \
  --cluster=kind-space9-v2 \
  --user=adam
```

Switch to Adam’s context:

```bash
kubectl config use-context adam
kubectl auth whoami
```

Output:

```
Username: adam
Groups:   [system:authenticated]
```

---

## 🔐 Step 8 — Verify Certificate Validity

To check how long Adam’s certificate is valid:

```bash
openssl x509 -noout -dates -in /path/to/adam.crt
```

Example:

```
notBefore=Oct 29 10:47:27 2025 GMT
notAfter=Oct 29 10:47:27 2026 GMT
```

---

## ✅ Step 9 — Test Access as Adam

```bash
kubectl get pods
```

✅ Works fine (Adam can read Pods)

```bash
kubectl get deploy
```

❌ Fails (Adam doesn’t have access to Deployments)

---

## 🌐 Step 10 — Access Kubernetes API Using `curl`

You can also make REST API calls directly:

```bash
curl --cacert /path/to/ca.crt \
     --cert /path/to/adam.crt \
     --key /path/to/adam.key \
     https://127.0.0.1:6443/api/v1/namespaces/default/pods \
     -o curl-info.yaml
```

This will fetch pod info directly from the Kubernetes API server and save it as `curl-info.yaml`.

---

## 🧩 Summary

| Component              | Purpose                          | Scope     |
| ---------------------- | -------------------------------- | --------- |
| **Role**               | Defines permissions              | Namespace |
| **RoleBinding**        | Assigns Role to a user/group     | Namespace |
| **ClusterRole**        | Defines cluster-wide permissions | Cluster   |
| **ClusterRoleBinding** | Assigns ClusterRole globally     | Cluster   |

---

### 🚀 Key Commands Reference

| Command                                | Description              |
| -------------------------------------- | ------------------------ |
| `kubectl auth whoami`                  | Check current user       |
| `kubectl auth can-i get pods`          | Check permissions        |
| `kubectl get roles -A`                 | List all roles           |
| `kubectl describe role <role-name>`    | Describe a specific role |
| `kubectl get rolebindings`             | List all rolebindings    |
| `kubectl config use-context <context>` | Switch user context      |

---

💡 **Pro Tip:**
Always start with the *principle of least privilege* — give users only the permissions they truly need.

---
