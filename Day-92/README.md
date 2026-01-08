
---

# Day-92 — Complex Variables & Validation at Scale (Production Standard)

If Day-91 taught you *why* variables matter, Day-92 teaches you **how teams avoid chaos when configurations grow**.

Simple strings don’t scale.
**Structured data does.**

---

## The Hard Truth First

If your Terraform still looks like:

* dozens of individual variables
* repeated blocks per resource
* environment logic scattered everywhere

You are **coding for today**, not for scale.

Production Terraform uses:

* **maps**
* **objects**
* **lists**
* **strict validation**
* **single-source environment configs**

---

## 1. Why Complex Variable Types Exist

Real environments need:

* multiple environments
* per-environment CIDRs
* per-environment instance sizes
* region-specific overrides
* consistent tagging

Trying to manage this with flat string variables is incompetence.

---

## 2. Using `map(string)` — First Step Toward Scale

### Example: Environment-Based Values

```hcl
variable "env_cidr_blocks" {
  description = "CIDR blocks per environment"
  type = map(string)

  default = {
    dev     = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod    = "10.2.0.0/16"
  }
}
```

Usage:

```hcl
cidr_block = var.env_cidr_blocks[var.environment]
```

**Why this matters**

* One variable
* Multiple environments
* Zero duplication
* Zero conditionals

---

## 3. Using `object` — Real Production Configuration

Maps are good.
**Objects are better.**

### Example: Full Environment Definition

```hcl
variable "environments" {
  description = "Complete environment configuration"
  type = map(object({
    cidr_block   = string
    instance_type = string
    enable_nat   = bool
  }))

  default = {
    dev = {
      cidr_block    = "10.0.0.0/16"
      instance_type = "t3.micro"
      enable_nat    = false
    }
    prod = {
      cidr_block    = "10.2.0.0/16"
      instance_type = "t3.large"
      enable_nat    = true
    }
  }
}
```

Usage:

```hcl
cidr_block    = var.environments[var.environment].cidr_block
instance_type = var.environments[var.environment].instance_type
```

This is **enterprise-grade Terraform**.

---

## 4. Lists vs Sets (People Get This Wrong)

### List

* Ordered
* Allows duplicates
* Index-based

```hcl
list(string)
```

### Set

* Unordered
* No duplicates
* Safer for security rules

```hcl
set(string)
```

**Rule**

* Use `set` for security groups, IAM principals
* Use `list` only when order matters

---

## 5. Variable Validation (Mandatory in Production)

If you don’t validate inputs, you are trusting humans.

That’s a mistake.

### Example: Environment Validation

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Example: CIDR Validation

```hcl
variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Must be a valid CIDR block."
  }
}
```

**Validation prevents outages before they exist.**

---

## 6. Combining Locals + Objects (Clean Architecture)

```hcl
locals {
  env_config = var.environments[var.environment]

  common_tags = {
    Environment = var.environment
    Project     = "Terraform-Demo"
    ManagedBy   = "Terraform"
  }
}
```

Usage:

```hcl
cidr_block = local.env_config.cidr_block
tags       = local.common_tags
```

Readable. Predictable. Safe.

---

## 7. What This Enables (This Is the Point)

With this pattern you get:

* zero environment-specific code branches
* single Terraform codebase
* clean promotion from dev → prod
* safer reviews
* easier automation
* GitOps-ready structure

---

## 8. Anti-Patterns You Must Stop Doing

If you do any of these, fix them immediately:

* one variable per environment
* `if environment == "prod"` everywhere
* hard-coded instance types
* copy-pasted resource blocks
* no validation blocks
* `type = any` in production

Those are beginner mistakes.

---

## Final Reality Check

If you understand:

* `map(object(...))`
* variable validation
* locals as computation layers

You are **already ahead of 80% of Terraform users**.

If you don’t—your infrastructure will work **until it doesn’t**, and then you won’t know why.

---

