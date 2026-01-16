
---
 
# Static Website Hosting on AWS using Terraform (Best Practices)

This project provisions a **secure, scalable, and production-ready static website hosting architecture** on AWS using **Terraform**.  
The website is hosted on **Amazon S3 (private)** and delivered globally via **Amazon CloudFront**, with **HTTPS enabled using ACM** and **custom domain support (`space9.in`) via Route53**.

The infrastructure strictly follows **AWS and DevOps best practices** for security, performance, and maintainability.

---

## Architecture Overview

```

User
└── Route53 (space9.in)
└── CloudFront (HTTPS, caching, compression)
└── Private S3 Bucket (Origin Access Control)

```

### Key Design Principles
- **No public S3 access**
- **HTTPS enforced**
- **Least-privilege IAM**
- **Global low-latency delivery**
- **Infrastructure as Code (IaC)**

---

## Directory Structure

```

.
├── code
│   ├── backend.tf        # Remote state configuration
│   ├── provider.tf       # AWS provider configuration
│   ├── variables.tf      # Input variables
│   ├── main.tf           # Core infrastructure resources
│   └── outputs.tf        # Outputs (CloudFront URL)
├── www
│   ├── index.html        # Website entry point
│   ├── script.js         # Client-side logic
│   └── style.css         # Styling
└── README.md

````

---

## What This Infrastructure Does

### 1. **Private S3 Bucket**
- Stores static website files (`HTML/CSS/JS`)
- **Public access fully blocked**
- Objects are **only accessible via CloudFront**

Why:
- Prevents direct internet access to S3
- Eliminates accidental data exposure
- Meets security compliance standards

---

### 2. **CloudFront Origin Access Control (OAC)**
- Replaces legacy Origin Access Identity (OAI)
- Uses **SigV4 request signing**
- Ensures CloudFront is the **only trusted consumer** of S3 content

Why:
- Modern, AWS-recommended approach
- Stronger security guarantees
- Required for future-proof architectures

---

### 3. **CloudFront Distribution**
- Global CDN with edge caching
- Gzip/Brotli compression enabled
- Only `GET` and `HEAD` allowed (static site optimized)
- HTTP automatically redirected to HTTPS

Why:
- Faster global performance
- Reduced origin load
- Enforced secure access
- Lower latency for end users

---

### 4. **ACM Certificate (us-east-1)**
- HTTPS enabled using AWS Certificate Manager
- Certificate is issued in **us-east-1** (mandatory for CloudFront)
- Integrated directly with CloudFront

Why:
- Secure encryption in transit
- No certificate management overhead
- AWS-managed renewal

---

### 5. **Route53 DNS Configuration**
- Custom domain `space9.in`
- Alias record pointing to CloudFront distribution
- No hardcoded IPs

Why:
- Highly available DNS
- Seamless CloudFront integration
- Zero maintenance for endpoint changes

---

### 6. **Local Website File Deployment**
- Static files uploaded from `www/` directory
- `etag` used for content-based updates
- Correct MIME types applied automatically

Why:
- Deterministic deployments
- Browser caching behaves correctly
- Changes propagate safely through CloudFront

---

## Security Best Practices Applied

- ✅ S3 Block Public Access enabled
- ✅ No public bucket policies
- ✅ Least-privilege bucket policy scoped to CloudFront ARN
- ✅ HTTPS enforced at CDN level
- ✅ No write permissions from CloudFront to S3
- ✅ No unnecessary IAM roles or policies

---

## Performance Best Practices Applied

- ✅ CloudFront caching
- ✅ Compression enabled
- ✅ Optimized HTTP methods
- ✅ Single origin, low operational complexity
- ✅ PriceClass optimized for cost vs performance

---

## How to Deploy

```bash
cd code
terraform init
terraform plan
terraform apply
````

After deployment:

* Access the site using **[https://space9.in](https://space9.in)**
* CloudFront propagation may take a few minutes

---

## Outputs

* **CloudFront Distribution Domain**
* Can be used for debugging or verification

---

## Why This Architecture Works Well

This setup is:

* **Production-ready**
* **Secure by default**
* **Scalable without redesign**
* **Cost-efficient**
* **Easy to explain in DevOps interviews**

It follows the same architecture used by real-world SaaS companies for hosting static frontends securely on AWS.

---

## Possible Future Enhancements

* CloudFront cache invalidation automation
* CI/CD pipeline for website deployment
* AWS WAF for edge security
* Access logs → S3 + Athena
* Multi-environment support (dev/stage/prod)

---

