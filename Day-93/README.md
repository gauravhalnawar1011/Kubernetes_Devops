
---

# Terraform Type Constraints

**AWS Infrastructure with Strong Typing, Validation, and Best Practices**

---

## Overview

This repository demonstrates **correct, explicit, and disciplined use of Terraform type constraints** across real AWS resources.
The focus is **type safety**, **predictability**, and **defensive configuration**, not copy-paste Terraform.

If you are still writing untyped variables or relying on implicit conversions, you are creating fragile infrastructure. This module shows how to avoid that.

---

## What This Module Covers

* Explicit primitive and complex types
* Correct use of `list`, `set`, `map`, `tuple`, and `object`
* Practical type-driven infrastructure decisions
* Real-world validation patterns
* Clean separation of concerns (`variables`, `locals`, `resources`, `outputs`)
* AWS EC2 + Security Group implementation using typed inputs

---

## Terraform & Provider Versions

```hcl
Terraform >= 1.5.0
AWS Provider = 6.16.0
```

**Why this matters**
Terraform type behavior and validation rules evolve. Locking versions avoids silent failures and breaking changes.

---

## File Structure

```text
.
├── main.tf          # Core AWS resources
├── variables.tf     # Strongly typed variable definitions
├── locals.tf        # Derived values and reusable logic
├── outputs.tf       # Typed outputs and demonstrations
├── provider.tf     # Provider configuration and constraints
└── README.md        # This document
```

---

## Core Design Principles

### 1. Types Are Mandatory, Not Optional

Every variable has:

* A declared type
* A description
* A sane default (where appropriate)

This is not optional. Untyped variables are technical debt.

---

### 2. Correct Use of Collection Types

| Type     | Used When                             |
| -------- | ------------------------------------- |
| `list`   | Order matters, duplicates allowed     |
| `set`    | Order irrelevant, uniqueness enforced |
| `map`    | Named values with string keys         |
| `tuple`  | Fixed structure, positional meaning   |
| `object` | Structured configuration blocks       |

If you misuse these, Terraform will not protect you.

---

## Variable Types Explained (With Intent)

### Primitive Types

```hcl
string  → environment names, instance types
number  → counts, sizes, ports
bool    → feature toggles
```

These should never be overloaded or reused ambiguously.

---

### Collection & Complex Types

#### `list(string)`

Used for:

* CIDR blocks
* Allowed instance types
* Regions

Why: ordering and indexing matter.

---

#### `set(string)`

Used for:

* Availability Zones

Why: duplicates make no sense and order should not be relied upon.

⚠️ **Reality check:**
If you convert a set to a list and index it, you are accepting nondeterminism. This module does it *only* to demonstrate the behavior—not because it is ideal.

---

#### `map(string)`

Used for:

* Tags

Why: tags are named attributes, not ordered values.

---

#### `tuple([string, string, number])`

Used for:

* Network configuration

```hcl
[VPC CIDR, Subnet CIDR, Port]
```

Why:
This enforces positional meaning and prevents accidental reshaping.

---

#### `object({...})`

Used for:

* Server configuration

This is the **most important type** in real Terraform work.

It enforces:

* Schema
* Required attributes
* Attribute-level typing

If you are still passing 10 independent variables instead of one object, your design is weak.

---

## locals.tf – Why Locals Exist

Locals are used to:

* Normalize naming
* Generate derived values
* Avoid duplication
* Enforce consistency

Example:

* `common_tags`
* Derived CIDRs
* Standardized resource names

If you repeat string interpolation across files, you are doing it wrong.

---

## main.tf – Resource Implementation

### EC2 Instance

Demonstrates:

* `string` → AMI, instance type
* `number` → instance count, disk size
* `bool` → monitoring, public IP
* `set → list` conversion
* `map` → tagging
* `object` → structured config access

This is how Terraform **should** look.

---

### Security Group

Demonstrates:

* Typed ingress rules
* Tuple-based port definition
* List-based CIDR enforcement

No magic numbers. No hardcoding without explanation.

---

## outputs.tf – Outputs With Meaning

Outputs are not decoration.

Each output:

* Demonstrates a type
* Shows transformations
* Explains intent

Bad output example:

```hcl
output "id" { value = aws_instance.x.id }
```

Good output example:

```hcl
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
}
```

---

## Validation & Constraints (What You Should Add Next)

This module intentionally keeps validation minimal for teaching clarity.
In production, **you must add validation blocks**.

Example:

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

If your Terraform accepts invalid business input, **that is your failure**, not Terraform’s.

---

## Best Practices (Non-Negotiable)

1. **Always specify types**
2. **Never rely on implicit conversions**
3. **Prefer object variables over many primitives**
4. **Validate business rules explicitly**
5. **Use sets only when order does not matter**
6. **Do not index sets in production logic**
7. **Document intent in descriptions**
8. **Keep locals deterministic**
9. **Lock provider versions**
10. **Read plans like legal contracts**

If you violate these, you are building unreliable infrastructure.

---

## Known Weak Points (Yes, I’m Calling Them Out)

* Converting `set` to `list` and indexing is non-deterministic
* Tuple-based networking is rigid and not scalable long-term
* No explicit `validation` blocks yet
* No module abstraction (intentional for teaching)

These are acceptable **only because this is a learning module**.

---

## Who This Is For

* DevOps engineers moving beyond beginner Terraform
* Engineers preparing for real production IaC
* People tired of broken plans and silent misconfigurations
* Anyone who wants Terraform to fail fast and loudly

---

