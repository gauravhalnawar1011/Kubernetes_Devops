
---

# GitOps & Argo CD – Day 56

## 📘 Overview

This repository provides a clear introduction to **GitOps**, its need, its core principles, and how tools like **Argo CD** implement GitOps for Kubernetes environments.
GitOps extends the familiar Git-based workflow used in CI processes to the world of **CD (Continuous Delivery)** and **infrastructure management**, making Git the **single source of truth** for both applications and infrastructure.

---

## ❓ What is GitOps?

**GitOps** is an operational model that uses **Git repositories as the single source of truth** for managing both **application deployments** and **infrastructure configurations**.

If your source code already benefits from Git’s:

* versioning
* collaboration
* review processes
* traceability

…then GitOps applies the same discipline to **deployments, infrastructure, clusters, and configuration changes**.

---

## 🤔 Why GitOps?

In traditional DevOps workflows:

* Application code is versioned in Git.
* Pull requests ensure proper reviews.
* CI systems (Jenkins, GitHub Actions, etc.) handle builds.

However, **CD and infra changes are often manual**, done using ad-hoc:

* kubectl commands
* shell scripts / Python scripts
* Helm / Kustomize commands

This creates major problems:

* ❌ No versioning of infra changes
* ❌ No auditing (who changed what, and when?)
* ❌ No traceability
* ❌ No review process
* ❌ No automatic rollback

### Example problem

Someone modifies Kubernetes node taints or resource configurations manually.
Later, another team member asks what changed.
Because it wasn't tracked in Git, there's **no reliable answer**.

### GitOps solves this

With GitOps:

* All changes (apps or infra) are made through Git.
* Pull requests ensure review and approval.
* Git history provides full auditability.
* A GitOps controller automatically applies approved changes.

Thus, **everything is tracked, versioned, audited, and declarative**.

---

## 🏗️ How GitOps Works

1. **Desired state** (deployments, node configs, manifests, etc.) is stored in a Git repository.
2. A GitOps tool (e.g., **Argo CD** or **Flux CD**) continuously monitors this repo.
3. When a change is merged:

   * The GitOps controller **pulls** the new state.
   * It applies the state to the Kubernetes cluster.
4. If someone manually changes the cluster:

   * The GitOps tool **detects drift**.
   * It **reverts** the change back to match Git.

Git is always the **single source of truth**.

---

## 🌍 Is GitOps Only for Kubernetes?

**No!**

GitOps is a **general operational model**, not restricted to Kubernetes.
However, tools like **Argo CD** and **Flux CD** implement GitOps specifically for Kubernetes.

Infrastructure can also be managed using GitOps workflows with:

* Terraform
* Pulumi
* Crossplane
* Custom GitOps controllers

---

## 📌 GitOps Principles (from OpenGitOps)

According to the OpenGitOps standards, a GitOps system must follow these principles:

### 1. **Declarative**

The desired system state must be expressed declaratively.
Example: Kubernetes YAML manifests describing pods, nodes, taints, resources, etc.

### 2. **Versioned & Immutable**

The desired state must be stored in a system that:

* Provides version history
* Retains all past changes
* Prevents accidental modifications

Typically this is **Git**, but S3 or other versioned stores can also work.

### 3. **Pulled Automatically**

Software agents automatically **pull** the latest desired state from the source.
Triggering can be:

* Pull-based
* Push-based (via webhooks)

### 4. **Continuously Reconciled**

GitOps controllers constantly compare:

* **Actual cluster state**
* **Desired state in Git**

If drift is detected → it reconciles back to the desired state.

---

## 🔐 Advantages of GitOps

| Benefit              | Description                                                      |
| -------------------- | ---------------------------------------------------------------- |
| **Security**         | Only Git changes are applied; manual changes are reverted.       |
| **Versioning**       | Every change is tracked with full audit trails.                  |
| **Consistency**      | Ensures clusters always match Git-defined state.                 |
| **Stability**        | Easy rollbacks using Git history.                                |
| **Scalability**      | Essential when managing large numbers of clusters and resources. |
| **Automation**       | Enables automatic deployment upon Git changes.                   |
| **Drift Correction** | Continuously overwrites unauthorized changes.                    |

---

## 🚀 GitOps Tools

Popular GitOps tools include:

* **Argo CD**
* **Flux CD**

Both are widely used, especially for Kubernetes-based GitOps workflows.

---

## 📚 Reference

Official neutral definition and principles of GitOps:
👉 [https://github.com/open-gitops](https://github.com/open-gitops)

---
