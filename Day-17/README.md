
---

# 🚀 Day 17 – Kubernetes Autoscaling: HPA vs VPA (and Beyond)

## 🧠 What Is Scaling?

Scaling means adjusting your application's computing resources **on demand**, either **manually** or **automatically**.

When we deploy an application on Kubernetes, we often specify **replicas** in a Deployment.
Each replica is an identical copy of a Pod, serving traffic together to balance workload and improve availability.

Scaling ensures your application can handle user traffic efficiently by increasing or decreasing resources when needed.

However, **manual scaling** is not practical for large-scale systems — imagine managing thousands of nodes or pods manually!
That’s where **autoscaling** comes in. It automates scaling based on real-time metrics like **CPU**, **memory**, or **custom events**.

---

## ⚙️ Types of Autoscaling in Kubernetes

There are three main types of autoscaling:

| Type                                | Scales                 | Managed By                     | Example                                   |
| ----------------------------------- | ---------------------- | ------------------------------ | ----------------------------------------- |
| **Horizontal Pod Autoscaler (HPA)** | Pods (Workload)        | Kubernetes                     | Scale pods based on CPU/Memory usage      |
| **Vertical Pod Autoscaler (VPA)**   | Pod Resources          | Separate Project (open-source) | Adjusts pod CPU/Memory limits dynamically |
| **Cluster Autoscaler (CA)**         | Nodes (Infrastructure) | Cloud Provider                 | Adds or removes nodes in the cluster      |

Additionally, **KEDA** provides **event-driven** autoscaling, and **Cron-based** scaling can handle scheduled workloads.

---

## 🧩 Horizontal Pod Autoscaler (HPA)

HPA automatically increases or decreases the number of pod replicas in a deployment based on CPU or memory utilization.

For example:

* If your CPU usage exceeds **70%**, HPA creates additional pods.
* If traffic decreases, it scales down automatically.

### ✅ Prerequisites

* A running **Metrics Server** in your cluster

  ```bash
  kubectl get deployment metrics-server -n kube-system
  ```

---

### 🧱 Example: HPA with Deployment and Service

#### Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 1
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
```

---

### Create the HPA

```bash
kubectl autoscale deploy php-apache --cpu-percent=50 --min=1 --max=4
```

### Generate Load on the Pods

```bash
kubectl run -i --tty load-generator --rm \
  --image=busybox:1.28 --restart=Never \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

### Check HPA and Pods

```bash
kubectl get hpa
kubectl get pods
```

---

## 📈 Vertical Pod Autoscaler (VPA)

VPA adjusts the **resources (CPU/memory)** allocated to existing pods instead of adding replicas.
This approach is suitable when:

* Your application can tolerate **downtime** (since pods are restarted).
* You have a **non-seasonal**, **stateless** workload.

🧩 Example: Increasing CPU/memory limits dynamically for a single pod.

> VPA is a **separate open-source project**, not included by default in Kubernetes.
> It can be installed from the official [VPA GitHub repository](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler).

---

## ☁️ Cluster Autoscaler

When your pods require more resources than the current nodes can provide, **Cluster Autoscaler** adds more **nodes (VMs)** automatically.

* Managed by your **cloud provider** (e.g., GKE, AKS, EKS).
* Scales down unused nodes when traffic decreases.

---

## ⚡ KEDA – Event-Driven Autoscaling

[KEDA (Kubernetes Event-Driven Autoscaling)](https://keda.sh/docs/2.18/scalers/) is a CNCF project that enables autoscaling based on **external event sources**, such as:

* **RabbitMQ**, **Kafka**, **AWS SQS**
* **Azure Service Bus**, **Google Pub/Sub**
* **MySQL**, **MongoDB**, **HTTP requests**, **Prometheus metrics**, and more.

### 🔄 Example Use Case

If you have a microservice consuming messages from a **RabbitMQ queue**, KEDA can:

* Scale **up** when the message queue grows.
* Scale **down to zero** when there are no messages — saving resources.

This makes it ideal for **event-driven microservice architectures**.

---

## 🕒 Cron or Schedule-Based Autoscaling

You can also schedule scaling events (e.g., scale up during business hours, scale down at night) using **KEDA Cron triggers** or Kubernetes Jobs/CronJobs.

---

## 🧭 Summary

| Autoscaler             | Scope         | Key Metric       | Included by Default | Use Case                               |
| ---------------------- | ------------- | ---------------- | ------------------- | -------------------------------------- |
| **HPA**                | Pods          | CPU / Memory     | ✅ Yes               | Scale pods automatically based on load |
| **VPA**                | Pod Resources | CPU / Memory     | ❌ No                | Resize pod resources dynamically       |
| **Cluster Autoscaler** | Nodes         | Node utilization | ⚙️ Cloud Provider   | Add/remove cluster nodes               |
| **KEDA**               | Events        | Queue/DB/Event   | ❌ No                | Event-driven or Cron-based scaling     |

---

### 🔗 Learn More

* [Kubernetes Autoscaling Concepts](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
* [KEDA Official Docs](https://keda.sh/docs/)
* [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
* [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

---

## 💡 Tip

You can define multiple resources in a single YAML file by separating them with `---`, for example:

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
...
---
# Service
apiVersion: v1
kind: Service
...
---
# HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
...
```
---

