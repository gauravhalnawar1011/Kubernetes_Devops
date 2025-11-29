
---

# 📘 Pod Security Standards, Linux Capabilities & Security Context

**Day-54 — Kubernetes Security Deep Dive**

This document provides a professional, structured explanation of **Pod Security Standards (PSS)**, **Linux Capabilities**, and **Security Context** settings in Kubernetes. It also includes hands-on examples, YAML manifests, expected outputs, and validation tests aligned with **CKA/CKS exam expectations**.

---

## 🔐 Overview

Kubernetes Pod Security revolves around controlling **privileges**, **identity**, and **kernel-level capabilities** available to workloads.
Two core areas define workload security:

1. **Security Context** (Pod & Container level)
2. **Linux Capabilities** (Container level)

These features help enforce the principle of **least privilege**, harden workloads, and comply with Pod Security Standards.

---

# 1. 🛡 Security Context in Kubernetes

The **Security Context** defines privilege and access settings for Pods and Containers.

Kubernetes docs reference:
➡ *K8s Official Docs:* [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

A **container’s PID 1** defines the main process identity. By configuring security context fields, we control how that process behaves.

### Key SecurityContext Fields

---

### ▶ **runAsUser**

Defines the **UID** of the container’s main process.

* `runAsUser: 1000` → Safe, non-root
* `runAsUser: 0` → Full root privileges ❌ **Not recommended**

---

### ▶ **runAsGroup**

Specifies the **primary GID** for the process.

Groups can have multiple users, similar to Linux system groups like `sudo`, `wheel`, etc.

---

### ▶ **runAsNonRoot**

Boolean that **prevents container from running as UID 0**.

* Very important for security
* When set to `true`, the container will fail unless using non-root UID

---

### ▶ **fsGroup**

Defines group ownership for all mounted volumes.

If `fsGroup: 2000`, all files created in volumes will belong to GID **2000**.

---

### ▶ **allowPrivilegeEscalation**

Prevents a process from gaining more privileges (e.g., via `sudo`, SUID binaries).

* `allowPrivilegeEscalation: false` is required for **restricted PSS**
* Enabled by default unless explicitly disabled

---

# 2. 🧩 Linux Capabilities

Reference:
➡ [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)
➡ Linux capabilities documentation from RedHat Blogs / Kernel docs.

Linux capabilities allow fine-grained control instead of full root privileges.

### Key Capabilities (often seen in exam questions)

| Capability        | Purpose                                             | Risk           |
| ----------------- | --------------------------------------------------- | -------------- |
| **CAP_NET_ADMIN** | Modify network interfaces, firewall, routing tables | High           |
| **CAP_SYS_ADMIN** | Broad system admin: mount FS, change kernel params  | Extremely High |
| **CAP_SYS_TIME**  | Modify system clock                                 | Medium         |

By default, containers start with a limited set of capabilities.

### Capability Management

Use:

* `add: ["<CAP>"]` – add specific capabilities
* `drop: ["ALL"]` – drop everything (recommended)

Dropping **ALL** capabilities is essential for **restricted** pod security standard.

---

## 3. 🧪 Hands-On: Capability Demo

### `capabilities.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-demo
spec:
  containers:
  - name: app
    image: busybox:1.28
    command: ["sh", "-c", "sleep 1h"]
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
        drop: ["ALL"]
```

Apply & test:

```bash
kubectl apply -f capabilities.yaml
kubectl exec -it secure-demo -- sh
```

Inspect interfaces:

```bash
ip link show
```

Try creating dummy interface:

```
ip link add dummy0 type dummy
```

Try mounting filesystem (should fail):

```
mount -t tmpfs tmpfs /tmp/test
```

Expected: **permission denied**, because `SYS_ADMIN` was not added.

---

# 4. 🔐 Pod-Level SecurityContext Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    runAsNonRoot: true
    fsGroup: 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox:1.28
    command: ["sh", "-c", "sleep 1h"]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      runAsUser: 1000
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

### Validate user identity inside container:

```bash
kubectl exec -it secure-demo -- sh

id
# uid=1000 gid=3000 groups=2000,3000
```

Try privilege escalation:

```bash
su -
# Fails (as expected)
```

---

# 5. ⚠ Root Privilege Example (NOT recommended)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: root-user-test
spec:
  containers:
  - name: root-container
    image: busybox
    command: ["sleep", "3600"]
    securityContext:
      runAsUser: 0
```

Running `id`:

```
uid=0(root) gid=0(root) groups=0(root),10(wheel)
```

---

# 6. 🛡 Kubernetes Pod Security Standards (PSS)

Reference:
➡ [https://kubernetes.io/docs/concepts/security/pod-security-standards/](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

PSS defines three profiles:

| Standard       | Security Level | Description                       |
| -------------- | -------------- | --------------------------------- |
| **Privileged** | Low            | No restrictions                   |
| **Baseline**   | Medium         | Limited restrictions              |
| **Restricted** | High           | Strong isolation, least privilege |

Restricted Pods **must**:

* Drop all capabilities
* Use `runAsNonRoot`
* Use non-root UID & GID
* Forbid privilege escalation
* Disallow hostPath, hostPID, hostNetwork
* Require seccomp `RuntimeDefault`

---

# 7. 🧪 Enforce Restricted Namespace

### Create namespace:

```bash
kubectl create namespace restricted-ns
```

### Apply PSS labels:

```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

---

# 8. 🟢 Restricted Compliant Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: restricted-ns
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      capabilities:
        drop: ["ALL"]
```

---

# 9. ❌ Violation Pod — Should FAIL under Restricted PSS

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-violations
  namespace: restricted-ns
spec:
  containers:
  - name: insecure-app
    image: nginx
    securityContext:
      privileged: true
      runAsUser: 0
      allowPrivilegeEscalation: true
      capabilities:
        add: ["SYS_ADMIN", "NET_ADMIN"]
    volumeMounts:
    - name: host-root
      mountPath: /host
  volumes:
  - name: host-root
    hostPath:
      path: /
      type: Directory
```

Applying:

```bash
kubectl apply -f all-violations-pod.yaml
```

Expected Output:

```
Error from server (Forbidden): violates PodSecurity "restricted:latest" ...
```

---

# 10. ✔ Verification & Testing

Apply compliant pod:

```bash
kubectl apply -f restricted-compliant-pod.yaml
```

Testing restricted rules:

```bash
kubectl apply -f violation-privileged.yaml
kubectl apply -f violation-root.yaml
kubectl apply -f violation-hostnetwork.yaml
```

Check violation events:

```bash
kubectl get events -n restricted-ns
```

Confirm compliant pod running:

```bash
kubectl get pods -n restricted-ns
```

---

# 🎯 CKA / CKS Exam Focus Points

### 🔹 Must-Know SecurityContext Fields

* `runAsUser`
* `runAsGroup`
* `runAsNonRoot`
* `allowPrivilegeEscalation`
* `fsGroup`
* `seccompProfile`

### 🔹 Linux Capabilities

* Add minimal needed
* Prefer `drop: ["ALL"]`

### 🔹 Pod Security Standards

* Restricted namespaces
* Required labels
* Behavior when violations occur

### 🔹 Hands-on Practice

* Create secure Pods
* Test violations
* Understand error messages

---

# ✅ Conclusion

By understanding and applying **Security Context**, **Linux Capabilities**, and **Pod Security Standards**, you strengthen workload isolation and ensure Kubernetes clusters follow **best security practices**.

This README serves as a complete, production-ready reference for learning, labs, and exam preparation.

---
