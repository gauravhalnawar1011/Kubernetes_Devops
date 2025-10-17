
#  Day 12 — Kubernetes DaemonSet, Job & CronJob

## 📘 Overview
On **Day 12**, we explored three key Kubernetes workload types beyond standard Deployments and ReplicaSets:  
- **DaemonSets**  
- **Jobs**  
- **CronJobs**  

Each of these serves specific use cases in managing pods and workloads across a cluster.

---

## ⚙️ DaemonSet

### 🧩 What is a DaemonSet?
A **DaemonSet** ensures that **a copy of a specific pod runs on all (or selected) nodes** in the cluster.  
When a new node is added, Kubernetes automatically schedules the DaemonSet pod on it.  
When a node is removed, the pod on that node is automatically deleted.

### ✳️ Key Characteristics
- One pod replica runs **per node**.  
- Automatically adapts to **node additions/removals**.  
- Commonly used for **infrastructure-level services** (monitoring, logging, networking).  
- Controller continuously ensures desired state — if a pod is deleted, it is recreated automatically.

### 🔍 Use Cases
- Monitoring agents (e.g., Prometheus Node Exporter)
- Logging agents (e.g., Fluentd, ELK, Splunk)
- Networking plugins (e.g., Calico, Flannel, Weave Net)
- System components (e.g., `kube-proxy`)

### 🧠 Example DaemonSet Manifest
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  labels:
    app: node-monitor
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      containers:
      - name: monitor-agent
        image: busybox:1.28
        command: ['sh', '-c', 'echo Monitoring node... && sleep 3600']

### 🧾 Useful Commands

```bash
# List all pods
kubectl get pods

# List all pods across namespaces
kubectl get pods -A

# List all DaemonSets
kubectl get ds
kubectl get daemonset

# Delete a pod (it will automatically recreate)
kubectl delete pod <pod-name>
```

---

## ⏱️ Job

### 🧩 What is a Job?

A **Job** creates **one or more pods** that run **to completion**.
Once the task (like a script or a computation) finishes successfully, the Job exits.

### 🔍 Use Cases

* Database initialization scripts
* One-time tasks or maintenance jobs
* Running automation/setup routines during deployments

### 🧠 Example Job Manifest

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-init-job
spec:
  template:
    spec:
      containers:
      - name: init-db
        image: busybox:1.28
        command: ['sh', '-c', 'echo Initializing database... && sleep 10']
      restartPolicy: OnFailure
```

---

## ⏰ CronJob

### 🧩 What is a CronJob?

A **CronJob** schedules and runs **Jobs at specific times or intervals**, just like the `cron` utility in Linux.

### 🧮 Cron Syntax

| Field        | Description | Allowed Values   |
| ------------ | ----------- | ---------------- |
| Minute       | `*`         | 0–59             |
| Hour         | `*`         | 0–23             |
| Day of Month | `*`         | 1–31             |
| Month        | `*`         | 1–12             |
| Day of Week  | `*`         | 0–6 (0 = Sunday) |

### 🕒 Examples

| Schedule      | Meaning                    |
| ------------- | -------------------------- |
| `* * * * *`   | Every minute               |
| `*/3 * * * *` | Every 3 minutes            |
| `45 23 * * 6` | Every Saturday at 11:45 PM |
| `0 0 * * *`   | Every day at midnight      |

### 🧠 Example CronJob Manifest

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: weekly-report
spec:
  schedule: "45 23 * * 6"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report-generator
            image: busybox:1.28
            command: ['sh', '-c', 'echo Generating weekly report... && sleep 10']
          restartPolicy: OnFailure
```

### 🔍 Use Cases

* Scheduled report generation
* Automated cleanup jobs
* Regular data backups
* Scheduled testing or build pipelines

---

## 🧾 Common Commands

```bash
# List all Jobs
kubectl get jobs

# List all CronJobs
kubectl get cronjobs

# Check job pods
kubectl get pods --watch

# Describe a specific job
kubectl describe job <job-name>

# Delete a Job or CronJob
kubectl delete job <job-name>
kubectl delete cronjob <cronjob-name>
```

---

## 🧩 Summary

| Component     | Purpose                       | Runs On             | Lifecycle  |
| ------------- | ----------------------------- | ------------------- | ---------- |
| **DaemonSet** | Run a pod on every node       | All nodes           | Continuous |
| **Job**       | Run a task once to completion | Specific node(s)    | One-time   |
| **CronJob**   | Run tasks periodically        | Scheduled intervals | Recurring  |

---

## 🏁 Key Takeaways

* **DaemonSets** ensure one pod per node — ideal for system-level services.
* **Jobs** handle one-off workloads that must complete successfully.
* **CronJobs** automate recurring tasks on defined schedules.
* Kubernetes controllers ensure reliability, automation, and self-healing across all workloads.

---

🏷️ **#Kubernetes #DevOps #Containers #CronJob #DaemonSet #Automation**

