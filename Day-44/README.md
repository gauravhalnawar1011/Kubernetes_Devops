
---

# Kustomize Deployment Guide

[![Kubernetes](https://img.shields.io/badge/Kubernetes-Deployment-blue?logo=kubernetes)](https://kubernetes.io/)
[![Kustomize](https://img.shields.io/badge/Kustomize-Overlay%20Engine-green)](https://kubectl.docs.kubernetes.io/references/kustomize/)
[![Helm](https://img.shields.io/badge/Helm-Templating%20Engine-0f1689?logo=helm)](https://helm.sh/)

## Overview

Kustomize is a Kubernetes-native configuration customization tool. It allows you to manage Kubernetes manifests using **overlays** instead of templates, enabling reusable configuration for multiple environments such as **dev**, **qa**, **staging**, and **production**.

Unlike Helm—which uses templates—Kustomize works directly with YAML manifests, applying layered patches to produce environment-specific deployments.

---

## Key Features

* **Pure YAML (No Templating)** – Works directly with Kubernetes manifests.
* **Overlays** – Create environment-specific variations without duplicating YAML.
* **Folder-Based Hierarchy** – Manage `base` and `overlays` as separate structures.
* **Native to kubectl** – No additional installation required (`kubectl kustomize`).
* **Reuse of Existing Manifests** – Ideal for teams already maintaining raw YAML.

---

## Prerequisites

* Kubernetes cluster (local or cloud)
* `kubectl` v1.14+ (includes built-in Kustomize support)
* Optional: standalone `kustomize` binary (for local building or CI)

---

## Project Structure

A typical Kustomize layout:

```
.
├── base
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
└── overlays
    ├── dev
    │   ├── kustomization.yaml
    │   └── replicas.yaml
    ├── qa
    ├── staging
    └── prod
```

### Example: `base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

commonLabels:
  app: hello

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
```

---

## Running Kustomize

### Build Only (Preview YAML)

```
kubectl kustomize .
```

### Build & Apply

```
kubectl kustomize . | kubectl apply -f -
```

### Using the Standalone Binary

```
kustomize build <folder> | kubectl apply -f -
```

---

## Environment Overlays

Each environment (e.g., `dev`, `prod`) contains its own `kustomization.yaml`.

Example: `overlays/dev/kustomization.yaml`

```yaml
resources:
  - ../../base

patches:
  - replicas.yaml
```

Kustomize will merge the overlay configuration with the base, producing a final manifest suitable for that environment.

---

# Deployment Strategy: Helm vs. Kustomize

This section analyzes which tool—Helm, Kustomize, or both—is best suited for this specific project based on the content in the original README.

## 1. Project Characteristics Identified

From the original notes, this project:

* Uses **raw Kubernetes YAML** (deployments, services, configmaps).
* Requires **environment-specific differences** (Dev, QA, Staging, Prod).
* Does **not** mention:

  * complex deployment logic,
  * templating requirements,
  * packaging for external users,
  * distribution as a chart.

The emphasis is on:

* layering,
* labels,
* simple patches,
* keeping YAML structure consistent across environments.

This aligns strongly with Kustomize’s design philosophy.

---

## 2. Tool Comparison for This Project

### **Helm**

| Strength                                           | Relevance to This Project |
| -------------------------------------------------- | ------------------------- |
| Complex templating (loops, conditionals)           | **Not needed**            |
| Packaging for distribution to external teams/users | **Not required**          |
| Values file acting as a central config             | Useful but unnecessary    |
| Large/complex microservices apps                   | Not indicated here        |

**Conclusion:** Helm is more powerful than required for this project.

---

### **Kustomize**

| Strength                                              | Relevance to This Project               |
| ----------------------------------------------------- | --------------------------------------- |
| Simple environment-specific overlays                  | **Strong match**                        |
| Keeping YAML as-is (no templates)                     | **Matches project approach**            |
| Native to kubectl                                     | **Reduces tooling complexity**          |
| Managing multiple environments using folder hierarchy | **Exactly what this project describes** |

**Conclusion:** Kustomize aligns almost perfectly with the current project structure and goals.

---

### **Hybrid (Helm + Kustomize)**

Only recommended if:

* You use third-party Helm charts (Redis, Postgres, NGINX ingress),
* Or you need to patch Helm output.

No such requirement appears in this project.

---

## Recommended Approach for This Project

### ✅ **Recommendation: Use Kustomize**

Based on project requirements, **Kustomize is the ideal choice**.

Reasons:

* The project already uses raw YAML manifests.
* Environment differences are simple patches (replicas, labels, image tags).
* No distribution of packaged charts.
* No need for templating logic.

If in the future the project must be distributed externally or requires complex templating, Helm could be introduced—but not at the current stage.

---


