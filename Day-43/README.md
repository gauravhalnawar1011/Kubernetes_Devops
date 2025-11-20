
---

# Day-43 — Introduction to Helm (Kubernetes Package Manager)

## What is Helm?

**Helm is the package manager for Kubernetes.**
Just like other operating systems have their own package managers:

* Windows → `choco`
* macOS → `brew`
* Ubuntu → `apt`
* RedHat → `yum`

Helm works similarly, but specifically for Kubernetes.
It allows you to **install, upgrade, manage, and package Kubernetes applications with simple commands**.

---

## What is a Package Manager?

A package manager is a tool that helps you:

* Install software
* Manage versions
* Handle dependencies
* Update or remove packages

Helm does the same for Kubernetes by packaging application manifests into reusable bundles called **Helm Charts**.

---

## Why Do We Need Helm?

### Without Helm

Installing an application like ArgoCD manually involves:

1. Downloading binaries from official websites
2. Following multiple setup steps
3. Downloading several Kubernetes YAML files (Deployments, Services, CRDs, etc.)
4. Managing and updating each file manually

This is **time-consuming and error-prone**, especially across multiple environments.

### With Helm

Helm bundles all required Kubernetes files into a **single archive** called a **chart**.

* A **chart** = packaged collection of Kubernetes YAMLs (resources, configs, dependencies)
* A **release** = a running instance of a chart in your cluster

Charts are stored in public repositories like **ArtifactHub**:

🔗 [https://artifacthub.io/](https://artifacthub.io/)

Organizations publish their official charts here, making installation extremely simple.

---

## Key Helm Concepts

### **Chart**

A packaged set of Kubernetes YAML manifests.

### **Values.yaml**

Central place to override configurations without editing templates manually.

### **Release**

A deployed instance of a chart.
Multiple releases can be created from the same chart across different environments.

### Example Analogy

* Dockerfile = Helm Chart (instructions)
* Container = Release (running instance)

---

## Installing Helm on Linux (Debian/Ubuntu)

```bash
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

Check version:

```bash
helm version
```

---

## Helm Basic Commands

| Command          | Description                     |
| ---------------- | ------------------------------- |
| `helm search`    | Search for charts               |
| `helm pull`      | Download a chart locally        |
| `helm install`   | Install a chart into Kubernetes |
| `helm list`      | List installed releases         |
| `helm upgrade`   | Upgrade an existing release     |
| `helm uninstall` | Remove a release                |

---

## Helm Directory Structure (`helm create`)

Running:

```bash
helm create <chart-name>
```

Creates the following structure:

```
<chart-name>/
├── .helmignore
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    └── tests/
```

### Important Files

* **Chart.yaml**
  Contains chart metadata (name, version, appVersion)

* **values.yaml**
  Default configuration; you edit this file instead of editing Kubernetes templates directly.

---

## Understanding Chart Versions

Inside `Chart.yaml`:

```yaml
version: 0.1.0
appVersion: "1.16.0"
```

* **version** → Helm chart version (increment when chart/template changes)
* **appVersion** → Version of the application being deployed (increment when the actual app updates)

---

## Installing ArgoCD Using Helm

First, add the official Argo Helm repository:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
```

Install the chart:

```bash
helm install my-argo-cd argo/argo-cd --version 9.1.3
```

Check installed release:

```bash
helm list
```

Retrieve ArgoCD admin password:

```bash
kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## Upgrading a Release

To upgrade an existing deployment:

```bash
helm upgrade my-argo-cd argo/argo-cd
```

---

## Searching Charts

Search ArtifactHub:

```bash
helm search hub argo
```

Search your added repos:

```bash
helm search repo argo
```

---

## Final Notes

* Helm significantly simplifies Kubernetes application management.
* You no longer edit YAML templates manually—only the `values.yaml` file.
* Charts are reusable and can be deployed across dev, test, and production.

---

