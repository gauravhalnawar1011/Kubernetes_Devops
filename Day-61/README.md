
---

# 🚀 Day-61: Argo CD UI – GitOps in Action

This document explains **why we use each component of the Argo CD UI**, how they fit into the **GitOps workflow**, and **step-by-step guidance** for configuring applications, repositories, projects, and clusters.

---

## ✅ Why Argo CD?

Argo CD is a **GitOps continuous delivery tool for Kubernetes**.
It ensures that:

* Your **cluster state always matches Git**
* Deployments are **version-controlled**
* Rollbacks are **fast and safe**
* Manual configuration drift is **eliminated**

---

# 🧩 Argo CD UI Components – Why We Need Each One

---

## 1️⃣ Applications

**Purpose:**
Used to **deploy and continuously sync applications** from Git to Kubernetes.

### ✅ Why We Need It:

* Connects **Git repo → Kubernetes cluster**
* Keeps apps **always in sync**
* Detects and fixes **configuration drift**
* Manages **rollbacks & health status**

### 🔧 What We Configure Here:

* Application Name
* Project
* Git Repository
* Branch / Revision
* Path inside the repo
* Destination Cluster & Namespace
* Sync Policy (Manual / Auto)

---

## 2️⃣ Settings → Projects

**Purpose:**
Projects act as **logical groups and security boundaries** for applications.

### ✅ Why We Need It:

* Controls **which apps can run where**
* Provides **namespace isolation**
* Limits **repo, cluster, and namespace access**
* Ideal for **multi-team & microservices environments**

### ✅ Example:

For an **eCommerce App**, we can create a project called `ecommerce` and allow:

* Frontend
* Backend
* Database
  to run under the same project with access control.

### 🔧 While Creating a Project:

* Project Name
* Description
* Allowed Repositories
* Allowed Clusters
* Allowed Namespaces

---

## 3️⃣ Settings → Repositories

**Purpose:**
This is where we **connect Git repositories** to Argo CD.

### ✅ Why We Need It:

* Argo CD **pulls Kubernetes manifests from Git**
* Securely stores **credentials**
* Supports **multiple SCM tools**

### ✅ Supported SCMs:

* GitHub
* GitLab
* Bitbucket
* Helm Repositories
* OCI Repositories

---

### 🔗 Connection Methods Explained

---

### ✅ VIA HTTP / HTTPS

**Used when Git requires username & password or token**

**Fields:**

* Repository URL
* Username
* Password
* Bearer Token
* TLS Certificates
* Skip SSL Verification
* Enable Git LFS
* Enable OCI
* Azure Workload Identity

✅ **Best Practice:**
Use **tokens instead of passwords**.

---

### ✅ VIA SSH

**Used when using SSH keys instead of passwords**

**Fields:**

* Repository URL
* SSH Private Key
* Skip SSL Verification
* Enable Git LFS

✅ **Most secure method for production**

---

### ✅ VIA GitHub App

**Enterprise-grade authentication using GitHub Apps**

**Fields:**

* GitHub App ID
* Installation ID
* Private Key
* Repository URL

✅ **Best for large organizations**

---

### ✅ VIA Google Cloud

**For GCP-based Git integration**

**Fields:**

* Repository URL
* GCP Service Account Key

---

## 4️⃣ Settings → Repository Certificates & Known Hosts

**Purpose:**
Manages **trusted SSL certificates and SSH known hosts**.

✅ Prevents:

* MITM attacks
* Untrusted repo connections

---

## 5️⃣ Settings → GnuPG Keys

**Purpose:**
Used for **commit signature verification**.

✅ Ensures:

* Git commits are **verified & trusted**
* Prevents **tampered deployments**

---

## 6️⃣ Clusters

**Purpose:**
Manages **all Kubernetes clusters connected to Argo CD**.

### ✅ Why We Need It:

* Deploy applications to **multiple clusters**
* Enables **multi-cloud and multi-environment GitOps**

---

### 🔐 IMPORTANT: CLI Login Required to Add More Clusters

Before adding a new cluster, you must **log in using the Argo CD CLI**:

```bash
argocd login <ARGOCD_SERVER>
```

You will need:

* ✅ Username
* ✅ Password

Then add a cluster:

```bash
argocd cluster add <kube-context>
```

✅ This securely registers the cluster with Argo CD.

---

## 7️⃣ Accounts

**Purpose:**
Manages **users and RBAC access**.

✅ Used to:

* Create users
* Assign permissions
* Enforce security policies

---

## 8️⃣ Appearance

**Purpose:**
Controls **UI themes and display settings**.

✅ Used for:

* Dark / Light mode
* Custom UI experience

---

## 9️⃣ User Info

**Purpose:**
Used to **update the admin password and user details**.

✅ Enhances:

* Security
* Personal access management

---

## 🔟 Documentation & CLI Access

From the UI, users can:

* Read official documentation
* Download Argo CD CLI
* Access Argo CD API

✅ Useful for:

* Automation
* CI/CD pipelines
* Scripting deployments

---

# 🛠️ Application Creation – Field-by-Field Explanation

---

## ✅ GENERAL

| Field              | Purpose                      |
| ------------------ | ---------------------------- |
| Application Name   | Unique name of app           |
| Project Name       | Security boundary            |
| Sync Policy        | Manual or Automatic          |
| Deletion Finalizer | Prevents accidental deletion |

---

## ✅ SYNC OPTIONS

* Skip Schema Validation
* Auto-Create Namespace
* Prune Last
* Apply Out of Sync Only
* Respect Ignore Differences
* Server-Side Apply
* Prune Propagation Policy (Foreground)
* Replace
* Retry

✅ These control **how safely and efficiently your app syncs with the cluster**

---

## ✅ SOURCE

| Field          | Purpose           |
| -------------- | ----------------- |
| Repository URL | Git source        |
| Revision       | Branch / Tag      |
| Path           | Manifest location |

---

## ✅ DESTINATION

| Field       | Purpose              |
| ----------- | -------------------- |
| Cluster URL | Target cluster       |
| Namespace   | Deployment namespace |

---

## ✅ DIRECTORY OPTIONS

* Recurse Directories
* Include / Exclude Files
* External Variables

✅ Useful for **Helm, Kustomize, and large repo structures**

---

# ✅ Summary: Why Each UI Component Matters

| Component    | Why We Need It          |
| ------------ | ----------------------- |
| Applications | Deploy & sync workloads |
| Projects     | Security & isolation    |
| Repositories | Git integration         |
| Clusters     | Multi-cluster delivery  |
| Accounts     | Access control          |
| Appearance   | UI customization        |
| GnuPG Keys   | Secure Git verification |
| Certificates | Secure communication    |

---

# ✅ Final GitOps Value

With Argo CD UI:

* Git becomes the **single source of truth**
* Deployments become **automated, auditable, and secure**
* Teams gain **faster, safer, and scalable Kubernetes delivery**

---


