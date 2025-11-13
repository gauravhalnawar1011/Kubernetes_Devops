
---

# Day-36 — Kubernetes Logging and Monitoring

## 📘 Overview

This repository focuses on **Kubernetes Logging and Monitoring**, with a particular emphasis on the **Metrics Server**—a CNCF project that provides resource utilization metrics (CPU, memory, etc.) for pods and nodes in a Kubernetes cluster.

The **Metrics Server** is a core component that powers features like **Horizontal Pod Autoscaling (HPA)**, `kubectl top` commands, and other tools that consume cluster performance data.

---

## 🔧 Installation

### Option 1: Using `kubectl apply`

You can deploy the Metrics Server by applying its latest manifest file:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Option 2: Using Helm

Alternatively, the Metrics Server can be installed via [Helm Charts](https://artifacthub.io/packages/helm/metrics-server/metrics-server) for easier management and versioning.

---

## 📦 Verification

After installation, verify that the Metrics Server pod is running in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system
```

You should see a pod named similar to:

```
metrics-server-xxxxxxxxxx-yyyyy
```

---

## 🧩 How It Works

The **Metrics Server** collects metrics from **Kubelet** running on each node.
Here’s a simplified flow of how data moves through the system:

1. **Kubelet** runs on every node and manages containers on that node.
2. **cAdvisor**, a daemon integrated with Kubelet, collects container-level metrics (CPU, memory, etc.) from the container runtime.
3. **Kubelet** aggregates these metrics and exposes them via the Kubernetes API.
4. The **Metrics Server** scrapes these metrics from each Kubelet.
5. It then exposes this data through the **Metrics API**, which the **API Server** consumes.
6. Commands like `kubectl top nodes` and `kubectl top pods` use this API to display resource utilization.

---

## ⚙️ Troubleshooting TLS Certificate Errors

If you encounter certificate-related errors, such as:

```
x509: certificate signed by unknown authority
```

You can edit the Metrics Server deployment and allow insecure TLS connections to Kubelets (for testing purposes only):

```bash
kubectl edit deployment metrics-server -n kube-system
```

Under the container `args:` section, add the following line:

```yaml
--kubelet-insecure-tls
```

> ⚠️ **Note:** This bypasses certificate verification and should not be used in production environments.

---

## 🪵 Logging and Monitoring Beyond Metrics Server

Kubernetes’ native monitoring and logging capabilities are limited.
For advanced observability (log aggregation, alerting, and dashboards), logs should be exported to external systems such as:

* **ELK / OpenSearch** (Elasticsearch, Logstash, Kibana)
* **Splunk**
* **Prometheus + Grafana**
* **Fluentd / Fluent Bit** for log forwarding

These tools help create metrics-based alerts, dashboards, and log-based monitoring.

---

## 🧠 Understanding Container Runtimes and `crictl`

From **Kubernetes v1.24** onward, **Docker** is no longer the default container runtime.
Most clusters now use **containerd** or **CRI-O** as the runtime.

To interact with containers, Kubernetes provides a runtime client called **`crictl`**.

### Examples

* **List running containers:**

  ```bash
  crictl ps
  ```

* **View container logs:**

  ```bash
  crictl logs <container-id>
  ```

* **Pull an image manually:**

  ```bash
  crictl pull nginx
  ```

* **Run a container using JSON config:**

  ```bash
  crictl run pod-config.json
  ```

`crictl` serves a similar purpose as `docker` commands but is runtime-agnostic and integrated directly with Kubernetes CRI.

---

## 🩺 Troubleshooting Clusters When `kubectl` Fails

Sometimes, if the **API Server** becomes unresponsive, `kubectl` commands won’t work (e.g., connection refused on port `6443`).

In such cases, you can use `crictl` to troubleshoot at the node level:

1. Check if the API server container is running:

   ```bash
   crictl ps
   ```
2. Inspect logs:

   ```bash
   crictl logs <api-server-container-id>
   ```
3. Manually pull or run test containers if necessary:

   ```bash
   crictl pull <image>
   ```

For more details, refer to the official documentation:
🔗 [Debugging Kubernetes clusters with crictl](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)

---

## 📚 References

* [Kubernetes Metrics Server GitHub Repository](https://github.com/kubernetes-sigs/metrics-server)
* [Kubernetes Documentation: crictl](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)
* [Helm Chart for Metrics Server](https://artifacthub.io/packages/helm/metrics-server/metrics-server)

---

## 🧩 Summary

This project demonstrates:

* Installing and configuring the **Metrics Server**.
* Understanding how metrics flow within a Kubernetes cluster.
* Using **crictl** for debugging in runtime-based environments.
* Extending observability with external monitoring and logging tools.

---

**Author:** *[Your Name]*
**Day 36 – Kubernetes Logging and Monitoring Series*

---



