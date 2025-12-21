
---


# GitHub Actions Playlist — Day 2 (Day 74)

This repository is part of an **open-source GitHub Actions learning playlist**, focused on **core workflow mechanics** rather than surface-level YAML snippets.

**Day 74** goes beyond “what is GitHub Actions” and drills into:
- How workflows are triggered
- How environment variables *actually* scope and behave
- How data moves between steps and jobs
- How secrets, variables, and environments differ in practice
- How contexts and expressions tie everything together

If you already know basic CI/CD concepts, this repo is designed to **remove ambiguity and mental shortcuts** you may still be relying on.

---

## What This Day Covers

### 1. Workflow Trigger Events

Almost **every activity in GitHub** can trigger a workflow. This repository demonstrates and discusses the most common and useful ones.

#### Common Trigger Types
- **Manual trigger**
  ```yaml
  on:
    workflow_dispatch:


* **Push events**

  ```yaml
  on:
    push:
      branches:
        - main
  ```

* **Pull request events**

  ```yaml
  on:
    pull_request:
      types: [opened, synchronize, reopened]
  ```

* **Scheduled (Cron) workflows**

  ```yaml
  on:
    schedule:
      - cron: "0 0 * * *"
  ```

* **Many more**

  * `release`
  * `workflow_run`
  * `issue_comment`
  * `repository_dispatch`

**Key takeaway**:
Triggers define *when* automation starts—not *what* it does. Poor trigger design leads to noisy, expensive, and brittle pipelines.

---

### 2. Environment Variables and Scope

Workflow:
`03-core-features--05-environment-variables.yaml`

This workflow exists to kill a common misconception:

> “Environment variables are global once defined.”

They are not.

#### Scope Hierarchy

```
Workflow
 └── Job
     └── Step
```

Variables **cascade downward**, never upward.

#### Example

```yaml
env:
  WORKFLOW_VAR: I_AM_WORKFLOW_SCOPED

jobs:
  job-1:
    runs-on: ubuntu-24.04
    env:
      JOB_VAR: I_AM_JOB_1_SCOPED
    steps:
      - name: Inspect scopes job 1 step 1
        env:
          STEP_VAR: I_AM_STEP_SCOPED
        run: |
          echo "WORKFLOW_VAR: $WORKFLOW_VAR"
          echo "JOB_VAR:      $JOB_VAR"
          echo "STEP_VAR:     $STEP_VAR"

      - name: Inspect scopes job 1 step 2
        run: |
          echo "WORKFLOW_VAR: $WORKFLOW_VAR"
          echo "JOB_VAR:      $JOB_VAR"
          echo "STEP_VAR:     ${STEP_VAR:-<UNSET>}"

  job-2:
    runs-on: ubuntu-24.04
    steps:
      - name: Inspect scopes job 2
        run: |
          echo "WORKFLOW_VAR: $WORKFLOW_VAR"
          echo "JOB_VAR:      ${JOB_VAR:-<UNSET>}"
          echo "STEP_VAR:     ${STEP_VAR:-<UNSET>}"
```

#### Rules You Must Internalize

* Workflow-level variables are visible everywhere.
* Job-level variables **do not cross job boundaries**.
* Step-level variables die when the step ends.
* Use `${{ env.VAR_NAME }}` when referencing variables **inside YAML logic** (e.g. `if:`).

If this behavior surprises you, your pipelines are already fragile—you just haven’t noticed yet.

---

### 3. Passing Data Between Steps and Jobs

Workflow:
`03-core-features--06-passing-data.yaml`

Environment variables are **not** the correct mechanism for cross-job communication.

GitHub gives you two explicit tools:

#### `$GITHUB_ENV`

* Persists variables **for the remainder of the current job**
* Invisible to downstream jobs

#### `$GITHUB_OUTPUT`

* Used to expose **step outputs**
* Can be promoted to **job outputs**
* Consumable via `needs`

#### Example

```yaml
jobs:
  producer:
    runs-on: ubuntu-24.04
    outputs:
      foo: ${{ steps.generate-foo.outputs.foo }}
    steps:
      - name: Generate and export foo
        id: generate-foo
        run: |
          foo=bar
          echo "foo=${foo}" >> "$GITHUB_OUTPUT"
          echo "FOO=${foo}" >> "$GITHUB_ENV"

  consumer:
    runs-on: ubuntu-24.04
    needs: producer
    steps:
      - name: Inspect values
        run: |
          echo "Value from producer: ${{ needs.producer.outputs.foo }}"
          echo "FOO in consumer: ${FOO:-<UNSET>}"
```

#### Important Observation

* `FOO` **does not survive** into the consumer job
* Job outputs **do**

If you are still trying to “share env vars between jobs,” you are solving the wrong problem.

---

### 4. Secrets, Variables, and Environments

Workflow:
`03-core-features--07-secrets-and-variables.yaml`

GitHub provides **three configuration layers**, and they are not interchangeable.

#### Secrets

* Encrypted
* Masked in logs
* Intended for credentials and tokens

#### Variables

* Plain text
* Visible in logs
* Use only for non-sensitive configuration

#### Environments

* Allow **deployment gates**
* Support **manual approvals**
* Enable **environment-specific secrets and variables**

#### Example

```yaml
jobs:
  staging-environment:
    runs-on: ubuntu-24.04
    environment: staging
    env:
      EXAMPLE_REPOSITORY_SECRET: ${{ secrets.EXAMPLE_REPOSITORY_SECRET }}
      EXAMPLE_REPOSITORY_VARIABLE: ${{ vars.EXAMPLE_REPOSITORY_VARIABLE }}
      EXAMPLE_ENVIRONMENT_SECRET: ${{ secrets.EXAMPLE_ENVIRONMENT_SECRET }}
      EXAMPLE_ENVIRONMENT_VARIABLE: ${{ vars.EXAMPLE_ENVIRONMENT_VARIABLE }}
```

GitHub **automatically masks secrets**.
Variables are printed as-is—if you leak something, that is on you.

---

### 5. Contexts and Expressions

Contexts expose structured metadata and are accessed using:

```yaml
${{ ... }}
```

#### Common Contexts

* `github` — repository, event, actor, ref, SHA
* `env` — environment variables
* `secrets` / `vars` — managed configuration
* `needs` — outputs from prerequisite jobs

#### Example Logic

```yaml
if: ${{ github.ref == 'refs/heads/main' }}
```

Expressions are not optional—they are how you write **conditional, maintainable workflows** instead of duplicating YAML.

---


