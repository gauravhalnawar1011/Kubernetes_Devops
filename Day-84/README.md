
---

# Day-84 — Capstone Project

## Multi-Service Deployment Using GitHub Actions

Fork the Repository

Open the repository on GitHub:

https://github.com/gauravhalnawar1011/github-actions-capstone-project


Click Fork

Clone your fork locally and start experimenting

📁 Project Directory Structure

All services, workflows, and tooling described in this README live under this repository root.
Once cloned, you can immediately proceed with:

devbox shell

Running services locally

Executing GitHub Actions workflows

Exploring CI/CD patterns used in the capstone
This repository is a **capstone project** demonstrating how to design, test, and deploy a **multi-language monorepo** using **GitHub Actions** with a focus on **maintainability, scalability, and production-grade CI/CD practices**.

The project showcases:

* Service isolation inside a monorepo
* Unified task execution via `go-task`
* Local developer experience using **Devbox**
* Dynamic, path-based CI execution (no unnecessary jobs)
* Multi-architecture Docker image builds using **QEMU**
* Clean upstream → downstream workflow orchestration

---

## Repository Structure

```
.
├── services/
│   ├── node/
│   │   └── api-node/
│   ├── go/
│   │   └── api-golang/
│   ├── python/
│   │   └── load-generator-python/
│   ├── react/
│   │   └── client-react/
│   └── other/
│       └── api-golang-migrator/
│           └── migrations/
├── .github/
│   ├── workflows/
│   │   ├── build-push.yaml
│   │   └── test.yaml
│   └── utils/
│       └── file-filters.yaml
├── Taskfile.yaml
└── README.md
```

### Key Concepts

* **`services/`** contains all application logic (backend + frontend).
* Each service is **self-contained** and executed via `task`.
* Database schema and migrations are isolated under the migrator service.
* CI workflows operate **per service**, not per repository.

---

## Local Development Setup

### Prerequisites

Verify your system supports Devbox:

```bash
lsb_release -a
curl --version
```

### Install Devbox

```bash
curl -fsSL https://get.jetpack.io/devbox | bash
exec $SHELL
```

---

## Running the Project Locally

All local execution is done **inside the Devbox shell**.

```bash
devbox shell
```

---

## Database Setup (PostgreSQL)

### 1. Start PostgreSQL

```bash
cd services/other/api-golang-migrator/migrations
task
task run-postgres
```

> Keep this terminal running.

---

### 2. Initialize Database Schema (New Terminal)

```bash
devbox shell
cd services/other/api-golang-migrator/migrations
task
task run-psql-init-script
```

This creates all required tables and schema.

---

## Running Backend Services

### Node.js API

```bash
cd services/node/api-node
task
task install
task run
```

---

### Go API

```bash
cd services/go/api-golang
task
task install
task run
```

---

### Python Load Generator

```bash
cd services/python/load-generator-python
task
task install
task run
```

This service generates load against the Node and Go APIs.

---

## Frontend (React)

```bash
cd services/react/client-react
task
task install
task run
```

The frontend visualizes request load, traffic, and API interactions.

---

## CI/CD Design Philosophy

### ❌ Naive Approach (What We Avoid)

Running **all jobs for every change**:

* Wasteful
* Slow
* Expensive
* Not production-ready

Example (anti-pattern):

* Change in Python → Node, Go, React tests also run

---

### ✅ Production Approach (What We Implement)

**Upstream → Downstream orchestration** using:

1. **Path-based change detection**
2. **Dynamic job matrices**
3. **Runtime service selection**

Only **changed services** trigger CI jobs.

---

## Testing Strategy

### Initial (Per-Service) Workflows

Separate workflows for Node and Go tests were used initially.

### Final (Maintainable) Solution

A **single matrix-based workflow** handles all services dynamically:

* Node
* Go
* Python
* React

Each service:

* Installs its own dependencies
* Runs tests in isolation
* Shares a unified CI structure

This dramatically reduces duplication and maintenance overhead.

---

## Docker Image Build & Push

### Why QEMU?

We use **QEMU** to build **multi-architecture images**:

* `linux/amd64`
* `linux/arm64`

This enables:

* Cloud portability
* ARM-based infrastructure support
* Future-proof deployments

---

## Image Build Flow

1. Detect changed services
2. Build images **only for affected services**
3. Tag images deterministically
4. Push images to registry
5. Trigger downstream deployment workflows

---

## Key Engineering Principles Demonstrated

* **Monorepo done right**
* **Fail-fast CI**
* **Dynamic job execution**
* **No hardcoded paths**
* **No unnecessary rebuilds**
* **Clear separation of concerns**
* **Production-grade GitHub Actions**

---

## Why This Project Matters

This is **not** a demo repo.

This project demonstrates:

* How real DevOps/SRE teams structure CI pipelines
* How to scale workflows as services grow
* How to avoid CI/CD anti-patterns
* How to keep pipelines fast, cheap, and reliable

---

## Final Notes

* All services are driven via `task`
* CI logic scales with service count
* Local and CI environments behave consistently
* The system is designed for **real production constraints**

---


