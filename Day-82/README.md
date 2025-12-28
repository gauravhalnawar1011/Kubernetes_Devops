
---

# Docker Image Build & Publish — GitHub Actions

This repository includes a GitHub Actions workflow that builds and publishes Docker images for both backend and frontend services to **Docker Hub** using a **manual trigger** (`workflow_dispatch`).

The workflow is intentionally simple, explicit, and reliable, making it suitable for controlled releases and demonstrations.

---

## 📦 What This Workflow Does

When manually triggered, the workflow performs the following steps:

1. Checks out the repository source code
2. Builds Docker images for:

   * Backend service (`Day-82/api`)
   * Frontend service (`Day-82/front-end-nextjs`)
3. Authenticates with Docker Hub using GitHub Secrets
4. Pushes both images to Docker Hub with the `latest` tag

---

## 🗂 Repository Structure (Relevant Parts)

```text
Day-82/
├── api/
│   ├── Dockerfile
│   └── application source
├── front-end-nextjs/
│   ├── Dockerfile
│   └── Next.js application
└── .github/
    └── workflows/
        └── dockerhub.yaml
```

Each service maintains its own `Dockerfile`, allowing independent builds and future scalability.

---

## 🚀 Workflow Trigger

This workflow uses **manual execution only**:

```yaml
on:
  workflow_dispatch:
```

### Why `workflow_dispatch`?

* Prevents accidental image pushes
* Allows controlled execution
* Ideal for learning, demos, and controlled releases
* Easy to debug and reason about

To run the workflow:

1. Go to **Actions** tab in GitHub
2. Select **Build and Publish image Docker Hub**
3. Click **Run workflow**

---

## 🔐 Required GitHub Secrets

The workflow depends on the following repository secrets:

| Secret Name           | Description                 |
| --------------------- | --------------------------- |
| `DOCKER_HUB_USERNAME` | Docker Hub account username |
| `DOCKER_HUB_TOKEN`    | Docker Hub access token     |

📍 Configure these under:
**Repository → Settings → Secrets and variables → Actions**

---

## 🐳 Docker Images Produced

On successful execution, the following images are published:

* **Backend**

  ```
  <DOCKER_HUB_USERNAME>/devops-qr-code-backend:latest
  ```

* **Frontend**

  ```
  <DOCKER_HUB_USERNAME>/devops-qr-code-frontend:latest
  ```

> Note: The `latest` tag is used intentionally for simplicity.
> In production environments, immutable tags (e.g., Git SHA or version numbers) are recommended.

---

## 🛠 Workflow Implementation (Summary)

Key implementation characteristics:

* Uses official GitHub Actions
* Secrets-based authentication (no hardcoded credentials)
* Clear separation between build and push steps
* Explicit Docker build contexts
* Compatible with multi-service repositories

---

## ⚠️ Notes & Limitations

This workflow is intentionally minimal and **does not include**:

* Automated triggers (`push`, `pull_request`)
* Test execution before image build
* Image vulnerability scanning
* Image signing or provenance
* Kubernetes or environment deployments

These can be added incrementally as the project matures.

---

## 📈 Future Improvements (Optional)

Possible next steps for a production-grade pipeline:

* Replace `latest` with immutable image tags
* Add CI validation (tests, linting)
* Enable Docker BuildKit caching
* Integrate vulnerability scanning (e.g., Trivy)
* Separate build and deployment workflows

---

## ✅ Status

✔ Workflow tested
✔ Images successfully pushed to Docker Hub
✔ Secrets handled securely
✔ Manual execution verified

---

