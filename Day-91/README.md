
---

# Day-91 — Terraform Variables (Input, Locals, Outputs)

**Designing Maintainable, Secure, and Scalable Configurations**

---

## Why This Matters (Read This First)

If you hard-code values in Terraform, you are not doing Infrastructure as Code—you are writing **copy-paste infrastructure**.

In real environments:

* You manage **hundreds or thousands of resources**
* You deploy **multiple environments** (dev, stage, prod)
* You must enforce **consistency, security, and repeatability**

Variables exist to **eliminate duplication, prevent human error, and enable safe reuse**.
Ignoring them is amateur behavior.

---

## Core Problem This Solves

### Without Variables

* Same value repeated across resources
* High chance of typo-based drift (`dev`, `staging`, `stage`)
* Manual edits required for every environment change
* Impossible to scale cleanly

### With Variables

* Single source of truth
* Environment switching without code edits
* Consistent tagging and naming
* Production-grade Terraform workflows

---

## Variable Categories (Terraform Standard)

Terraform supports **three variable types**, each with a distinct responsibility. Mixing them randomly is poor design.

---

## 1. Input Variables (External Control)

**Purpose:**
Values supplied *from outside* the configuration.
Think of them as **function parameters**.

**Best Practices**

* Never hard-code environment-specific values
* Always add descriptions
* Explicitly define types
* Use defaults only for non-production

### Example: `variables.tf`

```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "channel_name" {
  description = "Logical project or channel identifier"
  type        = string
  default     = "techtutorials"
}
```

---

## 2. Local Variables (Internal Computation)

**Purpose:**
Derived or computed values used internally to avoid repetition.

**Key Rule:**
If a value is **derived**, it belongs in `locals`, not `variables`.

### Why Locals Exist

* Centralize naming conventions
* Standardize tags
* Reduce string concatenation everywhere
* Improve readability

### Example: `locals.tf`

```hcl
locals {
  env = var.environment

  bucket_name = "${var.channel_name}-bucket-${local.env}"
  vpc_name    = "${local.env}-vpc"
  ec2_name    = "${local.env}-ec2-instance"

  common_tags = {
    Environment = local.env
    Project     = "Terraform-Demo"
    ManagedBy   = "Terraform"
  }
}
```

If you repeat the same string format more than once and **don’t use locals**, you are being careless.

---

## 3. Output Variables (Controlled Exposure)

**Purpose:**
Expose selected values *after* infrastructure creation.

**Security Rule:**
Only output what is **safe and necessary**.
Never expose secrets.

### Example: `output.tf`

```hcl
output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.demo.arn
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}
```

---

## Putting It Together (Realistic Example)

### `main.tf`

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = local.bucket_name

  tags = local.common_tags
}

resource "aws_vpc" "sample" {
  cidr_block = "10.0.0.0/16"

  tags = merge(
    local.common_tags,
    { Name = local.vpc_name }
  )
}
```

No duplicated strings.
No environment hard-coding.
No naming inconsistencies.

This is **non-negotiable quality**.

---

## Variable Type System (You Must Know This)

### Primitive Types

* `string`
* `number`
* `bool`

### Complex Types

* `list`
* `set`
* `map`
* `object`
* `tuple`

### Special Types

* `any` (avoid in production)
* `null`

**Rule:**
If you don’t define a type, Terraform assumes `any`.
That flexibility becomes technical debt in production.

---

## Variable Value Sources (Precedence Order)

Highest precedence wins.

1. Command line
2. `-var-file`
3. Environment variables (`TF_VAR_*`)
4. `terraform.tfvars`
5. Default values

### Example Commands

```bash
terraform plan -var="environment=production"
terraform plan -var-file="dev.tfvars"

export TF_VAR_environment=staging
terraform plan
```

---

## Recommended File Structure

```text
├── main.tf
├── variables.tf
├── locals.tf
├── output.tf
├── provider.tf
├── terraform.tfvars
└── README.md
```

Anything else is disorganized.

---

## Security Best Practices (Do Not Ignore)

* Never commit secrets to `variables.tf`
* Use environment variables or secret managers
* Avoid outputting sensitive attributes
* Keep `terraform.tfvars` out of version control for prod
* Validate variables using `validation` blocks when needed

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

---

## Key Takeaways (No Excuses)

* Input variables = external control
* Locals = internal logic
* Outputs = controlled visibility
* Duplication is a design failure
* Hard-coding is technical debt
* Poor variable design scales disasters, not systems

If your Terraform does not follow this structure, it is not production-ready—no matter how many resources it creates.

---

