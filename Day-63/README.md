

---

# **Day-63 – Argo CD: Application, App-of-Apps Pattern & ApplicationSet**

This document explains how Argo CD manages workloads declaratively using **Application**, **App-of-Apps**, and **ApplicationSet** patterns. It also includes working YAML examples and corrected conceptual details based on our discussions.

---

# **1. Deploying Applications With Argo CD (CLI/UI)**

Argo CD allows deploying applications through:

* Its **UI (Web Dashboard)**
* Its **CLI (`argocd`)**
* **Declarative YAML** using GitOps

While it is possible to create apps manually in UI/CLI, that approach does **not follow true GitOps principles**.
A GitOps workflow requires:

* Application configuration stored in Git
* Automatic reconciliation from Git to the cluster
* Declarative, repeatable deployment definitions

To achieve this, Argo CD exposes a Kubernetes-native object called **Application**.

---

# **2. Argo CD Application – A Kubernetes Resource**

An **Application** is simply another Kubernetes resource, just like Deployments, ConfigMaps, or Services.

It contains:

### **Key Fields**

| Field           | Description                                       |
| --------------- | ------------------------------------------------- |
| **project**     | Argo CD project the app belongs to                |
| **source**      | Git repo, path, revision, Helm/Kustomize settings |
| **destination** | Target cluster + namespace                        |
| **syncPolicy**  | Automation, pruning, self-healing, sync options   |

---

# **3. Example Application YAML (Corrected)**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo1
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default

  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    path: helm-guestbook

  destination:
    server: https://kubernetes.default.svc
    namespace: default

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - Validate=false
      - PruneLast=true
      - RespectIgnoreDifferences=true
      - Replace=true
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
      - ServerSideApply=true

    retry:
      limit: 2
      backoff:
        duration: 5s
        maxDuration: 3m0s
        factor: 2
```

---

# **4. Why Do We Need App-of-Apps?**

A single Application can deploy **only one Git path to one cluster/namespace**.
If the same service must run in:

* dev
* qa
* staging
* prod
* multiple clusters

… we would require **multiple Application objects**.

To manage many apps together, or bootstrap a whole cluster, we use the **App-of-Apps pattern**.

---

# **5. App-of-Apps Pattern (Cluster Bootstrapping)**

The App-of-Apps pattern uses **one "root" Application** that points to a Git folder containing **multiple child Applications**.

This is commonly used to:

* Bootstrap a new Kubernetes cluster
* Install multiple microservices at once
* Organize GitOps repositories cleanly
* Deploy Argo CD itself (self-managed GitOps)

### **How it works**

* The root Application syncs
* It discovers Application YAML files in Git
* Argo CD creates and manages all those child Applications

### **Limitation**

App-of-Apps is powerful but:

* **Static** (no templating)
* **Cannot dynamically generate Applications**
* **Not ideal for multi-cluster rollouts**

That is why **ApplicationSet** was created.

---

# **6. App-of-Apps Example (Root Application)**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app-demo
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
    targetRevision: main
    path: apps            # folder containing child apps

  destination:
    server: https://kubernetes.default.svc
    namespace: argocd

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

All YAML files in `apps/` representing child Applications will be deployed automatically.

---

# **7. ApplicationSet – The Dynamic Application Factory**

ApplicationSet solves the limitations of App-of-Apps.

Think of it as:

> **“An application factory that generates Applications dynamically based on inputs.”**

### **Key Features**

* Supports **templating**
* Supports **loops, variables, and generators**
* Generates Applications for:

  * Many clusters
  * Many microservices
  * Many environments
  * Git pull requests
  * Folder structures in Git

### **Generators**

ApplicationSet includes:

* **List generator**
* **Git directory generator**
* **Cluster generator**
* **Matrix generator**
* **Pull Request generator**

This is why ApplicationSet is preferred for **multi-cluster deployments, PR preview environments, and large microservice architectures**.

---

# **8. ApplicationSet Example**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices-list
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: payment
          - name: user
          - name: order

  template:
    metadata:
      name: "{{name}}-app"
    spec:
      project: default
      source:
        repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
        targetRevision: main
        path: "apps/{{name}}"
      destination:
        server: https://kubernetes.default.svc
        namespace: "{{name}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

# **9. Corrected Concept Summary**

### **Application**

* One deployment unit (one Git path → one cluster/namespace)

### **Applications (plural)**

* Many individual Application objects

### **App-of-Apps**

* One Application deploys other Applications
* Good for bootstrapping and grouping
* Static, no templating

### **ApplicationSet**

* Dynamic generator of Applications
* Supports templating & multi-cluster deployments
* The scalable, modern replacement for large deployments

---

# **10. When to Use What**

| Use Case                                | Best Choice                   |
| --------------------------------------- | ----------------------------- |
| Deploy one microservice                 | Application                   |
| Deploy 5–10 microservices manually      | App-of-Apps                   |
| Deploy dozens of services at scale      | ApplicationSet                |
| Deploy one service to multiple clusters | ApplicationSet                |
| Create environments from PRs            | ApplicationSet (PR Generator) |

---

# **11. Summary**

On Day-63, we explored how Argo CD manages applications declaratively using:

* Application (base unit)
* App-of-Apps (bootstrapping pattern)
* ApplicationSet (dynamic factory)

You now have:

* A corrected understanding of the patterns
* Production-grade YAML examples
* A complete App-of-Apps structure
* A clear explanation of ApplicationSet generators

---

