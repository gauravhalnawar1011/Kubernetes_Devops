
---

# GitHub Actions → AWS OIDC Setup (Terraform CI/CD)

## Overview

This document explains how to securely configure **GitHub Actions with AWS using OIDC (OpenID Connect)**.

The goal is simple:

> Allow GitHub Actions to assume an AWS IAM role **without storing AWS access keys or secrets**.

This is the **recommended and production-grade approach** for CI/CD pipelines using Terraform.

---

## Why OIDC (Important)

Traditional CI/CD pipelines store:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

This is **not secure** at scale.

With OIDC:

* No long-lived credentials
* Short-lived, auto-rotated credentials
* Access is tightly scoped to repo + branch
* Strong auditability

This is how modern DevOps teams operate.

---

## High-Level Flow

```
GitHub Actions
   |
   |-- Issues OIDC Token
   |
AWS IAM OIDC Provider
   |
   |-- Validates token claims
   |
IAM Role (Assumed)
   |
   |-- Temporary credentials
   |
Terraform / AWS APIs
```

---

## Prerequisites

* AWS Account
* GitHub Repository
* Terraform / GitHub Actions basic knowledge
* Admin access to AWS IAM (one-time setup)

---

## Step 1: Create IAM OIDC Provider (AWS Console)

### AWS Console Path

```
IAM → Identity providers → Add provider
```

### Provider Configuration

| Field         | Value                                         |
| ------------- | --------------------------------------------- |
| Provider type | OpenID Connect                                |
| Provider URL  | `https://token.actions.githubusercontent.com` |
| Audience      | `sts.amazonaws.com`                           |

📸 **Screenshot Placeholder**
*Add screenshot of OIDC provider creation screen here*

```md
<img width="1635" height="995" alt="Image" src="https://github.com/user-attachments/assets/6d4c7070-ba6e-42d3-9db3-6a2f39f18f06" />
```

---

## Step 2: Create IAM Role for GitHub Actions

### AWS Console Path

```
IAM → Roles → Create role
```

### Trusted Entity

* **Type**: Web identity
* **Identity provider**: `token.actions.githubusercontent.com`
* **Audience**: `sts.amazonaws.com`

```md
<img width="1635" height="995" alt="Image" src="https://github.com/user-attachments/assets/67773077-02ae-4b94-934c-15a778b37e36" />
```

---

## Step 3: Configure Trust Policy (Critical)

Restrict **who** can assume the role.

### Recommended Restrictions

* GitHub organization / username
* Specific repository
* Specific branch (`main`)

### Example Trust Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:sub":
            "repo:<GITHUB_ORG>/<REPO_NAME>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```


```md
<img width="1635" height="995" alt="Image" src="https://github.com/user-attachments/assets/76de0faf-5f83-4e11-9eff-b5bda05b0b4e" />
```

⚠️ **Do not use wildcards unless absolutely necessary**.

---

## Step 4: Attach IAM Permissions (Least Privilege)

For Day-03 (S3 bucket creation), attach a **scoped policy**, not admin.

### Example Permissions (S3 only)

* `s3:CreateBucket`
* `s3:DeleteBucket`
* `s3:PutBucketTagging`
* `s3:GetBucketTagging`
* `s3:ListBucket`


---

## Step 5: Note the IAM Role ARN

Example:

```
arn:aws:iam::123456789012:role/github-actions-terraform-dev
```

✅ This ARN **is NOT a secret**
❌ Do not store AWS access keys anywhere

---

## Step 6: Configure GitHub Actions Workflow

### Required Permissions

```yaml
permissions:
  id-token: write
  contents: read
```

### Example Workflow Snippet

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-terraform-dev
          aws-region: us-east-1

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan

      - name: Terraform Apply
        run: terraform apply -auto-approve
```

---

## What NOT to Do (Common Mistakes)

❌ Store `AWS_ACCESS_KEY_ID` in GitHub Secrets
❌ Store `AWS_SECRET_ACCESS_KEY` in GitHub Secrets
❌ Use `AdministratorAccess` for Terraform
❌ Leave trust policy wide open
❌ Use OIDC provider ARN in GitHub Actions

---

## Verification Checklist

* [ ] No AWS secrets stored in GitHub
* [ ] IAM role restricted to repo + branch
* [ ] OIDC provider configured once
* [ ] GitHub Actions successfully assumes role
* [ ] Terraform runs without credentials in code

---

## Security Summary

| Item                | Status       |
| ------------------- | ------------ |
| Static AWS keys     | ❌ Not used   |
| Credential rotation | ✅ Automatic  |
| Least privilege     | ✅ Enforced   |
| Branch protection   | ✅ Enabled    |
| Auditability        | ✅ CloudTrail |

---

## Next Improvements

* Separate roles for `dev`, `stage`, `prod`
* Require manual approval for Terraform apply
* Remote Terraform state (S3 + DynamoDB)
* Reusable GitHub Actions workflows

---

## Final Note

If your pipeline still relies on AWS access keys,
**you are solving yesterday’s problem with yesterday’s tools**.

OIDC is not optional anymore — it is the baseline.

---

