
---

# Day-89 — Secure S3 Backend for Terraform State

## Mission-Critical, Highly Available, Locked & Audited

---

## Purpose

This document defines **how to create and secure an Amazon S3 bucket** for:

* Terraform **remote backend**
* **S3 native state locking**
* **High availability**
* **Security-first, audit-ready environments**
* **Mission-critical workloads**

This is **not optional** for production Terraform usage.

---

## Why This Matters (Read Carefully)

Terraform state is:

* The **source of truth** for infrastructure
* A **single point of failure**
* A **high-value attack target**
* A **concurrency bottleneck**

If your state backend is misconfigured:

* You risk **infrastructure corruption**
* You risk **secret leakage**
* You risk **irreversible drift**
* You risk **simultaneous applies**

This README eliminates those risks.

---

## Design Principles (Non-Negotiable)

Your Terraform state bucket must be:

1. **Highly available**
2. **Strongly consistent**
3. **Encrypted**
4. **Versioned**
5. **Locked**
6. **Audited**
7. **Access-restricted**
8. **Regionally resilient**

Amazon S3 satisfies all of this **if configured correctly**.

---

## Architecture Overview

```
Terraform CLI
   |
   |  (IAM Auth)
   v
Amazon S3 (State Bucket)
   ├── Versioning (Enabled)
   ├── Encryption (SSE-KMS)
   ├── Native Lock Files (.tflock)
   ├── Bucket Policy (Least Privilege)
   ├── Public Access Block (Enabled)
   └── CloudTrail Logging
```

No DynamoDB.
No shortcuts.
No excuses.

---

## Step 1 — Create S3 Bucket (Correctly)

### Naming Convention (Important)

Use **globally unique, purpose-clear names**:

```
<org>-terraform-state-<region>-<env>
```

Example:

```
acme-terraform-state-ap-south-1-prod
```

---

### Create Bucket via AWS CLI

```bash
aws s3api create-bucket \
  --bucket acme-terraform-state-ap-south-1-prod \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
```

---

## Step 2 — Enable Versioning (Mandatory)

S3 **native state locking does NOT work without versioning**.

```bash
aws s3api put-bucket-versioning \
  --bucket acme-terraform-state-ap-south-1-prod \
  --versioning-configuration Status=Enabled
```

Why this matters:

* Enables rollback
* Enables lock delete markers
* Enables forensic recovery

---

## Step 3 — Enable Encryption (Mandatory)

### Option A — SSE-KMS (Recommended for Production)

```bash
aws s3api put-bucket-encryption \
  --bucket acme-terraform-state-ap-south-1-prod \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "alias/terraform-state-key"
      }
    }]
  }'
```

### Why KMS?

* Fine-grained access control
* Auditability
* Key rotation
* Compliance readiness

---

## Step 4 — Block Public Access (Always)

There is **zero justification** for public state files.

```bash
aws s3api put-public-access-block \
  --bucket acme-terraform-state-ap-south-1-prod \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

---

## Step 5 — Bucket Policy (Least Privilege)

### Example Minimal Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/TerraformExecutionRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::acme-terraform-state-ap-south-1-prod",
        "arn:aws:s3:::acme-terraform-state-ap-south-1-prod/*"
      ]
    }
  ]
}
```

**No wildcards.
No root access.
No human IAM users.**

---

## Step 6 — Enable CloudTrail Logging

State access must be auditable.

Ensure:

* CloudTrail is enabled
* Data events for S3 are logged

Why?

* Who ran `terraform apply`
* Who accessed state
* Incident forensics

---

## Step 7 — Terraform Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket       = "acme-terraform-state-ap-south-1-prod"
    key          = "prod/network/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

## High Availability & Durability (Reality Check)

Amazon S3 provides:

* **99.999999999% durability**
* **Multi-AZ replication**
* **Strong read-after-write consistency**

You do **not** need:

* Replication buckets
* DynamoDB
* Custom locking systems

S3 already solves this at planetary scale.

---

## Operational Best Practices (Hard Rules)

### Environment Isolation

* One bucket per account
* One key prefix per environment
* Never share state across environments

### Access Control

* CI/CD role only
* No developer laptops in prod
* MFA enforced for admin roles

### Recovery

* Versioning enabled
* Rollback tested
* Force-unlock only as last resort

---

## Common Mistakes (Avoid These)

| Mistake         | Consequence           |
| --------------- | --------------------- |
| No versioning   | Locking breaks        |
| Shared state    | Cross-env destruction |
| Public bucket   | Secret leakage        |
| Human IAM users | Credential sprawl     |
| Local state     | Corruption            |
| No audit logs   | Zero accountability   |

---

## Validation Checklist

Before production use, verify:

* [ ] Versioning enabled
* [ ] Encryption enabled
* [ ] Public access blocked
* [ ] IAM least privilege
* [ ] CloudTrail logging active
* [ ] Terraform ≥ 1.10
* [ ] Locking tested with parallel applies

If any item is unchecked — **do not proceed**.

---

## Important References (Read These)

* Terraform S3 Backend Docs
  [https://developer.hashicorp.com/terraform/language/settings/backends/s3](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

* Terraform State Locking
  [https://developer.hashicorp.com/terraform/language/state/locking](https://developer.hashicorp.com/terraform/language/state/locking)

* AWS S3 Security Best Practices
  [https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

* Terraform State Security
  [https://developer.hashicorp.com/terraform/language/state/sensitive-data](https://developer.hashicorp.com/terraform/language/state/sensitive-data)

---

## Final Word (Brutally Honest)

If you:

* Skip versioning
* Skip encryption
* Skip locking
* Skip IAM discipline

You are **not doing DevOps**.
You are automating outages.

Terraform state is **production data**.
Treat it with the same seriousness as databases and secrets.

---
