
---

# Day-72: Canary Deployment Using `setWeight` (Argo Rollouts)

This repository demonstrates **Canary deployments using the `setWeight` strategy in Argo Rollouts**.
The goal is to explain the **concept clearly**, show **how it works step by step**, and help you understand **why this strategy is used in real production systems**.

---

## What Is a Canary Deployment? (Simple Explanation)

A **Canary deployment** is a way to release a new version of an application **gradually**, instead of exposing it to all users at once.

### Real-World Analogy

Think of a restaurant:

* You introduce a **new recipe**
* First, you serve it to **a few customers**
* You observe feedback
* If everything is good, you serve it to **more customers**
* Eventually, it replaces the old recipe

That is exactly what Canary deployment does — but with **users and application traffic**.

---

## Why `setWeight`?

In Argo Rollouts, `setWeight` controls **how much traffic** goes to the new version (Canary).

Instead of switching everything at once:

* You move traffic **step by step**
* You pause to observe behavior
* You promote only when you are confident

This makes deployments:

* Safer
* Observable
* Easy to roll back

---

## Core Concept: How `setWeight` Works

`setWeight` represents the **percentage of traffic** that should be routed to the Canary version.

Argo Rollouts achieves this by:

1. Calculating how many pods should run the new version
2. Scaling the Canary ReplicaSet accordingly
3. Letting the Service load-balance traffic evenly across pods

> Important:
> `setWeight` controls **traffic percentage**, not directly pod count — pod count is derived from the percentage.

---

## Understanding `steps` in Canary Strategy

The `steps` field defines **how traffic moves over time**.

Each step can contain:

* **`setWeight`** → move traffic to Canary
* **`pause`** → stop and wait (manual or timed)

This gives you full control over **when and how** traffic progresses.

---

## Step-by-Step Traffic Progression (5 Replicas)

Assume:

* Total replicas: **5**
* Initial state: all pods run **Version 1 (stable)**

---

### Step 1: `setWeight: 20`

* 20% traffic → Canary
* 20% of 5 replicas = **1 pod**

**Result:**

* Old ReplicaSet: 4 pods
* New ReplicaSet: 1 pod

Only a small portion of users see the new version.

---

### Step 2: `pause: {}`

* Rollout pauses **indefinitely**
* Nothing progresses until you decide

This allows:

* Manual testing
* Monitoring logs and metrics
* Verifying business KPIs

Promotion command:

```bash
kubectl argo rollouts promote rollouts-setweight
```

---

### Step 3: `setWeight: 40`

* 40% traffic → Canary
* 2 pods run the new version

**Result:**

* Old: 3 pods
* New: 2 pods

Confidence increases.

---

### Step 4: `pause: { duration: 10s }`

* Automatic pause
* Rollout resumes after 10 seconds

Timed pauses are useful for:

* Short observation windows
* Automated pipelines

---

### Step 5: `setWeight: 60`

* 60% traffic → Canary
* 3 pods run the new version

At this stage, most users are already on the new version.

---

### Step 6: `pause: { duration: 20s }`

Another observation window.

---

### Step 7: `setWeight: 80`

* 80% traffic → Canary
* 4 new pods, 1 old pod

Only a small fraction still uses the old version.

---

### Step 8: `pause: { duration: 1m }`

Final safety pause before full rollout.

---

### Final Promotion

After the final pause:

* 100% traffic → Canary
* New ReplicaSet: 5 pods
* Old ReplicaSet: 0 pods (terminated)

The rollout is complete.

---

## Rounding Behavior in `setWeight`

Argo Rollouts **always rounds up** when calculating pod counts.

### Examples

| Replicas | setWeight | Canary Pods |
| -------- | --------- | ----------- |
| 10       | 10%       | 1           |
| 10       | 15%       | 2           |
| 5        | 20%       | 1           |

Why?

* To avoid under-routing traffic
* To ensure Canary always receives at least the requested percentage

This is a **safety feature**, not a limitation.

---

## YAML (Production-Ready Example)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollouts-setweight
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: { duration: 10s }
      - setWeight: 60
      - pause: { duration: 20s }
      - setWeight: 80
      - pause: { duration: 1m }
  selector:
    matchLabels:
      app: rollouts-setweight
  template:
    metadata:
      labels:
        app: rollouts-setweight
    spec:
      containers:
      - name: rollouts-setweight
        image: canary
        env:
        - name: HTML_NAME
          value: "app-v1.html"
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: rollouts-setweight
spec:
  selector:
    app: rollouts-setweight
  ports:
  - port: 5000
    targetPort: 5000
```

---

## Key Takeaways

* `setWeight` enables **gradual, controlled traffic shifting**
* `pause` allows **manual or timed validation**
* Pod counts are derived from traffic percentages
* Rounding ensures Canary traffic is never under-represented
* This strategy is ideal for **production-grade deployments**

---

## When to Use `setWeight`

Use this approach when:

* You want **high confidence** deployments
* You need **human checkpoints**
* You care about **real user impact**
* Rollbacks must be **fast and safe**

---

## Final Thought

> Canary with `setWeight` is not about speed — it’s about **confidence**.
> You trade a little time for a lot of safety, and in production systems, that trade is almost always worth it.
---