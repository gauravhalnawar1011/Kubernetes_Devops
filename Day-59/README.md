
# Day 59 – Multi-Cluster Deployment with Argo CD (GitOps)

## Overview

This project demonstrates **multi-cluster Kubernetes deployment using Argo CD with GitOps principles**. It explains how to manage deployments across multiple environments (Dev, QA, Test, Prod) using both **Hub-Spoke** and **Standalone (Singleton)** Argo CD architectures.

The goal is to replace **traditional script-heavy CD pipelines** (Shell, Python, Ansible) with a **declarative, auditable, and self-healing GitOps-based delivery model**.

---

## What is Argo CD?

**Argo CD** is a **Kubernetes-native Continuous Delivery (CD) tool** that follows the **GitOps** model. It ensures that your Kubernetes clusters always match the desired state defined in Git.

In modern CI/CD:

```

Apps → Argo CD → Continuous Delivery → Kubernetes

```

---

## CI vs CD in Traditional Pipelines

### CI (Continuous Integration)
Common CI Stages:
- Build
- Unit Testing
- Static Code Analysis
- SAST (SonarQube)
- DAST
- End-to-End Testing
- Regression Testing
- Docker Image Build
- Image Scanning (Trivy, Docker Scout)
- Push to Registry (DockerHub / ECR / ACR / Artifact Registry)

### CD (Traditional Approach)
Traditionally handled using:
- Shell Scripts
- Python Scripts
- Ansible
- Jenkins Plugins

### Problems with Traditional CD:
- No **single source of truth**
- No **audit trail**
- No **automatic rollback**
- No **drift detection**
- Manual changes directly on clusters
- Hard to identify **who changed what**
- No **self-healing**

---

## Why GitOps?

GitOps brings **version control, auditability, and automation** to CD.

### Key GitOps Benefits:
- ✅ Single Source of Truth (Git)
- ✅ Change Tracking
- ✅ Full Audit Trail
- ✅ Monitoring of Drift
- ✅ Automatic Rollbacks
- ✅ Auto-Healing
- ✅ Security & Compliance

Argo CD continuously reconciles:
```

Git Desired State ↔ Cluster Actual State

````

If someone makes a manual change in the cluster, Argo CD will **automatically revert it**.

---

## Problem Scenario (Real-Life Use Case)

### Existing Setup:
- `Dev` cluster → Running `textbook:v1`
- `QA` cluster → Running `textbook:v1`
- `Test` cluster → Running `textbook:v1`

### New Requirement:
- A new feature `textbook:v2` is ready
- Developer requests a **standalone testing cluster**
- The new version must be deployed to **all 3 clusters at once**

### Traditional Approach:
Using:
```bash
kubectl apply -f deployment.yaml
````

on each cluster (manual, error-prone, not auditable).

### GitOps Approach:

* Push updated manifests to Git
* Argo CD automatically syncs all clusters
* All environments get `textbook:v2` instantly and consistently

---

## Multi-Cluster Deployment Models in Argo CD

Argo CD supports **two major deployment models**:

### 1. Standalone (Singleton) Model

Each cluster has its **own Argo CD instance**.

```
Dev  → Argo CD → Git Repo
QA   → Argo CD → Git Repo
Test → Argo CD → Git Repo
```

#### Characteristics:

* Independent management
* Each Argo CD watches its own repo
* High isolation
* Easier disaster recovery
* Independent upgrades

#### Drawbacks:

* Operational overhead
* Repeating upgrades on every cluster
* Hard to enforce centralized governance

---

### 2. Hub-Spoke Model (Centralized Model)

One **central hub cluster** runs Argo CD and manages multiple target clusters.

```
            Git Repo
               |
           Argo CD (Hub)
          /      |       \
     Spoke1   Spoke2   Spoke3
     (Dev)     (QA)     (Test)
```

#### Naming Convention:

* Hub
* Spoke1
* Spoke2
* Spoke3

#### Characteristics:

* Centralized control
* One Argo CD deploys to all clusters
* Best for organizations with a **central DevOps team**
* Requires high CPU/RAM on Hub cluster
* Must be Highly Available (HA)

#### Drawbacks:

* Hub is a single point of control
* Argo CD upgrades affect all clusters
* Migration (Argo → Flux) impacts everything centrally

---

## When to Use Which Model?

| Organization Type       | Recommended Model |
| ----------------------- | ----------------- |
| Centralized DevOps Team | ✅ Hub-Spoke       |
| Independent Teams       | ✅ Standalone      |
| Small Setup             | ✅ Standalone      |
| Large Enterprise        | ✅ Hub-Spoke       |

---

## GitOps Principles Reference

This implementation follows **OpenGitOps Principles**:

* Declarative
* Versioned and Immutable
* Pulled Automatically
* Continuously Reconciled

📘 Official Reference:
[https://opengitops.dev/training/](https://opengitops.dev/training/)

---

## Key Advantages of Argo CD in Multi-Cluster Setup

* Automatic sync across clusters
* No manual `kubectl` usage required
* Cluster drift detection
* Self-healing workloads
* Secure Git-based approvals
* Easier audits and compliance
* Faster rollouts across environments

---

## Summary

* Traditional CD is script-driven and error-prone
* GitOps with Argo CD provides:

  * Automation
  * Reliability
  * Auditability
  * Security
* Argo CD supports:

  * Standalone Model
  * Hub-Spoke Model
* Multi-cluster deployments become:

  * Faster
  * Safer
  * Fully automated

---

## Next Scope (Optional Enhancements)

* Argo CD High Availability (HA)
* Multi-tenant Argo CD
* Argo CD + Helm
* Argo CD + Kustomize
* Progressive Delivery (Rollouts & Blue/Green)
* Secrets Management (Sealed Secrets / Vault)

---

