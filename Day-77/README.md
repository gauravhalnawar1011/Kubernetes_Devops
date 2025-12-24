
---

# Common GitHub Actions Workflows

This repository documents common workflow patterns implemented using **GitHub Actions**.
Each section explains the **baseline workflow**, followed by **practical enhancements** that improve performance, reliability, and developer experience.

The goal is not only to automate tasks, but to build **maintainable, scalable, and production-ready CI/CD pipelines**.

---

## Linting and Static Analysis

Linting and static analysis workflows validate code quality and enforce standards early in the development lifecycle.

### Minimal Workflow

A basic linting workflow typically includes:

1. Checking out the repository code.
2. Installing the linting tool (or using a prebuilt container image).
3. Running the linter across the codebase.

### Recommended Enhancements

To improve efficiency and usability:

* Detect changed files and lint only the affected portions of the codebase.
* Cache tool binaries or dependencies to reduce execution time.
* Publish results directly in the GitHub UI using:

  * Job summaries
  * Pull request annotations
  * Status checks

Many Marketplace actions encapsulate this logic. For example, GitHub’s Super Linter aggregates multiple linters and automatically scopes execution to modified files.

The same structure applies to other static analysis tools: checkout → install → run → optimize.

---

## Testing Applications

Testing workflows validate application behavior and prevent regressions.

### Baseline Testing Pipeline

A standard testing workflow includes:

1. Checking out the source code.
2. Installing the language runtime and package manager.
3. Restoring dependencies.
4. Executing the test suite.

### Production Improvements

Well-designed pipelines also include:

* Dependency caching to reduce setup time.
* Uploading test reports for post-run inspection.
* Publishing code coverage metrics for visibility and trend analysis.

Actions such as runtime setup tools simplify environment configuration and often include built-in caching support.

---

## Building Artifacts

Build workflows extend testing pipelines by producing deployable outputs.

### Typical Build Flow

After validation steps:

1. Execute the build process.
2. Package the output.
3. Publish artifacts to:

   * Artifact storage
   * Package registries
   * Release assets

### Advanced Build Practices

In mature pipelines, builds may also:

* Generate SBOMs (Software Bill of Materials).
* Produce provenance or attestation metadata.
* Perform security or vulnerability scans.

#### Container Image Builds

For containerized applications:

* Replace language tooling with container builders such as Docker or BuildKit.
* Build the image.
* Push it to a container registry.
* Optionally sign the image using tools like Cosign.

---

## Deploying Applications

Deployment workflows promote validated artifacts into target environments.

### Push-Based Deployments

In push-based delivery, the workflow directly executes deployment tooling.

Typical steps include:

1. Checking out deployment manifests or infrastructure code.
2. Installing required CLIs (for example: Kubernetes, Helm, or infrastructure tooling).
3. Authenticating to the target platform using secure mechanisms such as OIDC.
4. Applying changes.
5. Verifying deployment health.

This approach provides immediate feedback and is common for controlled environments.

---

### GitOps Deployments

GitOps separates deployment execution from CI pipelines.

In this model:

1. The workflow updates configuration stored in Git (Helm values, Kustomize overlays, etc.).
2. Changes are committed and pushed.
3. A controller running in the environment detects and reconciles the desired state.

This approach improves auditability, rollback safety, and environment consistency.

---

## Repository Maintenance Automation

GitHub Actions can also automate repository hygiene and governance tasks.

---

## Release Management

Automated release workflows analyze commit history, apply semantic versioning rules, update changelogs, and create tagged releases.

This ensures consistent versioning and reduces manual release overhead.

---

## Managing Stale Issues and Pull Requests

Scheduled workflows can:

* Label inactive issues.
* Post reminder comments.
* Close abandoned pull requests.

This keeps backlogs clean and reduces operational noise with minimal configuration.

---

## Dependency Updates

Automated dependency management tools periodically scan manifest files for outdated packages and raise pull requests.

These PRs rely on existing test workflows to validate updates before merge.
For unsupported ecosystems, custom workflows can replicate this behavior by querying versions, updating manifests, and opening pull requests programmatically.

---

## GitHub-Provided Workflow Templates

For new repositories or unfamiliar stacks, GitHub provides curated workflow templates accessible via:

**Actions → New Workflow**

These templates are generated based on detected languages and frameworks and offer a minimal, functional starting point.

They should be treated as a foundation—iterate by improving authentication practices, adding caching, enforcing organizational standards, and integrating security controls.

---

## Summary

These workflows represent **real-world CI/CD patterns**, not toy examples.

They emphasize:

* Incremental optimization
* Secure authentication
* Maintainability
* Developer feedback loops
* Production readiness

Use them as building blocks, adapt them to your environment, and evolve them as your delivery requirements grow.

---