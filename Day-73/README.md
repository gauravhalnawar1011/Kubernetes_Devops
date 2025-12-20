
---
 
# Day 73 – GitHub Actions (Day 1)

## Overview

Day 73 marks the start of GitHub Actions in this Cloud & DevOps learning series.
The focus of this day is to build a **foundational understanding of Continuous Integration (CI)**, why it exists, and how GitHub Actions implements CI concepts through workflows, jobs, steps, and runners.

By the end of this day, you should understand:

* Why CI/CD tooling evolved the way it did
* Why GitHub Actions is widely adopted
* Core GitHub Actions concepts and terminology
* How workflows are structured and executed
* How jobs and steps are coordinated using dependencies (DAGs)

---

## The Evolution of Continuous Integration

Modern CI/CD did not appear overnight. It is the result of decades of iteration in how software is built, tested, and delivered.

### From Punch Cards to Instant Deployments

**Punch card era (1960s–1970s)**
Programs were authored by physically punching cards and feeding them into mainframes. Iteration cycles were extremely slow, and software was typically written and consumed by the same people.

**Physical media distribution (1980s–1990s)**
Software shipped on floppy disks, CDs, and DVDs. While authoring became easier, distribution still required physical shipping, resulting in long release cycles and high costs per update.

**Web delivery (2000s)**
The rise of the internet enabled instant software delivery. Deploying a new version of an application could be as simple as updating a server. Faster delivery increased the risk of breaking production without proper validation.

**Modern release cadence (2010s–present)**
High-performing teams deploy multiple times per day. This velocity is only possible with automated validation for every change.

---

## Why Continuous Integration Emerged

Manual testing could not scale with faster release cycles. Continuous Integration solved this by:

* Automatically building and testing every commit
* Catching regressions early
* Providing rapid feedback to developers

CI moved validation **left**, closer to the point where code is written.

---

## Why GitHub Actions?

GitHub Actions is a CI/CD platform built directly into GitHub. While it entered the CI market later than tools like Jenkins, adoption grew rapidly because workflows live **next to the code**.

### Adoption Snapshot

* **CNCF Annual Survey**
  Among cloud-native and Kubernetes-focused teams, GitHub Actions ranks as the most commonly used CI platform.

* **JetBrains Developer Ecosystem Survey**
  Jenkins remains prevalent in legacy and enterprise environments, but GitHub Actions ranks second overall and ahead of GitLab CI/CD.

### Strengths of GitHub Actions

* **Low barrier to entry**
  Add a YAML file under `.github/workflows/` and CI is enabled.
* **Tight GitHub integration**
  Native access to pull requests, commits, checks, and secrets.
* **Large marketplace**
  Thousands of reusable community actions reduce custom scripting.
* **Strong ecosystem momentum**
  Widespread adoption drives rapid improvements and third-party tooling.

### When Another Platform May Be Better

* Your code is hosted outside GitHub (e.g., GitLab, Bitbucket)
* You need highly expressive, composable pipelines
* You require deep observability and analytics without third-party tools

---

## Core GitHub Actions Concepts

### Events

An **event** is anything that happens in GitHub that can trigger automation:

* `push`
* `pull_request`
* `workflow_dispatch`
* Scheduled or API-driven events

Events are defined in the `on:` section of a workflow.

---

### Workflow

A **workflow** is a CI/CD pipeline defined as a YAML file.

* Location: `.github/workflows/<workflow-name>.yml`
* Contains one or more jobs
* Triggered by one or more GitHub events

---

### Job

A **job** is a unit of work that:

* Runs on a single runner
* Contains one or more steps
* Runs in parallel with other jobs by default

---

### Step

A **step** is a single action within a job.

There are two primary step types:

1. **Inline commands** (`run`)
2. **Reusable actions** (`uses`)

Steps execute sequentially within the same job environment.

---

### Runner

A **runner** is the compute environment that executes a job.

Common GitHub-hosted runners:

* `ubuntu-24.04`
* `windows-latest`
* `macos-latest`

---

## Minimal Workflow Example

```yaml
name: Hello World

on:
  workflow_dispatch:

jobs:
  say-hello:
    runs-on: ubuntu-24.04
    steps:
      - run: echo "Hello from a GitHub Actions workflow!"
```

Key points:

* `workflow_dispatch` allows manual execution from the GitHub UI
* `runs-on` selects the runner image
* Steps execute sequentially in the same environment

---

## Step Types and Shells

Steps can:

* Run inline shell commands
* Override the default shell
* Call reusable marketplace actions

Example with multiple step types:

```yaml
jobs:
  inline-bash:
    runs-on: ubuntu-24.04
    steps:
      - run: echo "Hello from Bash"

  inline-python:
    runs-on: ubuntu-24.04
    steps:
      - run: print("Hello from Python")
        shell: python

  marketplace-action:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/hello-world-javascript-action@081a6d193d1dcb38460df1e6927486d748730f9d
        with:
          who-to-greet: "from a pinned marketplace action"
```

**Best practices:**

* Always pin third-party actions to a full commit SHA
* Explicitly define required inputs using `with`

---

## Jobs, Dependencies, and DAGs

### Parallelism and Coordination

* Jobs run in parallel by default
* Use `needs:` to define dependencies
* Dependencies form a **Directed Acyclic Graph (DAG)**

Example:

```yaml
jobs:
  job-1:
    runs-on: ubuntu-24.04
    steps:
      - run: echo "Job 1"

  job-2:
    runs-on: ubuntu-24.04
    steps:
      - run: echo "Job 2"

  job-3:
    runs-on: ubuntu-24.04
    needs:
      - job-1
      - job-2
    steps:
      - run: echo "Job 3 runs after Job 1 and Job 2"
```

Use DAGs to:

* Gate deployments on successful tests
* Control execution order
* Coordinate multi-stage pipelines

---

## Key Takeaways (Day 73)

* GitHub Actions workflows live in `.github/workflows/`
* Events trigger workflows
* Workflows contain jobs
* Jobs run on runners
* Steps execute sequentially within jobs
* Jobs can run in parallel or form DAGs using `needs`
* GitHub Actions prioritizes simplicity and tight GitHub integration

---

## What’s Next

In upcoming days, this foundation will be extended to:

* Reusable workflows and actions
* Caching and performance optimization
* Secrets and permissions
* Real-world CI/CD pipeline patterns

---

