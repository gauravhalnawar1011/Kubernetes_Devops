
---

# GitHub Actions Best Practices

## Building Reliable, Secure, and High-Performance CI/CD Pipelines

This repository documents the engineering standards used to design and operate **production-grade GitHub Actions pipelines**.
The focus is not “making CI work,” but **making CI predictable, fast, secure, and maintainable at scale**.

These practices reflect how **senior DevOps and SRE teams** build automation that supports developer velocity without sacrificing reliability or security.

---

## Core Principles (Read This First)

Before optimizing or adding complexity, anchor on these principles:

* **Measure before optimizing** – No optimization is valid without a baseline.
* **Fail fast, not late** – Feedback speed matters more than absolute throughput.
* **Do the minimum necessary work** – Every unnecessary job is wasted capacity.
* **Prefer standardization over cleverness** – Consistency beats bespoke logic.
* **Security is a constraint, not an afterthought** – Pipelines are part of your attack surface.

If a workflow violates any of the above, it will become a liability as the system scales.

---

## 1. Performance Engineering for CI/CD

### 1.1 Measure First, Always

Optimization without observability is guessing.

* Use GitHub’s built-in job and step timing data as a baseline.
* Export workflow timing metrics to an external system (for example, Prometheus, Datadog, or a data warehouse).
* Track:

  * Queue time vs execution time
  * Job duration trends
  * Cache hit/miss ratios

**Rule:** If you cannot quantify the improvement, do not ship the change.

---

### 1.2 Reduce Waiting Time

Most CI pipelines are slow because they spend time *waiting*, not executing.

**Key strategies:**

* **Runner availability**

  * Ensure adequate capacity (GitHub-hosted or managed self-hosted).
  * Avoid fan-out storms that exhaust runner pools.

* **Fail fast**

  * Run high-flakiness or high-failure-probability checks first.
  * Do not allow long-running jobs to fail at minute 45 when the failure was detectable at minute 2.

This is an SRE concept applied to CI: **early signal beats late certainty**.

---

### 1.3 Do Less Work

Every executed step should justify its existence.

* Use `paths` filters to avoid running workflows when unrelated files change.
* Use job-level and step-level `if` conditions.
* Avoid rebuilding or retesting unchanged components.

This is where monorepos fail without discipline—change detection is non-negotiable.

---

### 1.4 Use Compute Resources Effectively

* Split independent tasks into **parallel jobs**.
* Exploit multi-core runners where tooling supports it.
* Avoid architecture emulation (for example, QEMU) unless absolutely required.

**Important:**
Cross-architecture emulation is expensive. High-performing build systems build **natively per architecture** and merge artifacts afterward. This is how serious container build platforms achieve speed.

---

### 1.5 Prevent Performance Regressions

CI pipelines naturally degrade over time.

* Continuously monitor execution times.
* Treat pipeline slowdowns as technical debt.
* Flag regressions early—before developers complain.

This is **capacity management**, not optional optimization.

---

## 2. Caching Strategy (Applied, Not Blind)

Caching is a force multiplier—but only when scoped correctly.

### 2.1 What to Cache

* **Git checkout**

  * Useful for large repositories to reduce fetch time.
* **Language toolchains**

  * Cache custom versions of Node, Go, Java, Python, etc.
* **Dependencies**

  * npm, pip, Maven, Cargo, and similar package managers.
* **Build and test artifacts**

  * Only when size and reuse justify the complexity.
* **Container layers**

  * Cache base images and unchanged layers.
  * Use cache mounts to expose dependency caches inside Docker builds.

### 2.2 What Not to Cache

* Secrets
* Environment-specific outputs without proper key scoping
* Large artifacts with low reuse probability

**Bad caching is worse than no caching.**

---

## 3. Maintainability and Workflow Design

### 3.1 Define a Standard CI Interface

Every service must expose a **predictable contract**.

Choose one entry point:

* `make`
* `task`
* `bazel`
* equivalent tooling

Required targets (minimum):

* `install`
* `test`
* `build`
* `dev`

This ensures:

* Fast onboarding
* Identical local and CI behavior
* Minimal GitHub Actions complexity

CI should **orchestrate**, not implement business logic.

---

### 3.2 Centralize Reusable Logic

Avoid YAML copy-paste at all costs.

Use:

* Composite actions
* Reusable workflows
* Internal action repositories (for multi-repo environments)

Decision rule:

* Marketplace action → Inline shell → Task runner → Custom action
  Only move right when complexity forces you to.

---

### 3.3 Optimize Developer Feedback Loops

A broken CI that developers cannot reproduce locally is a failure.

* Ensure all CI commands run locally.
* Provide tooling to execute workflows without pushing commits.
* Minimize iteration cycles caused by remote-only validation.

Fast feedback is a **developer experience requirement**, not a luxury.

---

## 4. Monorepo vs Multirepo: CI Considerations

This is not ideology—these are trade-offs.

### Monorepo

**Pros**

* Easy reuse of logic
* Atomic dependency and pipeline updates
* Centralized auditing

**Cons**

* Complex change detection
* Cache key collisions
* Runner contention from large PR fan-out
* Coarse-grained permissions

### Multirepo

**Pros**

* Natural isolation
* Simpler caching and permissions
* Clear ownership boundaries

**Cons**

* Shared logic requires dedicated repositories
* Configuration drift risk
* Harder coordinated changes

Choose deliberately. CI complexity scales differently in each model.

---

## 5. Security as a First-Class Constraint

CI/CD pipelines are privileged systems. Treat them accordingly.

### Mandatory Security Controls

* Grant **minimum required permissions** per workflow/job.
* Prefer **short-lived tokens** (OIDC) over static secrets.
* Maintain an **allow list** of approved marketplace actions.
* Pin all marketplace actions by **commit SHA**, never by tag.
* **Never** run forked pull requests on self-hosted runners.
* Use **GitHub Environments** to require approvals for sensitive stages (for example, production).

If your pipeline can deploy, it can be exploited.

---

## 6. Operational Readiness Checklist

Before calling a pipeline “production-ready”:

* Execution times are measured and tracked
* Failure modes are fast and visible
* Caching is scoped and intentional
* Security boundaries are explicit
* Reuse patterns are documented
* Developers can reproduce CI locally

If any of these are missing, the pipeline is unfinished.

---

## Final Note

Reliable CI/CD is not about YAML syntax.
It is about **systems thinking, risk management, and operational discipline**.

Treat your pipelines as production systems—and they will scale with your organization instead of slowing it down.

---
