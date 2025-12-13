
---

# Day-66

## Configure Single Sign-On (SSO) for Argo CD using Okta

This guide demonstrates how to configure **Single Sign-On (SSO)** for **Argo CD** using **Okta** as the Identity Provider (IdP).
By integrating Okta with Argo CD, users can authenticate securely using centralized identity management instead of local Argo CD accounts.

---

## Overview

Argo CD supports external authentication providers through **Dex**. In this setup:

* Okta acts as the **Identity Provider**
* Argo CD uses **SAML authentication**
* Authorization inside Argo CD is controlled via **RBAC**
* Argo CD is exposed using **NodePort** (for demo/lab purposes)

---

## Prerequisites

* AWS account
* Ubuntu 24.04 LTS EC2 instance
* Kubernetes cluster (k3s or Minikube)
* `kubectl` installed and configured
* Helm installed
* Basic understanding of:

  * Kubernetes
  * Argo CD
  * Okta

---

## What is Okta?

Okta is an enterprise-grade **Identity and Access Management (IAM)** platform that provides:

* Single Sign-On (SSO)
* Multi-Factor Authentication (MFA)
* Centralized user and group management
* Integration with thousands of applications

Okta acts as a centralized identity provider, allowing organizations to manage authentication and authorization securely and consistently.

---

## Why Use Okta Instead of GitHub or GitLab?

While GitHub and GitLab provide authentication capabilities, they are primarily **source control and CI/CD platforms**.
Okta is purpose-built for **identity and access management**, offering:

* Advanced SSO and MFA
* Centralized identity lifecycle management
* Group-based access control
* Enterprise scalability

For production-grade authentication, Okta is more robust and secure.

---

## Why Integrate SSO with Argo CD?

By default, Argo CD manages users internally, which becomes difficult as teams grow.
Integrating SSO with Okta provides:

* Centralized authentication
* Simplified user onboarding/offboarding
* Improved security
* Group-based RBAC inside Argo CD

---

## Install and Configure Argo CD

### Create Namespace

```bash
kubectl create namespace argocd
```

### Install Argo CD

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Verify Installation

```bash
kubectl -n argocd get all
```

---

## Expose Argo CD Using NodePort

Edit the Argo CD server service:

```bash
kubectl edit svc argocd-server -n argocd
```

Change:

```yaml
spec:
  type: NodePort
```

Note the assigned NodePort to access the UI.

---

## Create Okta Account and Application

1. Create an Okta account using a **business email**
2. Go to **Admin Console**
3. Navigate to:

   ```
   Applications → Create App Integration
   ```

---

## Create Okta Application (SAML)

### Sign-in Method

Select:

```
SAML 2.0
```

### General Settings

* App name: `argocd`
* App logo: optional

---

### Configure SAML Settings

#### Single Sign-On URL

```
https://<ARGOCD_NODE_IP>:<NODEPORT>/api/dex/callback
```

#### Audience URI (SP Entity ID)

```
https://<ARGOCD_NODE_IP>:<NODEPORT>/api/dex/callback
```

#### Attribute Statements

| Name | Value      |
| ---- | ---------- |
| user | user.email |

#### Group Attribute Statement

| Name  | Filter             |
| ----- | ------------------ |
| group | Matches regex `.*` |

Click **Create**.

---

## Assign Users to the Okta Application

1. Open the application
2. Go to **Assignments**
3. Assign required users or groups

---

## Collect Okta SAML Details

From the **Sign On** tab, copy:

* Identity Provider Single Sign-On URL
* Identity Provider Issuer
* X.509 Certificate (Base64 encoded)

---

## Configure Argo CD for SAML (Dex)

### Create Certificate File

```bash
nano okta.cert
```

Paste the **X.509 certificate** and save.

### Base64 Encode Certificate

```bash
base64 okta.cert -w 0
```

Copy the output.

---

## Update Argo CD ConfigMap

```bash
kubectl edit configmap argocd-cm -n argocd
```

Add the following configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  dex.config: |-
    connectors:
    - type: saml
      name: okta
      id: okta
      config:
        ssoURL: <OKTA_SSO_URL>
        redirectURI: https://<ARGOCD_NODE_IP>:<NODEPORT>/api/dex/callback
        usernameAttr: email
        emailAttr: email
        groupsAttr: group
        caData: "<BASE64_ENCODED_CERT>"
  url: https://<ARGOCD_NODE_IP>:<NODEPORT>
```

---

## Restart Argo CD Server (Required)

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

---

## Configure Argo CD RBAC (Admin Access)

Edit RBAC ConfigMap:

```bash
kubectl edit configmap argocd-rbac-cm -n argocd
```

Add:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    p, role:admin, *, *, *, allow
    g, <USERNAME_OR_OKTA_GROUP>, role:admin
  policy.default: role:readonly
```

Notes:

* Replace `<USERNAME_OR_OKTA_GROUP>` with:

  * Email address (e.g. `gaurav.halnawar@equip9.com`), or
  * Okta group name (recommended)

---

## Restart Argo CD Server Again

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

---

## Login to Argo CD Using Okta

1. Open Argo CD UI in browser
2. Click **Login via Okta**
3. Authenticate with Okta credentials
4. Argo CD dashboard will load with assigned permissions

---

## Validation

* User can log in via Okta
* Admin users can:

  * Create applications
  * Sync applications
  * Manage repositories and clusters
* Non-admin users have read-only access

---

## Conclusion

You have successfully configured:

* Okta as Identity Provider
* SAML authentication via Dex
* Secure SSO for Argo CD
* RBAC-based authorization

This setup improves security, scalability, and access management for Argo CD in production environments.

---
