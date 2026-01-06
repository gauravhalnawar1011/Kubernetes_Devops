
---

# Terraform Infrastructure Lifecycle — GitHub Actions (Apply & Destroy)

## Production-Grade IaC Execution with Explicit Intent

---

## Overview

This repository demonstrates a **clean, intention-driven Infrastructure as Code (IaC) workflow** using:

* **Terraform**
* **AWS (OIDC-based authentication)**
* **Remote state with S3 + DynamoDB locking**
* **GitHub Actions**

Infrastructure **creation** and **destruction** are intentionally split into **two separate workflows** to ensure safety, auditability, and operational clarity.

This design aligns with **real-world platform and DevOps best practices**.

---

## Repository Structure

```
.
├── Day-90/
│   └── main.tf
└── .github/
    └── workflows/
        ├── terraform-apply.yml
        └── terraform-destroy.yml
```

* `Day-90/` is a **Terraform root module**
* Each workflow executes Terraform **only within this directory**
* State is shared via a **remote backend**

---

## Terraform Configuration

### Providers

```hcl
aws    ~> 6.0
random ~> 3.6
```

### Remote Backend (Mandatory)

```hcl
backend "s3" {
  bucket         = "space9-terraform-bucket-v1"
  key            = "dev/terraform.tfstate"
  region         = "ap-south-1"
  encrypt        = true
  dynamodb_table = "space9-terraform"
}
```

### Why this matters

* **S3** stores Terraform state securely
* **DynamoDB** ensures state locking
* Prevents:

  * Concurrent state corruption
  * Accidental overwrites
  * Unsafe parallel execution

State is treated as **production data**.

---

## Authentication Model (OIDC)

Both workflows authenticate to AWS using **GitHub OIDC**:

* No long-lived AWS access keys
* No secrets rotation overhead
* Short-lived, scoped credentials

Required repository variable:

```
AWS_OIDC_ROLE = arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>
```

The IAM role must trust `token.actions.githubusercontent.com`.

---

## Workflow 1 — Terraform Apply

**Purpose:**
Create or update infrastructure.

**Trigger:**
Manual (`workflow_dispatch`)

**What it does:**

1. Initializes Terraform
2. Generates an execution plan
3. Applies the plan
4. Leaves infrastructure running

**Key principle:**
This workflow **never destroys resources**.

### Execution Flow

```
init → plan → apply
```

This workflow represents **intent to create infrastructure**.

---

## Workflow 2 — Terraform Destroy

**Purpose:**
Explicitly remove infrastructure.

**Trigger:**
Manual (`workflow_dispatch`)

**What it does:**

1. Re-initializes Terraform
2. Reads the existing remote state
3. Destroys all tracked resources

### Execution Flow

```
init → destroy
```

This workflow represents **explicit destructive intent**.

---

## Why Apply and Destroy Are Separate

This separation is **deliberate and non-negotiable**.

### Benefits

* Prevents accidental deletions
* Clear audit trail
* Explicit human intent
* Independent access control
* Aligns with production change-management standards

### Industry Reality

> Destructive actions should never be implicit or coupled with creation logic.

This is how **real infrastructure teams operate**.

---

## Test Resources

The Terraform configuration creates:

* A uniquely named S3 bucket using `random_string`
* Used only to validate:

  * Backend configuration
  * State locking
  * OIDC permissions
  * End-to-end Terraform lifecycle

This setup is intentionally simple but **structurally correct**.

---

## Operational Guidelines

### When to run Apply

* Creating new infrastructure
* Updating existing configuration
* Validating backend and permissions

### When to run Destroy

* Cleaning up test infrastructure
* Decommissioning environments
* Explicit teardown events only

### What not to do

* Do not run destroy automatically
* Do not mix apply and destroy in PRs
* Do not change backend config between runs
* Do not manage state manually

---

## Key Takeaways

* Terraform state is the **source of truth**
* Apply and destroy are **separate intents**
* OIDC is the **preferred auth model**
* GitHub Actions can safely manage IaC when used correctly
* Simplicity + discipline beats clever automation

---

## Interview-Grade Summary

> Infrastructure creation and destruction are handled via separate GitHub Actions workflows.
> Both workflows reference the same Terraform root and remote backend to ensure state consistency.
> This design enforces explicit intent, improves auditability, and aligns with production IaC best practices.

---

## Status

✅ Production-safe
✅ State-secure
✅ OIDC-enabled
✅ Intent-driven
✅ Auditable

---

