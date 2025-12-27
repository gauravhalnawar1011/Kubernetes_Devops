
---

# Day 80 — Debugging & Observability in GitHub Actions

Reliable CI/CD pipelines are not defined by how often they pass, but by how quickly and confidently failures can be diagnosed.

This repository focuses on **practical debugging and observability techniques in GitHub Actions**, with an emphasis on repeatability, signal clarity, and production discipline.

---

## Why Debugging Matters in CI/CD

Most GitHub Actions workflows fail for predictable reasons:
- Incorrect assumptions about inputs
- Hidden environment differences
- Poor observability by design

Scrolling logs blindly is not debugging.  
Professional teams rely on **systematic fault isolation**.

GitHub Actions provides built-in mechanisms to surface deeper execution details—when used intentionally.

---

## Debug Channels in GitHub Actions

GitHub exposes internal debug channels that are disabled by default.

### Step-Level Debug Logging

Enable via repository variable or secret:

```

ACTIONS_STEP_DEBUG=true

```

Use this when:
- Debugging workflow logic
- Verifying conditionals and expressions
- Inspecting action-level behavior

---

### Runner-Level Debug Logging

Enable via repository variable or secret:

```

ACTIONS_RUNNER_DEBUG=true

```

Use this when:
- Tool installation behaves inconsistently
- Containers or services fail to start
- Filesystem, PATH, or permission issues appear

**Important:**  
Enable debug flags temporarily. Disable them immediately after resolution to avoid noise and information overload.

---

## Example: Structured Logging in a Workflow

GitHub Actions supports log commands that make intent explicit.

| Command       | Visibility                           |
|--------------|--------------------------------------|
| `::debug::`  | Visible only with debug enabled      |
| `::notice::`| Informational                        |
| `::warning::`| Non-blocking issues                 |
| `::error::` | Fails the step                       |

A sample workflow demonstrating these log levels is included in this repository.

---

## Debugging Without SSH Access

SSH-based debugging should **not** be your default approach.

Instead, prefer:
- Elevated logging
- Log grouping (`::group::`)
- Artifact uploads (logs, configs, reports)
- Deterministic local reproduction

If SSH is required frequently, it indicates missing observability or poor pipeline design.

---

## Team Habits That Improve Developer Experience

High-performing DevOps and SRE teams treat CI as a first-class development environment.

Recommended practices:
- Maintain a Taskfile / Makefile that mirrors CI commands
- Document required environment variables in `.env.example`
- Reuse the same scripts locally and in CI
- Capture debugging learnings in PRs or commit history

This reduces onboarding time and accelerates incident resolution.

---

## Production Debugging Checklist — GitHub Actions (SRE Standard)

Good. Then I’m not going to sugarcoat this.

What most people call “debugging CI/CD” is random log scrolling and guesswork.  
What SRE teams do is **systematic fault isolation**. The difference is process.

Below is a **production-grade GitHub Actions debugging checklist** that SRE / Platform teams actually use. You can adopt this as-is.

---

### 0. First Principle

**Never debug blindly.**

Before touching the workflow, answer one question:

> What changed between the last successful run and the failing run?

If you cannot answer this, stop and gather context.

---

### 1. Classify the Failure

Do not jump into fixes.

**Deterministic**
- Fails every time
- Same step, same error

**Intermittent / Flaky**
- Passes sometimes
- Timing, networking, caching, concurrency

**Environment-Specific**
- OS version differences
- Hosted vs self-hosted runners
- Fork vs main repository

Your debugging strategy depends entirely on this classification.

---

### 2. Turn On Observability (Temporarily)

Enable only what you need:
- `ACTIONS_STEP_DEBUG=true`
- `ACTIONS_RUNNER_DEBUG=true`

If debug logs do not provide new information within 1–2 runs, disable them.

---

### 3. Verify Inputs Explicitly

Most CI bugs are incorrect assumptions.

Check:
- Workflow inputs
- Environment variables
- Secret presence (never values)

> A majority of CI failures originate here.

---

### 4. Eliminate False Positives

Before changing code:
- Re-run the job
- Check for transient failures
- Validate external dependencies

If a re-run succeeds without changes, you are dealing with flakiness.

---

### 5. Isolate the Failing Step

Reduce the failure surface:
- Comment out unrelated steps
- Split large scripts
- Add explicit precondition checks

Your goal is isolation, not speed.

---

### 6. Capture Artifacts

Persist data instead of guessing:
- Generated configs
- Rendered templates
- Tool logs
- Test reports

Artifacts enable post-mortem analysis without reruns.

---

### 7. Reproduce Locally

If the issue cannot be reproduced locally:
- CI logic is too coupled
- Environment assumptions are undocumented

This is a design problem, not a tooling issue.

---

### 8. Avoid SSH Debugging by Default

SSH is a last resort.

If you need it frequently, your workflows lack:
- Determinism
- Observability
- Proper diagnostics

---

### 9. Fix Root Causes

Bad fixes:
- Blind retries
- Arbitrary sleeps
- Masked errors

Good fixes:
- Explicit readiness checks
- Idempotent operations
- Clear failure messages

If you cannot explain the fix in one sentence, it is probably wrong.

---

### 10. Close the Loop

After resolution:
- Remove debug flags
- Clean up temporary logs
- Document the failure and detection improvements

This is how teams improve over time.

---

## Final Reality Check

If you cannot:
- Explain CI failures clearly
- Predict recurrence
- Debug without guesswork

Then you are using GitHub Actions, not engineering pipelines.

---

## Repository Structure

```

.github/workflows/
└── debug-env-vars.yaml

```

---

## Key Takeaway

Observability is not an add-on.  
It is a design requirement.

Well-designed pipelines explain themselves.

---
