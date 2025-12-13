
---

# Argo CD Best Practices for GitOps Specialists

**Application Modeling, Dependency Management, Health Checks, Configuration, and Installation**

---

## 1. Argo CD Fundamentals and Application Definition

### Kubernetes Objects and Argo CD’s Role

Kubernetes is composed of loosely coupled **API objects** (Deployments, Services, CRDs, ConfigMaps, etc.). These objects are reconciled independently by their respective controllers under an **eventually consistent** control plane.

### Argo CD Application as the Atomic Unit of Deployment

An **Argo CD Application** is a Custom Resource Definition (CRD) that represents the **atomic unit of deployment** in GitOps:

* It is a **declarative mapping** between:

  * A Git repository (source of truth)
  * A target Kubernetes cluster and namespace
* It manages a **group of related Kubernetes resources** as a single operational unit.
* Argo CD continuously:

  * Detects drift
  * Reports health and sync status
  * Reconciles actual state back to the desired Git state

Key characteristics:

* One Application = one independently deployable workload.
* Sync ordering **only applies within a single Application**, not across multiple Applications by default.
* Kubernetes resources are applied using **phases and sync waves** during a sync operation.

---

## 2. Handling Cross-Application Dependencies and Ordering

Argo CD does **not natively enforce inter-Application dependency graphs**. Instead, there are three accepted strategies to manage dependencies across Applications:

1. **Eventual Consistency**
2. **App-of-Apps Pattern**
3. **ProgressiveSyncs (via ApplicationSets)**

Each approach has trade-offs and specific operational prerequisites.

---

### 2.1 Eventual Consistency (Default Kubernetes Model)

This model relies on Kubernetes’ inherent **eventual consistency** and Argo CD’s retry behavior rather than explicit ordering.

#### Core Concept

* Resources and Applications are applied independently.
* Temporary failures are tolerated.
* Controllers reconcile once dependencies become available.

This is best suited for:

* CRDs and their dependent resources
* Controllers that can tolerate delayed dependencies
* Cloud-native workloads with built-in retry logic

#### Required Sync Options for Unknown Resources

When a CRD is not yet registered at dry-run time, use:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
```

This prevents sync failures when:

* A controller CRD is installed in one Application
* Custom resources are installed in another Application

#### Customizing Sync Retries

You can tune sync retries at the Application level:

```yaml
spec:
  syncPolicy:
    retry:
      limit: 10
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 1m
```

This allows:

* Gradual backoff during dependency convergence
* Tolerance for slow-starting controllers

#### Validation Control (Use with Caution)

```yaml
spec:
  syncPolicy:
    syncOptions:
      - Validate=false
```

* Disables schema validation.
* Useful in rare CRD bootstrap scenarios.
* **Not recommended for general workloads** due to safety risks.

---

### 2.2 App-of-Apps Pattern (Explicit Ordering via Parent Application)

#### Primary Use Case

The **App-of-Apps pattern** is primarily a **bootstrapping mechanism** for Argo CD itself and large GitOps platforms.

#### How It Works

* A **parent Argo CD Application** manages multiple **child Applications** as Kubernetes resources.
* Ordering is controlled using:

  * `sync-wave` annotations on the child Application manifests
* The parent Application synchronizes child Applications in wave order.

#### Example Ordering Mechanism

* Wave `0`: CRDs, Operators
* Wave `1`: Platform services (ingress, cert-manager)
* Wave `2`: Business applications

#### Critical Prerequisite: Application Health Checks

For ordering to function correctly:

* **Argo CD Application health checks must be enabled**
* Otherwise, Argo CD cannot reliably determine when a child Application is “Ready”

This is essential because:

* Sync waves depend on **health status**, not just resource creation.

---

### 2.3 ProgressiveSyncs with ApplicationSets (RollingSync Strategy)

#### Purpose

ApplicationSets generate large numbers of Applications dynamically. However:

* **SyncWaves do not function across ApplicationSets**
* ProgressiveSyncs were introduced to address this limitation

ProgressiveSyncs provide **explicit, ordered rollout control across generated Applications**.

#### Key Constraints

* **Status:** Alpha
* **Must be explicitly enabled**
* **AutoSync is disabled when using ProgressiveSyncs**
* Designed for staged rollouts (e.g., database → backend → frontend)

#### Minimal Example: RollingSync Strategy

```yaml
spec:
  generators:
  - list:
      elements:
      - srv: database
        path: apps/golist-db/
      - srv: backend
        path: apps/golist-api/
      - srv: frontend
        path: apps/golist-frontend/

  strategy:
    type: RollingSync
    rollingSync:
      steps:
      - matchExpressions:
        - key: golist-component
          operator: In
          values:
          - database

      - matchExpressions:
        - key: golist-component
          operator: In
          values:
          - backend

      - matchExpressions:
        - key: golist-component
          operator: In
          values:
          - frontend
