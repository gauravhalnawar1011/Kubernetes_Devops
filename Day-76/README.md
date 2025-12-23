
# GitHub Actions → AWS Authentication (Static Credentials vs OIDC)

This repository demonstrates **two different ways** to authenticate GitHub Actions workflows with AWS:

1. ❌ **Static AWS access keys** (legacy, insecure)
2. ✅ **OIDC (OpenID Connect)** using GitHub Actions (recommended, production-grade)

The goal of this demo is to **clearly show how OIDC works**, why it is better, and how to configure it correctly in AWS IAM.

---

## What This Demo Proves

- GitHub Actions can authenticate to AWS **without storing secrets**
- AWS issues **short-lived credentials** at runtime using OIDC
- IAM trust policies control **which repository and branch** are allowed
- You can visibly compare:
  - IAM **user** authentication (static)
  - IAM **role** authentication (OIDC)

Both methods are included **only for learning and comparison**.

---

## Repository Structure

```

.
├── .github/
│   └── workflows/
│       └── third-party-auth.yml
└── README.md

```

---

## Prerequisites

Before running this demo, you must have:

- An AWS account
- A GitHub repository (this repo)
- IAM permissions to create:
  - Identity providers
  - IAM roles
- GitHub Actions enabled on the repo

---

## Workflow Overview

The workflow contains **three jobs**:

### 1. `auth-to-aws-static` (Legacy)
- Uses long-lived AWS access keys
- Credentials are stored as GitHub secrets
- Authenticates as an **IAM user**

> ⚠️ Included for demo purposes only.  
> Do **not** use this approach in production.

### 2. `auth-to-aws-oidc` (Recommended)
- Uses GitHub Actions OIDC
- No AWS secrets stored in GitHub
- Authenticates as an **assumed IAM role**

### 3. `compare-identities`
- Prints identity details from both jobs
- Makes the difference obvious in logs

---

## GitHub Secrets (Static Auth Only)

Required **only** for the static credentials job:

| Secret Name | Description |
|------------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

OIDC **does not require any secrets**.

---

## AWS Setup – OIDC Configuration (Required)

### Step 1: Create OIDC Identity Provider

AWS Console → IAM → Identity providers → Add provider

- Provider type: **OpenID Connect**
- Provider URL:
```

[https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com)

```
- Audience:
```

sts.amazonaws.com

````

---

### Step 2: Create IAM Role for GitHub Actions

- Trusted entity type: **Web identity**
- Identity provider: `token.actions.githubusercontent.com`
- Attach required permissions (example: read-only for demo)

---

### Step 3: Configure Trust Relationship (Critical)

Replace the role trust policy with the following:

```json
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::715210804309:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:gauravhalnawar1011/Kubernetes_Devops:ref:refs/heads/main"
      }
    }
  }
]
}
````

### Important Notes

* `sub` is **case-sensitive**
* Repo owner, repo name, and branch **must match exactly**
* A wrong `sub` value will cause OIDC to fail with:

  ```
  Not authorized to perform sts:AssumeRoleWithWebIdentity
  ```

---

## Workflow File

`.github/workflows/third-party-auth.yml`

```yaml
name: Third Party Authentication Demo

on:
  workflow_dispatch:

jobs:
  auth-to-aws-static:
    runs-on: ubuntu-24.04
    outputs:
      aws_account_id: ${{ steps.identity.outputs.account }}
      aws_arn: ${{ steps.identity.outputs.arn }}
    steps:
      - name: Configure AWS credentials using static access keys
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-2
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Get AWS identity (static)
        id: identity
        run: |
          IDENTITY=$(aws sts get-caller-identity)
          echo "account=$(echo $IDENTITY | jq -r .Account)" >> $GITHUB_OUTPUT
          echo "arn=$(echo $IDENTITY | jq -r .Arn)" >> $GITHUB_OUTPUT

  auth-to-aws-oidc:
    runs-on: ubuntu-24.04
    permissions:
      id-token: write
      contents: read
    outputs:
      aws_account_id: ${{ steps.identity.outputs.account }}
      aws_arn: ${{ steps.identity.outputs.arn }}
    steps:
      - name: Configure AWS credentials using OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-2
          role-to-assume: arn:aws:iam::715210804309:role/github_action_oidc

      - name: Get AWS identity (OIDC)
        id: identity
        run: |
          IDENTITY=$(aws sts get-caller-identity)
          echo "account=$(echo $IDENTITY | jq -r .Account)" >> $GITHUB_OUTPUT
          echo "arn=$(echo $IDENTITY | jq -r .Arn)" >> $GITHUB_OUTPUT

  compare-identities:
    runs-on: ubuntu-24.04
    needs:
      - auth-to-aws-static
      - auth-to-aws-oidc
    steps:
      - name: Compare authentication methods
        run: |
          echo "Static Auth ARN: ${{ needs.auth-to-aws-static.outputs.aws_arn }}"
          echo "OIDC Auth ARN:   ${{ needs.auth-to-aws-oidc.outputs.aws_arn }}"
```

---

## Expected Output

### Static Authentication

```
arn:aws:iam::<account-id>:user/<iam-user>
```

### OIDC Authentication

```
arn:aws:sts::<account-id>:assumed-role/github_action_oidc/GitHubActions
```

This confirms:

* Static auth → IAM user
* OIDC auth → assumed IAM role

---

## Why OIDC Is the Correct Approach

| Aspect              | Static Keys | OIDC        |
| ------------------- | ----------- | ----------- |
| Secrets in GitHub   | Yes         | No          |
| Credential lifetime | Long-lived  | Short-lived |
| Rotation required   | Manual      | Automatic   |
| Blast radius        | High        | Low         |
| Production ready    | ❌           | ✅           |

---

## Common Failure Causes

* Incorrect `sub` in trust policy
* Wrong repo owner or repo name
* Branch mismatch (`main` vs `master`)
* Missing `id-token: write` permission

---

## Final Recommendation

* Use static credentials **only for demos**
* Use OIDC for **all real CI/CD pipelines**
* Remove AWS access keys from GitHub once OIDC is verified

---

