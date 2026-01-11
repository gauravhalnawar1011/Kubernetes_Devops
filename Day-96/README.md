
---

# Terraform Expressions – Practical Guide with Best Practices

## Overview

Terraform expressions are **core language constructs** that allow you to make infrastructure code **dynamic, reusable, and environment-aware**—without duplicating configuration.

They are **not functions**, but they solve many of the same problems:

* Reduce hardcoding
* Avoid copy-paste blocks
* Adapt infrastructure based on inputs (environment, scale, rules)

This repository focuses on three high-impact Terraform expressions used in real production code:

1. **Conditional Expressions**
2. **Dynamic Blocks**
3. **Splat Expressions**

Each section includes:

* What problem it solves
* Clean examples
* Real-world use cases
* Best practices

---

## 1. Conditional Expressions

### What It Is

A conditional expression selects a value based on a condition.

**Syntax**

```hcl
condition ? true_value : false_value
```

Terraform evaluates the condition first:

* If `true` → returns `true_value`
* If `false` → returns `false_value`

---

### Example: Environment-Based Instance Sizing

```hcl
instance_type = var.environment == "dev" ? "t2.micro" : "t3.micro"
```

**What this does**

* Uses smaller, cheaper instances in `dev`
* Automatically upgrades size for `staging` / `prod`
* Eliminates manual changes between environments

---

### Real-World Use Case

**Scenario:**
Your organization enforces cost control in development but requires performance in production.

```hcl
instance_type = var.environment == "dev" ? "t3.micro" : "m5.large"
```

No branching modules. No duplicated files. One clean rule.

---

### Best Practices

* Keep conditions **simple and readable**
* Use conditionals for **configuration differences**, not architecture changes
* Avoid nested conditionals (they become unreadable fast)
* Prefer conditionals over duplicated resources

**Bad Practice**

```hcl
instance_type = var.env == "dev" ? var.small : var.env == "stage" ? var.medium : var.large
```

If logic grows this complex, refactor using maps.

---

## 2. Dynamic Blocks

### What It Is

Dynamic blocks allow you to generate **nested blocks programmatically** using loops.

They are essential when:

* A resource supports repeating blocks (ingress, egress, rules)
* The number of blocks varies by environment or input

---

### Problem Without Dynamic Blocks

```hcl
ingress {
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
}

ingress {
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
}
```

This does **not scale** and leads to duplication.

---

### Solution Using Dynamic Blocks

#### Variable Definition

```hcl
variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}
```

#### Resource Configuration

```hcl
resource "aws_security_group" "example" {
  name = "example-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

---

### Real-World Use Case

**Scenario:**
Different teams expose different ports across environments.

```hcl
ingress_rules = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
```

Add or remove rules **without touching resource code**.

---

### Best Practices

* Always drive dynamic blocks from **typed variables**
* Use `list(object(...))`, not loose maps
* Keep logic out of resources—inputs decide behavior
* Use meaningful variable names (`ingress_rules`, not `rules`)

**Red Flag**
If you see 10+ repeated ingress blocks → you missed dynamic blocks.

---

## 3. Splat Expressions

### What It Is

Splat expressions retrieve **multiple values from multiple resource instances** in a single line.

They are used when a resource is created using `count` or `for_each`.

---

### Example: Multiple EC2 Instances

```hcl
resource "aws_instance" "example" {
  count         = 2
  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Trying this **will fail**:

```hcl
aws_instance.example.id
```

Because there are multiple instances.

---

### Correct Approach: Splat Expression

```hcl
aws_instance.example[*].id
```

This returns:

```hcl
list(string)
```

---

### Output Example

```hcl
output "instance_ids" {
  value = aws_instance.example[*].id
}
```

Terraform will resolve these values **after apply**.

---

### Real-World Use Case

* Passing instance IDs to:

  * Load balancers
  * Auto Scaling Groups
  * Monitoring tools
* Collecting private IPs for configuration management
* Feeding outputs into downstream modules

---

### Best Practices

* Use splat expressions only with **multiple instances**
* Prefer splat over manual indexing
* Combine with outputs or locals—not inline hacks

**Avoid**

```hcl
aws_instance.example[0].id
```

This breaks the moment scaling changes.

---

## Key Takeaways

* **Conditional expressions** adapt infrastructure without duplication
* **Dynamic blocks** eliminate repetitive nested configurations
* **Splat expressions** safely extract data from scaled resources

If you are writing Terraform without these:

* You are over-engineering
* You are duplicating code
* You are making future changes harder than necessary

---

## Final Advice (Read This Carefully)

Terraform expressions are not “advanced features.”
They are **baseline skills** for anyone writing production Terraform.

If your configs are large and still static, the problem is not Terraform—it’s how you are using it.

Practice these patterns. Break them. Fix them.
That is how you actually become good at Terraform.

---
