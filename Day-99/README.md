
---

# Terraform Data Sources – Practical Usage Guide

## Overview

Terraform **data sources** allow you to **read information about existing infrastructure** without managing or modifying it.
They are essential when working in **real-world, shared, or enterprise AWS environments** where infrastructure already exists.

Instead of hardcoding values like AMI IDs, VPC IDs, or subnet IDs, data sources let Terraform **query AWS dynamically** and use the latest or correct resources at runtime.

---

## Why Data Sources Exist (The Real Reason)

Hardcoding infrastructure values is **lazy and dangerous**.

Examples of bad practices:

* Hardcoding AMI IDs
* Copy-pasting VPC IDs from AWS Console
* Manually updating Terraform files after every AWS change

Data sources solve this by:

* Eliminating manual intervention
* Enabling automation
* Making Terraform code reusable, portable, and safe

---

## Core Use Cases for Data Sources

### 1. Fetching the Latest AMI (No Hardcoding)

AMI IDs:

* Change frequently
* Are region-specific
* Break automation if hardcoded

**Data source advantage:**
Always fetch the **latest approved AMI** automatically.

---

### 2. Referencing Existing Infrastructure

In enterprise environments:

* VPCs already exist
* Subnets are shared across teams
* Networking is managed separately

You **do not recreate these resources**.

**You reference them.**

---

### 3. Working with Shared VPC Architecture

Typical enterprise setup:

* One shared VPC
* Multiple teams (Dev / QA / Prod)
* Central networking team

Terraform data sources allow:

* Safe reuse of shared resources
* Zero duplication
* Clear ownership boundaries

---

## Architecture Used in This Example

* Existing VPC (shared)
* Existing Subnet
* Latest Amazon Linux 2 AMI
* EC2 instances launched using fetched data

Terraform **does not create**:

* VPC
* Subnet
* AMI

Terraform **only reads** them.

---

## Project Structure

```
.
├── main.tf
├── provider.tf
└── backend.tf
```

---

## Terraform Provider Configuration

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

```hcl
provider "aws" {
  region = "us-east-1"
}
```

---

## Remote Backend (S3) Configuration

Terraform state **must never be local** in production.

State is stored in an S3 bucket with locking via DynamoDB.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

---

## Using Remote State for VPC (Cross-Stack Reference)

In real environments, VPCs are managed in a **separate Terraform stack**.

Use `terraform_remote_state` to fetch VPC outputs.

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-terraform-state-bucket"
    key    = "network/vpc.tfstate"
    region = "us-east-1"
  }
}
```

This allows:

* Clean separation of concerns
* Independent deployments
* Safe reuse of networking components

---

## Data Sources Implementation

### Fetch Existing VPC

```hcl
data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}
```

---

### Fetch Existing Subnet

```hcl
data "aws_subnet" "shared" {
  filter {
    name   = "tag:Name"
    values = ["subnetA"]
  }

  vpc_id = data.aws_vpc.main_vpc.id
}
```

---

### Fetch Latest Amazon Linux 2 AMI

```hcl
data "aws_ami" "linux2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

---

## EC2 Instance Using Data Sources

```hcl
resource "aws_instance" "main" {
  ami           = data.aws_ami.linux2.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.shared.id
}
```

**Key Point:**
Nothing is hardcoded.
Everything is dynamically resolved.

---

## Benefits of Using Data Sources (No Excuses)

| Benefit          | Explanation                   |
| ---------------- | ----------------------------- |
| Automation       | Zero manual updates           |
| Safety           | Prevents incorrect IDs        |
| Reusability      | Same code across environments |
| Scalability      | Works with shared infra       |
| Maintainability  | Less fragile Terraform        |
| Enterprise-ready | Matches real org structures   |

---

## When You Should Use Data Sources

Use data sources when:

* Infrastructure already exists
* Multiple teams share resources
* You want CI/CD automation
* You want Terraform that survives long-term

Do **not** use Terraform like a shell script with hardcoded values.

---

## Final Takeaway

If you are:

* Hardcoding AMI IDs
* Copying IDs from AWS Console
* Recreating shared resources

You are **not using Terraform correctly**.

Terraform data sources are **not optional** in professional environments.
They are **mandatory**.

---
