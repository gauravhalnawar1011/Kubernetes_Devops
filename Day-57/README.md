
---

# 🚀 Day 57 — Understanding GitOps & Popular GitOps Tools

### *Focusing on Argo CD (History, Concepts, Architecture & Challenges)*

---

## 📌 What is GitOps?

**GitOps** is a modern operational model for Kubernetes where:

* **Git = Single Source of Truth**
* Everything desired in the cluster (deployments, services, config) must exist in Git.
* A GitOps controller (like Argo CD or FluxCD) continuously **watches Git**, compares it with the **actual cluster state**, and **reconciles differences**.

In short:

> ✔️ Whatever is in Git = What must be running in Kubernetes
> ✔️ GitOps tools enforce this through **continuous reconciliation**

---

## ⭐ Popular GitOps Tools

Here are widely used tools in the GitOps ecosystem:

| Tool          | Description                                                             |
| ------------- | ----------------------------------------------------------------------- |
| **Argo CD**   | CNCF graduated project, UI-based, application-centric GitOps controller |
| **Flux CD**   | GitOps toolkit with modular controllers                                 |
| **Jenkins X** | CI/CD platform using GitOps under the hood                              |
| **Spinnaker** | Primarily focused on deployments; can integrate GitOps concepts         |

---

# 🧭 We Will Focus on *Argo CD*

---

## 🏛️ History of the Argo Project

* Created by engineers at **Applatix**
* The entire Argo project was **open-sourced**
* Now includes:

  * **Argo CD** (GitOps)
  * **Argo Workflows**
  * **Argo Events**
  * **Argo Rollouts**
  * **Argo Notifications**
* Applatix was later acquired by **Intuit**
* Current active contributors include:

  * **Akuity**, **BlackRock**, **Codefresh**, **Intuit**, **RedHat**
* Argo CD is now a **CNCF Graduated Project**
* GitHub stars: **13k+**

---

# 🧠 GitOps in a Nutshell

A GitOps tool (like Argo CD or FluxCD):

1. **Watches a Git repository**
2. Treats manifests in Git as the **desired state**
3. Continuously compares Git (desired) with Kubernetes (actual)
4. If drift happens → It **corrects the cluster** to match Git

### Example:

If we store `appA` and `appB` manifests in Git:

* Argo CD deploys them to Kubernetes
* If someone manually edits a Deployment in Kubernetes:
  ➝ Argo CD auto-corrects it back to match Git
  ➝ This gives **self-healing** capability

This is something traditional CI/CD pipelines **cannot** do because Jenkins or GitLab pipelines **run once** and stop.
GitOps controllers run **continuously**.

---

## 🔁 Reconciliation Logic (Core of GitOps)

Reconciliation in Kubernetes =

> *Ensuring actual state = desired state.*

In GitOps:

* **Desired state = Git**
* **Actual state = Kubernetes cluster**
* GitOps controller continuously tries to match the two

---

# 🏗️ Argo CD Architecture (Simplified)

GitOps tools maintain state between **Git** and **Kubernetes**, so Argo CD is implemented using multiple internal microservices:

```
           +------------------+
           |      Git Repo     |
           +------------------+
                    |
         (1) Repo Server fetches manifests
                    |
       +-------------------------+
       |     Repo Server         |
       +-------------------------+

                    |
                    v
       +-------------------------+
       |  Application Controller | <----> Kubernetes API
       |  (Reconciliation Engine)|
       +-------------------------+
                    |
                    v
       +-------------------------+
       |   API Server / UI       |
       |  (User Interaction)     |
       +-------------------------+
```

### 🔹 **1. Repo Server**

* Fetches data/manifests from Git
* Acts like a microservice responsible for interacting with Git

### 🔹 **2. Application Controller**

* Talks to Kubernetes
* Continuously compares Git state with cluster state
* Performs **sync** operations when a drift is found
* This is where reconciliation logic lives
* Runs as a **stateful component**, uses Redis for caching

### 🔹 **3. API Server (User Interface & CLI)**

* End users interact via:

  * Web UI
  * CLI (`argocd` command)
* Handles authentication
* Supports **SSO / OIDC**

### 🔹 **4. Dex (OIDC Proxy)**

* Installed by default
* Lightweight OIDC server for SSO integration
* Can connect to:

  * Google
  * GitHub
  * LDAP
  * Okta
  * Azure AD
  * Any OIDC provider

### 🔹 **5. Redis**

* Used for caching and state persistence
* Supports Application Controller when restarted

---

# 🛠️ Argo CD Installation Methods

You can install Argo CD in three ways:

1. **Using YAML manifests** (official method)
2. **Using Helm Chart**
3. **Using Operators** (community supported)

---

# ⚠️ Is GitOps Really That Simple? (Important Questions)

### ❓ If Git is the single source of truth, what about Admission Controllers?

For example:

* You deploy a Pod via GitOps
* A Kubernetes admission controller automatically injects:

  * resource limits
  * labels
  * annotations
  * sidecar containers (e.g., Istio)

Should Argo CD remove them?

This depends on whether:

* The mutation is allowed
* You configure Argo CD to ignore those fields
* You use `.spec.ignoreDifferences` settings

GitOps strict mode would indeed try to revert such changes.

---

### ❓ What happens to **existing resources** already in the cluster?

When enabling GitOps:

* Git contains only the new applications
* Kubernetes already has many existing workloads

Should GitOps delete them?

👉 **By default: NO**, unless your GitOps configuration explicitly manages those namespaces and resources.

But if Argo CD is told:

> “I own this namespace and everything inside it”

Then yes, it may delete unmanaged resources.

This is why onboarding GitOps requires:

* Proper scoping
* Deciding which namespaces are GitOps-managed
* Migrating existing resources into Git gradually

---

# 🏁 Summary

### GitOps Advantages

* Continuous state management
* Automatic self-healing
* Audit trails via Git commits
* Faster rollback (Git revert)
* Declarative + predictable deployments

### Argo CD Highlights

* CNCF graduated, widely adopted
* Great UI
* Strong community
* Supports multi-cluster GitOps
* Easy integration with SSO/OIDC

---

