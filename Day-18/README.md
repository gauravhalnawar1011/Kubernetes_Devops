
-----

# Kubernetes Health Probes: Liveness, Readiness, and Startup

This document provides a clear and practical guide to understanding and implementing health probes in Kubernetes. Probes are essential for building robust, self-healing applications.

## What is a Probe?

In Kubernetes, a **probe** is a periodic diagnostic check performed by the `kubelet` (the agent running on each node) to assess the health of a container.

Think of it as an automated health check-in. The `kubelet` regularly "asks" your container, "Are you healthy?" How the container answers (or *if* it answers) determines what action Kubernetes takes.

The primary goal of probes is to ensure application reliability and self-healing. They help Kubernetes automatically detect and recover from failures, preventing failed applications from serving traffic and ensuring users have a stable experience.

-----

## The Three Types of Probes

Kubernetes provides three distinct types of probes. Using them correctly is critical for application stability.

### 1\. Liveness Probe: "Is my application *running*?"

  * **Purpose:** To check if your container is still running and responsive. This probe is used to detect containers that are in a "stuck" or "deadlocked" state, where the process is technically running but can no longer make progress.
  * **Action on Failure:** If the liveness probe fails, the `kubelet` **restarts the container**.
  * **When to Use (Real-world Example):**
      * Imagine a web application that gets stuck in an infinite loop due to a bug. The server process is still running, so Kubernetes thinks everything is fine. However, it's not responding to any requests.
      * A liveness probe (e.g., hitting a `/healthz` endpoint) would fail, signaling to Kubernetes that the container is unhealthy. Kubernetes then restarts it, automatically recovering the application from the deadlock.

