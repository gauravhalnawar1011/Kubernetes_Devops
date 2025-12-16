
---


# Argo Rollouts – Progressive Delivery on Kubernetes

Day-69 Learning Notes & Practical Guide

---

## Overview

**Argo Rollouts** is a Kubernetes controller implemented using **Custom Resource Definitions (CRDs)** that provides **advanced deployment strategies** and **progressive delivery capabilities** beyond what the native Kubernetes `Deployment` object offers.

It enables safer application releases by supporting strategies such as **Blue-Green** and **Canary deployments**, along with **traffic management**, **automated analysis**, and **automatic promotions or rollbacks**.

This repository documents the **core concepts, deployment strategies, components, use cases, and installation steps** for Argo Rollouts in a clear and interview-ready manner.

---

## Why Argo Rollouts?

Kubernetes provides the `Deployment` object for managing application updates. While useful, it has important limitations when running **production-grade workloads**.

### Native Kubernetes Deployment Capabilities
- Supports **RollingUpdate** and **Recreate** strategies
- Provides basic safety through:
  - Readiness probes
  - Liveness probes
  - Controlled Pod scaling

### Limitations of Kubernetes Deployment
- No support for **Blue-Green** or **Canary** deployments
- No traffic percentage control
- No automated metric-based decision making
- No built-in rollback based on real-time metrics
- Risky for high-impact production releases

---

## What Argo Rollouts Adds

Argo Rollouts extends Kubernetes with:

- Advanced deployment strategies
- Traffic shaping and routing
- Metric-based rollout analysis
- Automated promotion and rollback
- Integration with ingress controllers and service meshes

---

## Key Features

- **Blue-Green Deployments**
- **Canary Deployments**
- **Progressive Delivery**
- **Ingress Controller Integration**
- **Service Mesh Integration (Istio, NGINX, etc.)**
- **Automated Rollouts**
- **Automated Promotions and Rollbacks**
- **Metric-Based Analysis**

---

## Deployment Strategies

### Native Kubernetes Deployment Strategies

#### 1. RollingUpdate (Default)
- Gradually replaces old Pods with new Pods
- Maintains application availability
- Limited control over traffic and rollout validation

#### 2. Recreate
- Terminates old Pods before starting new Pods
- Ensures only one version runs at a time
- Causes application downtime

---

### Argo Rollouts Deployment Strategies

#### 1. RollingUpdate
- Also supported in Argo Rollouts
- Similar to native Kubernetes behavior

#### 2. Blue-Green Deployment
- Runs **two versions** of the application simultaneously:
  - **Active Service** → serves production traffic
  - **Preview Service** → serves new version
- Allows final functional and validation tests before production traffic switch
- After validation, preview service is promoted to active
- Old version is removed once the new version is stable

**Use Case Example**  
Run last-minute functional tests on a new version before it serves production traffic.

---

#### 3. Canary Deployment
- Gradually shifts traffic to the new version
- Example flow:
  - 10% → validate
  - 33% → validate
  - 100% → full promotion
- Traffic percentages and wait durations are configurable
- Minimizes risk by exposing only a subset of users initially

**Use Case Example**  
Safely introduce a new version by monitoring real user behavior and metrics.

---

## Core Components of Argo Rollouts

### 1. Rollouts Controller
- Main controller that watches Rollout resources
- Continuously reconciles desired and actual cluster state
- Reacts only to Rollout CRDs (not native Deployments)

---

### 2. Rollout Resource (CRD)
- Custom Kubernetes resource managed by Argo Rollouts
- Largely compatible with `Deployment`
- Includes additional fields for:
  - Canary steps
  - Blue-Green configuration
  - Analysis templates
  - Traffic routing

> **Note:**  
> Argo Rollouts does not manage native Deployment objects.  
> Existing Deployments must be **migrated to Rollout resources** to be managed by Argo Rollouts.  
> It can safely coexist with standard Kubernetes Deployments in the same cluster.

---

### 3. Services and Traffic Routing
- Uses standard Kubernetes `Service` objects
- Additional metadata is required for rollout control
- Supports:
  - Active services
  - Preview services
  - Canary services
- Flexible networking options depending on ingress or service mesh

---

### 4. AnalysisTemplate
- Defines success or failure conditions for a rollout
- Integrates with metric providers
- Supports:
  - Multiple metrics per analysis
  - Threshold-based success criteria
- Rollouts can:
  - Automatically promote
  - Automatically rollback
  - Pause when results are inconclusive

---

### 5. Metric Providers
Argo Rollouts supports native integrations with popular providers, including:
- Prometheus
- Datadog
- New Relic
- CloudWatch (via adapters)

Metrics drive automated rollout decisions.

---

## Installation

### Install Argo Rollouts Controller

```bash
kubectl create namespace argo-rollouts

kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
````

---

### Optional: Install kubectl Plugin

The kubectl plugin is optional but highly recommended for managing and visualizing rollouts.

```bash
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
```

Make the binary executable:

```bash
chmod +x ./kubectl-argo-rollouts-linux-amd64
```

Move it into your PATH:

```bash
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

Verify installation:

```bash
kubectl argo rollouts version
```

> For macOS, replace `linux` with `darwin`.

---

## Argo Rollouts Dashboard

Argo Rollouts provides a web-based dashboard for visualizing rollout progress.

Documentation:
[https://argo-rollouts.readthedocs.io/en/stable/dashboard/](https://argo-rollouts.readthedocs.io/en/stable/dashboard/)

---

## Official Resources

* Argo Rollouts GitHub Repository:
  [https://github.com/argoproj/argo-rollouts](https://github.com/argoproj/argo-rollouts)

* Official Documentation:
  [https://argo-rollouts.readthedocs.io/](https://argo-rollouts.readthedocs.io/)

---

## Summary

Argo Rollouts enables **safe, observable, and automated application delivery** on Kubernetes by extending native deployment capabilities with modern progressive delivery practices.

It is especially valuable for:

* Production environments
* High-availability systems
* Continuous delivery pipelines
* Risk-sensitive application releases

---