```

This enforces:

1. Database Applications sync first
2. Backend Applications sync second
3. Frontend Applications sync last

---

## 3. Health Checks and Synchronization

### Kubernetes Probes vs. Argo CD Health Checks

| Capability           | Purpose                          | Scope                  |
| -------------------- | -------------------------------- | ---------------------- |
| Liveness Probe       | Detects container deadlocks      | Pod Lifecycle          |
| Readiness Probe      | Controls traffic routing         | Service Endpoints      |
| Argo CD Health Check | Determines Application readiness | GitOps Sync & Ordering |

Kubernetes probes are **necessary but insufficient** for GitOps ordering.

---

### CRD and Application Health Checks

By default:

* Many CRDs (including Argo CD’s own Application CRD) **do not have health checks enabled**
* This causes their health status to appear as `Unknown`

Why this matters:

* **Sync waves and App-of-Apps ordering depend on health**
* Without health checks, Argo CD cannot block dependent Applications

You must:

* **Extend health checks for CRDs**
* **Enable health checks for Argo CD Application resources themselves**

Relevant upstream items:

* Health enablement gaps: Issue 3781
* Dependency management feature request: **7437**

Until native dependency management is implemented, **health checks are a hard requirement for reliable ordering**.

---

## 4. Configuration Management Best Practices (Repository and Resource Level)

---

### 4.1 Repository Structure Best Practices

A scalable GitOps repository strategy typically includes:

* **Control Plane Repository**

  * Bootstraps Argo CD itself
  * Defines:

    * Projects
    * App-of-Apps
    * ApplicationSets
    * RBAC
* **Application-Specific Repositories**

  * One repo per service or domain
  * Owned by application teams
* **Cluster Add-ons Repositories**

  * Ingress controllers
  * Monitoring stacks
  * Cert-manager
  * Service meshes

Best practices:

* Store all Argo CD configuration under:

  * `applications/`
  * `applicationsets/`
  * `projects/`
* Use:

  * **Helm for packaging**
  * **Kustomize for environment overlays**
* Terraform is frequently used for:

  * Cluster provisioning
  * Argo CD installation bootstrap

---

### 4.2 Application-Specific vs. Resource-Specific Sync Options

Argo CD supports **two distinct layers of sync behavior control**.

---

### Application-Specific Sync Options

Applied at the **Application level** under `spec.syncPolicy`. These affect **all resources managed by the Application**.

Typical use cases:

* Namespace creation
* Drift control
* Partial sync optimization

#### Recommended Application-Level Options

```yaml
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
```

Key options:

* `CreateNamespace=true`: Automatically creates the destination namespace
* `ApplyOutOfSyncOnly=true`: Prevents unnecessary re-applies

These should be treated as **global workload policies**.

---

### Resource-Specific Sync Options

Applied via **metadata annotations** on individual Kubernetes resources. These override default behavior only for that resource.

Common use cases:

* Protecting shared infrastructure
* Preventing destructive pruning
* Forcing replacement semantics

#### Common Resource-Level Annotations

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: Prune=false,Replace=true
```

Popular options:

* `Prune=false`: Prevents deletion during prune operations
* `Delete=false`: Protects critical resources
* `Replace=true`: Forces delete-and-recreate instead of patch

Use these **sparingly and intentionally**, as they introduce exceptions to GitOps immutability.

---

## 5. Installation and Scaling

---

### 5.1 Installation Methods

| Method     | Assessment                                         |
| ---------- | -------------------------------------------------- |
| Raw YAML   | Simple, but not maintainable at scale              |
| Helm Chart | Flexible, declarative, upgrade-safe                |
| Operator   | Adds lifecycle automation but increases complexity |

---

### 5.2 Recommended Installation Method: Helm

**Helm is the recommended method for installing Argo CD**, because it is:

* Predictable and repeatable
* Officially supported by the Argo Project
* Capable of expressing complex HA topologies
* Easily upgradeable
* Compatible with GitOps-driven lifecycle management

**Best practice:**
Use **Helm + Kustomize together**:

* Helm for packaging
* Kustomize for environment-specific customization

---

### 5.3 Scaling and High Availability

#### Core Components to Scale

For production environments, you must scale:

* **Repo Server**

  * Handles Git fetches and manifest rendering
* **API Server**

  * UI and CLI access
* **Application Controller**

  * Reconciliation engine (most critical for scale)

#### Controller Sharding

* Horizontal scaling of the **Application Controller** enables:

  * Workload isolation
  * High concurrency
  * Reduced reconciliation latency in large clusters

#### High Availability Requirements

* Minimum **3 nodes** recommended
* Redis becomes a **hard dependency** for HA deployments
* Scaling is typically performed via:

  * `helm upgrade`
  * Controller replica adjustments
  * Sharding configuration

---

## Summary of Key Best Practices

* Treat the **Argo CD Application as the atomic GitOps unit**
* Use:

  * **Eventual consistency** for decoupled cloud-native workloads
  * **App-of-Apps** for platform bootstrapping
  * **ProgressiveSyncs** for ordered ApplicationSet rollouts (Alpha)
* Always:

  * Enable and extend **Application and CRD health checks**
* Separate:

  * **Application-level sync behavior**
  * **Resource-level override behavior**
* Prefer:

  * **Helm for installation**
  * **Helm + Kustomize for customization**
* Scale:

  * Repo Server
  * API Server
  * Application Controller with **sharding**

---

