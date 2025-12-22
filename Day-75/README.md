
---
# Day 75 — Advanced GitHub Actions Features

This document covers advanced GitHub Actions concepts with a focus on **runner types**, **execution environments**, **artifacts**, **caching strategies**, and **workflow permissions**. The examples demonstrate practical configurations used in real-world CI/CD pipelines.

---

## 1. GitHub Actions Runners

A **runner** is the compute environment where a GitHub Actions job executes. The runner is defined using the `runs-on` key in a workflow.

### What Runner Selection Controls

The runner type determines:

- The **operating system** and base VM image  
- Preinstalled **tools and dependencies**  
- Available **CPU and memory resources**  
- Network access and execution boundaries  

Every job **must** explicitly declare a runner.

---

## 2. Runner Types

GitHub Actions supports three primary runner categories.

### 2.1 GitHub-Hosted Runners

GitHub provides fully managed runners for common platforms:

- Ubuntu
- Windows
- macOS

These are ideal for:
- Quick onboarding
- Open-source projects
- Standard CI workloads

They require no infrastructure management but have fixed performance characteristics and usage limits.

---

### 2.2 Third-Party Hosted Runners

External providers host GitHub-compatible runners with enhanced performance characteristics.

**Key advantages:**
- Faster builds
- Lower cost per minute
- Additional features such as fleet monitoring and advanced caching

Example providers include Namespace.

Switching typically requires **changing only the `runs-on` value**.

---

### 2.3 Self-Hosted Runners

Self-hosted runners are managed entirely by you.

Common setups include:
- Kubernetes-based runners (Actions Runner Controller)
- VM-based runners
- Managed platforms like RunsOn

**Benefits:**
- Private network access
- Custom hardware profiles
- Full environment control

**Trade-off:** you own the operational complexity.

---

## 3. Runner Execution Environments

The `runs-on` key defines:

- OS and architecture
- Resource limits
- Underlying VM image

You can further customize execution by:
- Running jobs inside containers
- Using custom runner labels
- Combining hosted runners with containerized workloads

---

## 4. Runner Examples

```yaml
jobs:
  github-hosted-ubuntu-vm:
    name: Ubuntu 24.04 VM
    runs-on: ubuntu-24.04
    steps:
      - run: |
          echo "Hello from ${{ runner.os }}-${{ runner.arch }}"
          echo "Runner name: ${{ runner.name }}"
````

### Containerized Job on a Hosted Runner

```yaml
jobs:
  alpine-container:
    runs-on: ubuntu-24.04
    container:
      image: alpine:3.20
    steps:
      - run: |
          echo "Running inside Alpine container"
          cat /etc/os-release
```

---

## 5. Persisting Build Outputs with Artifacts

GitHub Actions runners are **ephemeral**. Any files created during a job are destroyed once the job completes.

**Artifacts** allow you to persist files beyond job execution by storing them in GitHub-managed object storage.

### Artifact Producer and Consumer Example

```yaml
jobs:
  artifact-producer:
    runs-on: ubuntu-24.04
    steps:
      - run: echo "Hello artifact" > artifact.txt
      - uses: actions/upload-artifact@v4
        with:
          name: example-artifact
          path: artifact.txt
```

```yaml
  artifact-consumer:
    runs-on: ubuntu-24.04
    needs: artifact-producer
    steps:
      - uses: actions/download-artifact@v5
        with:
          name: example-artifact
      - run: cat artifact.txt
```

Artifacts appear in the workflow summary as downloadable archives and are commonly used for:

* Build outputs
* Test reports
* Debugging assets

---

## 6. Reusing Work with Caching

Artifacts are for **long-lived outputs**.
Caches are for **intermediate data** such as dependencies or compiled assets.

GitHub provides up to **10 GB of cache storage per repository**, with eviction based on usage.

---

### 6.1 Generic Cache Example

```yaml
- uses: actions/cache@v4
  with:
    path: demo-cache
    key: demo-cache-v1
```

Caches are keyed explicitly and must be restored and saved intentionally.

---

### 6.2 Built-In Caching via Setup Actions

Some setup actions include native caching support.

Example using Node.js:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: npm
    cache-dependency-path: package-lock.json
```

This approach is preferred for common ecosystems because it:

* Automatically manages cache keys
* Reduces configuration overhead
* Improves reliability

---

### 6.3 Alternative Caching Models

Third-party runner providers may offer advanced caching mechanisms.

Example:

* Snapshot-based cache volumes
* Directory mounts instead of upload/download cycles

These approaches can drastically reduce build times for dependency-heavy workloads.

---

## 7. Controlling GitHub Token Permissions

Each workflow receives a `GITHUB_TOKEN` with **read-only access by default**.

Explicitly scoping permissions enforces **least privilege** and reduces security risk.

---

### Read-Only Permissions Example

```yaml
permissions:
  pull-requests: read
```

Attempting write operations with this token will fail.

---

### Read-Write Permissions Example

```yaml
permissions:
  pull-requests: write
```

This enables label changes, comments, and PR updates.

**Best practice:**
Always grant the minimum permissions required per job.

---

## Summary

This module covered:

* Runner types and execution environments
* Containerized jobs
* Artifact persistence
* Cache strategies
* Permission scoping for secure automation

These features are essential for building **scalable, secure, and cost-efficient CI/CD pipelines** with GitHub Actions.

---