### 2\. Readiness Probe: "Is my application *ready to serve traffic*?"

  * **Purpose:** To check if your container is ready to accept and handle user requests. An application might be *running* (liveness probe passes) but not yet *ready* (e.g., it's still warming up a cache, loading data, or connecting to a database).
  * **Action on Failure:** If the readiness probe fails, Kubernetes **does not restart the container**. Instead, it removes the Pod's IP address from the list of endpoints for all matching Services. This effectively and temporarily takes the Pod out of the load-balancing pool.
  * **When to Use (Real-world Example):**
      * You have a microservice that takes 30 seconds to start because it needs to load a large dataset into memory.
      * Without a readiness probe, as soon as the container starts, the Service would send traffic to it. Users would receive `503 Service Unavailable` errors for 30 seconds.
      * By adding a readiness probe, Kubernetes will wait until the probe passes (meaning the data is loaded) before allowing the Service to send traffic to that Pod.

### 3\. Startup Probe: "Is my application *still starting*?"

  * **Purpose:** To protect slow-starting containers. Some legacy or complex applications (e.g., large Java applications) may take several minutes to boot.
  * **Action on Failure:** If configured, the startup probe **disables the liveness and readiness probes** until it succeeds. If the startup probe *itself* fails, the `kubelet` **restarts the container** (just like a liveness probe).
  * **When to Use (Real-world Example):**
      * Your application takes 2 minutes (120 seconds) to start.
      * You set a `livenessProbe` to check every 10 seconds after an `initialDelaySeconds` of 30.
      * The liveness probe would start checking at 30s, fail, and (after its `failureThreshold`) restart the container *before it ever finished starting*. This would cause an endless restart loop.
      * By adding a `startupProbe` with a large `failureThreshold` (e.g., 30 failures with a 10s period = 300s total), you tell Kubernetes: "Be patient for up to 5 minutes. Only *after* this probe passes should you start the liveness and readiness checks."

**The Probe Lifecycle:** `Startup Probe` (if present) runs first $\rightarrow$ Once it succeeds, `Liveness Probe` and `Readiness Probe` take over.

-----

## How to Perform a Check (Probe Mechanisms)

You can configure each probe to use one of three methods:

1.  **`httpGet` (HTTP Check):**

      * **What it does:** Sends an HTTP GET request to a specific port and path (e.g., `/api/health`).
      * **Success:** The probe succeeds if it receives an HTTP status code between 200 and 399.
      * **Use Case:** Ideal for web servers and APIs.

2.  **`tcpSocket` (TCP Check):**

      * **What it does:** Attempts to open a TCP connection to a specific port.
      * **Success:** The probe succeeds if the connection is established.
      * **Use Case:** Good for non-HTTP services, like a database (e.g., checking if the PostgreSQL port `5432` is open) or a gRPC service.

3.  **`exec` (Command Check):**

      * **What it does:** Executes a command inside the container.
      * **Success:** The probe succeeds if the command exits with a status code of **0**.
      * **Use Case:** A flexible "catch-all." You can run a script or a command-line tool to check for a specific file, query a local service, or perform any custom logic.

-----

## Example in Practice: A Liveness Probe with `exec`

Let's analyze the provided `liveness-exec` Pod definition.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox:1.27.2
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

### What's Happening in This Example?

This manifest is designed to demonstrate a liveness probe failure and recovery.

1.  **Container Start:** The container starts and immediately runs its command:

    1.  `touch /tmp/healthy`: Creates an empty file named `healthy` in the `/tmp` directory.
    2.  `sleep 30`: Pauses for 30 seconds.
    3.  `rm -f /tmp/healthy`: Deletes the `healthy` file.
    4.  `sleep 600`: Sleeps for 10 minutes (to keep the container running).

2.  **Liveness Probe Start:** The `livenessProbe` is configured to:

      * Wait for `initialDelaySeconds: 5` (5 seconds) before its first check.
      * Run the command `cat /tmp/healthy` every `periodSeconds: 5` (5 seconds).

3.  **The "Healthy" Period (Seconds 5-30):**

      * At 5s, the first probe runs `cat /tmp/healthy`. The file exists, so the command exits with code 0 (Success).
      * At 10s, 15s, 20s, and 25s, the probe runs again, and the file still exists. The container is considered "healthy."

4.  **The "Failure" Period (Second 30+):**

      * At 30s, the container's main command executes `rm -f /tmp/healthy`, deleting the file.
      * At 30s (or the next 5s interval, 35s), the probe runs `cat /tmp/healthy`. The file no longer exists, so `cat` exits with code 1 (Failure).
      * The probe fails again at 35s, 40s, etc.

5.  **The Recovery:**

      * By default, the `failureThreshold` is **3**.
      * After the probe fails 3 times in a row (which takes \~15 seconds), Kubernetes determines the container is unhealthy.
      * **Action:** Kubernetes terminates and **restarts** the container.
      * The entire cycle then begins again. If you run `kubectl get pods --watch`, you will see the `RESTARTS` count for this Pod increment every 45-50 seconds.

-----

## A Note on Node Health vs. Container Health (Tolerations)

You may notice that running `kubectl describe pod <pod-name>` shows `tolerations` that you did not define:

```yaml
tolerations:
 - effect: NoExecute
   key: node.kubernetes.io/not-ready
   operator: Exists
   tolerationSeconds: 300
 - effect: NoExecute
   key: node.kubernetes.io/unreachable
   operator: Exists
   tolerationSeconds: 300
```

This is an important high-availability feature of Kubernetes that is separate from, but related to, health.

  * **Probes** check the health of your *container*.
  * **Tolerations** handle the health of the *node* (the VM) your container is running on.

Kubernetes automatically adds these tolerations to your Pod. They mean:

  * If the node this Pod is on becomes `NotReady` or `Unreachable` (e.g., the `kubelet` stops reporting), the Pod will "tolerate" this bad state for `300` seconds (5 minutes).
  * If the node does not recover within 5 minutes, the control plane **evicts** the Pod. This means the Pod is deleted from the unhealthy node and rescheduled onto a new, healthy node.

This ensures that your application recovers not only from *application-level failures* (via probes) but also from *infrastructure-level failures* (via tolerations and evictions).