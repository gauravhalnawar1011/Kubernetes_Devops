
---

# **Argo CD RBAC & Project-Based Access Control Demo**

This repository demonstrates how to design and implement **environment-based access control** in Argo CD using:

* Argo CD Projects
* Application isolation (dev, test, prod)
* Local user accounts
* RBAC policies
* Automated password setup
* Restricting the default project

This demo is useful for learning, testing RBAC flows, onboarding DevOps engineers, or training teams on secure GitOps practices.

---

# **Repository Structure**

```
.
├── applications
│   ├── dev
│   │   └── springboot-dev.yaml
│   ├── prod
│   │   └── springboot-prod.yaml
│   └── test
│       └── springboot-test.yaml
│
├── local-users
│   ├── argocd-cm-users.yaml
│   └── argocd-user-passwords.sh
│
├── projects
│   ├── default
│   │   └── remove-default-access.yaml
│   ├── dev
│   │   └── dev-project.yaml
│   ├── prod
│   │   └── prod-project.yaml
│   └── test
│       └── test-project.yaml
│
└── rbac
    └── argocd-rbac-config.yaml
```

---

# **1. Overview**

Argo CD allows you to organize and limit access to applications using **Projects**.
A Project defines:

* Allowed Git repositories
* Allowed cluster destinations
* Resource whitelists
* RBAC roles
* User permissions

In this demo, we create three isolated environments:

* Development
* Testing
* Production

Each environment gets:

* Its own **Project**
* Its own **Argo CD Application**
* Its own **RBAC role**
* A designated **local user**

This ensures a user can only interact with applications in the project assigned to them.

---

# **2. Restricting the Default Project**

Argo CD comes with a built-in **default** project.
It has unrestricted access and is not suitable for secure environments.

We remove all permissions from it using:

```
projects/default/remove-default-access.yaml
```

After applying this:

* No application may use the default project
* Only environment-specific projects may be selected

This forces teams to use structured, isolated Projects.

---

# **3. Creating Environment-Based Projects**

The following files define isolated Projects:

| Project     | YAML File                         |
| ----------- | --------------------------------- |
| Development | `projects/dev/dev-project.yaml`   |
| Testing     | `projects/test/test-project.yaml` |
| Production  | `projects/prod/prod-project.yaml` |

Each project defines:

* Allowed repositories
* Allowed namespaces (`dev*`, `test*`, `prod*`)
* Allowed clusters
* Resource permissions

These Projects separate workloads and enforce environment boundaries.

---

# **4. Applications per Environment**

Each application is associated with its respective Project:

| Environment | YAML File                                |
| ----------- | ---------------------------------------- |
| Dev         | `applications/dev/springboot-dev.yaml`   |
| Test        | `applications/test/springboot-test.yaml` |
| Prod        | `applications/prod/springboot-prod.yaml` |

Applications share:

* A values repository
* A Helm chart repository
* Automated sync policy
* Namespace auto-creation options

This setup reflects a real-world multi-environment GitOps workflow.

---

# **5. Local User Accounts (Testing Use Only)**

File:

```
local-users/argocd-cm-users.yaml
```

Defines the following local users:

* developer
* tester
* devops

Each user is given:

* UI login access
* API key access

This does NOT set passwords.

---

# **6. Setting User Passwords (Testing Automation)**

File:

```
local-users/argocd-user-passwords.sh
```

This script:

* Logs in as admin
* Updates passwords for each local user
* Enables rapid re-setup of the environment

Use only for testing—not production.

Run:

```
chmod +x local-users/argocd-user-passwords.sh
./local-users/argocd-user-passwords.sh
```

---

# **7. RBAC Configuration**

File:

```
rbac/argocd-rbac-config.yaml
```

Defines RBAC rules:

* developer → dev-project
* tester → test-project
* devops → prod-project
* default behavior → read-only

This ensures proper least-privilege access:

| User       | Allowed Project | Permissions |
| ---------- | --------------- | ----------- |
| developer  | dev             | view, sync  |
| tester     | test            | view, sync  |
| devops     | prod            | view, sync  |
| all others | none            | read-only   |

---

# **8. Applying This Configuration**

Apply the entire structure using:

```
kubectl apply -f projects/default/remove-default-access.yaml
kubectl apply -f projects/dev/dev-project.yaml
kubectl apply -f projects/test/test-project.yaml
kubectl apply -f projects/prod/prod-project.yaml

kubectl apply -f applications/dev/springboot-dev.yaml
kubectl apply -f applications/test/springboot-test.yaml
kubectl apply -f applications/prod/springboot-prod.yaml

kubectl apply -f local-users/argocd-cm-users.yaml
kubectl apply -f rbac/argocd-rbac-config.yaml
```

Then run the password script:

```
./local-users/argocd-user-passwords.sh
```

---

# **9. Logging In to Argo CD**

Port-forward the server:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then open:

```
https://localhost:8080
```

Login using:

| User      | Password         |
| --------- | ---------------- |
| developer | dev123 (example) |
| tester    | test123          |
| devops    | devops123        |

Each user will see only the applications for their environment.

---

# **10. Purpose of This Demo**

This repository demonstrates:

* How to structure Argo CD Projects
* How to isolate environments
* How to apply least-privilege RBAC
* How to create multiple application sources (values + Helm)
* How to manage local users for training
* How to disable the default project correctly

This is a complete learning exercise for mastering Argo CD security concepts.

---

# **11. Notes**

* This is a **testing/demo setup**.
* Local users should NOT be used in production.
* Production systems should use SSO + group-based RBAC.
* Admin user should be disabled after bootstrap.

---

# **12. Next Steps**

If you want to extend this demo, consider:

* Adding SSO-based authentication
* Adding pipeline automation for CI/CD
* Adding environment promotion workflows
* Adding image automation (Image Updater)
* Adding Helmfile/Kustomize overlays

---


