
---

# Argo CD GitOps – Revisited (Day 68)

## Overview

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. It treats Git repositories as the **single source of truth** and continuously reconciles the desired state defined in Git with the actual state of a Kubernetes cluster.

This document revisits core Argo CD concepts, application deployment strategies, dependency management, health checks, repository organization, sync behaviors, and installation best practices.

---

## Kubernetes Objects and Argo CD Applications

### Kubernetes Object Model

* Kubernetes consists of **loosely coupled objects**
* Objects are independently managed and reconciled
* Ordering and dependency handling are **not inherently guaranteed**

### Argo CD Application CRD

* `Application` is the **atomic deployment unit** in Argo CD
* Manages a **grouping of Kubernetes resources**
* Responsible for:

  * Deploying resources
  * Reconciling drift
  * Reporting health
  * Enforcing sync behavior

Argo CD operates **strictly within the scope of an Application CRD**.

---

## Deployment Ordering and Sync Behavior

### Sync Waves

* Built-in mechanism to **control deployment order**
* Resources are applied based on `sync-wave` annotations
* Typically required for:

  * CRDs
  * Controllers
  * Resources unknown at initial reconciliation

Example:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Sync Phases

* `PreSync`
* `Sync`
* `PostSync`

Used for hooks, migrations, or operational steps.

---

## Cross-Application Dependencies

### The Core Problem

> What happens when one application depends on another?

Argo CD does **not natively manage dependencies across Applications**.

### Three Common Strategies

#### 1. Eventual Consistency

* Rely on Kubernetes reconciliation
* Resources eventually become available
* Minimal orchestration
* Suitable for loosely coupled systems

Example for unknown CRDs:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
```

#### 2. App-of-Apps Pattern

* A **parent Application** manages multiple child Applications
* Primarily used for **bootstrapping Argo CD**
* Ordering enforced via **Sync Waves**
* Application health checks are critical

Characteristics:

* Clear hierarchy
* Explicit ordering
* Suitable for platform bootstrap

#### 3. Progressive Syncs (ApplicationSets)

* Designed for **controlled rollout ordering**
* ApplicationSets only **generate Applications**
* Sync Waves do **not** work across generated Applications
* ProgressiveSyncs enable ordering semantics

> **Status**: Alpha
> **Requirements**:

* Feature must be enabled
* AutoSync is disabled
* Explicit rollout strategy required

Example:

```yaml
strategy:
  rollingSync:
    steps:
      - matchExpressions:
          - key: golist-component
            operator: In
            values: [database]
      - matchExpressions:
          - key: golist-component
            operator: In
            values: [backend]
      - matchExpressions:
          - key: golist-component
            operator: In
            values: [frontend]
```

---

## Health Checks and Probes

### Kubernetes Probes

* **Readiness Probe**: Determines traffic eligibility
* **Liveness Probe**: Determines container restart

These are **mandatory best practices**.

### Argo CD Application Health Checks

* Argo CD evaluates resource health to determine Application status
* Some CRDs are reported as `Unknown` by default
* Custom health checks can:

  * Extend existing checks
  * Define new ones for custom CRDs

> Application-level health checks are **not enabled by default**
> Refer to Argo CD Issue #3781

---

## Retry and Validation Configuration

### Retry Strategy

```yaml
retry:
  limit: 10
  backoff:
    duration: 5s
    factor: 2
    maxDuration: 1m
```

Used to:

* Handle transient failures
* Improve reliability during reconciliation

### Validation

```yaml
syncOptions:
  - Validate=false
```

* Can be useful when prerequisites are pre-installed
* **Not recommended** for general usage

---

## Repository Management Strategy

### Recommended Repository Structure

* **Control Plane Repository**

  * Bootstraps Argo CD
  * App-of-Apps definitions
* **Application Repositories**

  * Application-specific manifests
* **Cluster Add-ons Repository**

  * Ingress, monitoring, logging, etc.

### Best Practices

* Store configuration in:

  * `apps/`
  * `appsets/`
  * `projects/`
* Use:

  * Helm
  * Kustomize
  * GitOps-friendly values
* Terraform simplifies cluster and Argo CD bootstrap

---

## Sync Options: Application vs Resource Specific

### Application-Specific Sync Options

Applies to **all resources in the Application**.

Recommended options:

* `CreateNamespace=true`
* `ApplyOutOfSyncOnly=true`
* `ServerSideApply=true`

Example:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
```

Documentation:
[https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)

---

### Resource-Specific Sync Options

Applied via **annotations on individual resources**.

Common options:

* `Prune=false`
* `Delete=false`
* `Replace=true`

Example:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: Prune=false
```

Documentation:
[https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)

---

## Installation

### Installation Methods

* Raw YAML
* Helm Chart
* Operator

### Recommendation: Helm

Reasons:

* Officially supported
* Predictable and flexible
* Simplifies HA and scaling
* De-facto Kubernetes package manager

**Preferred Setup**:

* Helm + Kustomize

---

## Scaling and High Availability

### Scaling Considerations

* Minimum **3 nodes** recommended
* Redis is required for HA
* Scale individual components:

  * Repo Server
  * API Server
  * Application Controller

### Controller Sharding

* Enabled by scaling the Application Controller
* Improves performance at scale

---

## Key Takeaways

* Argo CD Applications are collections of Kubernetes resources
* Liveness and readiness probes are critical
* Application health checks must be explicitly managed
* Dependency handling options:

  * Eventual consistency
  * App-of-Apps
  * Progressive Syncs
* Use Helm for installation and scaling
* Clearly separate Application and Resource sync behaviors

---

## References

* Argo CD Documentation
  [https://argo-cd.readthedocs.io](https://argo-cd.readthedocs.io)
* Feature Request: Application Dependencies (#7437)

---

