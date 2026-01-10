
---

# Terraform Meta-Arguments 

**count, for_each, depends_on, lifecycle, for expressions**

---

## Overview

Terraform **meta-arguments** control *how* resources are created, iterated, ordered, and managed — not *what* they create.

Most Terraform outages do **not** happen because of providers.
They happen because engineers misuse meta-arguments.

This module focuses on:

* Correct usage
* Design intent
* Production-safe patterns
* Avoiding common traps

Official reference:
[https://developer.hashicorp.com/terraform/language/meta-arguments](https://developer.hashicorp.com/terraform/language/meta-arguments)

---

## What Are Meta-Arguments?

Meta-arguments are **special arguments** supported by Terraform resources and modules that affect lifecycle, iteration, and dependency behavior.

They are evaluated by Terraform **itself**, not by providers.

---

## Meta-Arguments Covered

| Meta-Argument     | Purpose                                       |
| ----------------- | --------------------------------------------- |
| `count`           | Create multiple identical resources           |
| `for_each`        | Create multiple uniquely identified resources |
| `depends_on`      | Enforce explicit dependencies                 |
| `lifecycle`       | Control resource replacement & destruction    |
| `for` expressions | Transform collections                         |

---

## 1. `count` – Simple Replication

### When to Use

* Identical resources
* Index-based access is acceptable
* Resource identity does **not** need to persist

### Example

```hcl
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "web-${count.index}"
  }
}
```

### Reality Check

* `count` uses **numeric indexes**
* Removing an element causes **index shifting**
* Index shifting = **resource recreation**

### Best Practices

* Use only when resources are truly interchangeable
* Avoid for long-lived infrastructure
* Never combine `count` with complex identity logic

---

## 2. `for_each` – Stable & Scalable Iteration

### When to Use

* Resources must have stable identity
* Maps, sets, or named objects
* Production infrastructure

### Example (Recommended)

```hcl
variable "instances" {
  type = map(object({
    instance_type = string
  }))
}

resource "aws_instance" "web" {
  for_each      = var.instances
  ami           = var.ami_id
  instance_type = each.value.instance_type

  tags = {
    Name = each.key
  }
}
```

### Why `for_each` Wins

* No index shifting
* Predictable diffs
* Safe deletion and scaling

### Best Practices

* Prefer `for_each` over `count`
* Use maps for clarity
* Keys = resource identity

---

## 3. `depends_on` – Explicit Dependencies

### When to Use

* Terraform cannot infer dependency automatically
* Hidden or indirect dependencies

### Example

```hcl
resource "aws_iam_role" "role" {
  name = "app-role"
}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  depends_on = [aws_iam_role.role]
}
```

### Warning

If you overuse `depends_on`, your design is flawed.

### Best Practices

* Use only when implicit dependency fails
* Never use to “fix” race conditions
* Prefer data references instead

---

## 4. `lifecycle` – Resource Behavior Control

### Common `lifecycle` Options

#### `prevent_destroy`

```hcl
lifecycle {
  prevent_destroy = true
}
```

Used for:

* Databases
* Critical networking
* Production stateful resources

---

#### `create_before_destroy`

```hcl
lifecycle {
  create_before_destroy = true
}
```

Used for:

* Load balancers
* Auto Scaling Launch Templates

---

#### `ignore_changes`

```hcl
lifecycle {
  ignore_changes = [tags]
}
```

Use carefully.

### Hard Truth

If you ignore changes broadly, Terraform is no longer the source of truth.

---

## 5. `for` Expressions – Data Transformation

### Purpose

* Convert one collection into another
* Filter, reshape, compute

### Example – Map Transformation

```hcl
locals {
  instance_names = [
    for name, cfg in var.instances : name
  ]
}
```

### Example – Filtering

```hcl
locals {
  prod_instances = {
    for name, cfg in var.instances :
    name => cfg
    if cfg.env == "prod"
  }
}
```

### Best Practices

* Use in `locals`, not resources
* Keep expressions readable
* Avoid nested `for` unless necessary

---

## Meta-Argument Decision Guide

| Scenario                      | Correct Choice              |
| ----------------------------- | --------------------------- |
| Identical stateless resources | `count`                     |
| Production resources          | `for_each`                  |
| Hidden dependency             | `depends_on`                |
| Prevent deletion              | `lifecycle.prevent_destroy` |
| Data reshaping                | `for` expression            |

---

## Anti-Patterns (Don’t Do This)

❌ `count` with conditional logic
❌ Index-based resource identity
❌ `ignore_changes = all`
❌ `depends_on` everywhere
❌ Complex logic inside resource blocks

If you’re doing these, Terraform will hurt you later.

---

## Best Practices Summary (Non-Negotiable)

1. Prefer `for_each` over `count`
2. Keep resource identity stable
3. Use `lifecycle` surgically
4. Fail at plan time, not apply
5. Transform data in `locals`
6. Let Terraform infer dependencies first
7. Read plans like contracts

---

## Key Insight

Terraform meta-arguments are **power tools**.
Used correctly, they make infrastructure predictable.
Used carelessly, they guarantee outages.

If your Terraform feels fragile, the issue is not AWS.
It’s how you’re using meta-arguments.

---

## Next: Day 95

**Terraform Dynamic Blocks**

* Conditional nested blocks
* Reducing duplication
* Real-world use cases (security groups, IAM, listeners)

---

