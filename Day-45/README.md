
---

# 🏗️ Kubernetes StatefulSet vs Deployment — MongoDB Stateful Application Demo

A hands-on guide to understanding **why and when we use StatefulSets** in Kubernetes, with a fully working MongoDB example using **headless services**, **persistent storage**, **PVC/PV mapping**, and **order-based pod identity**.

This repository covers:

* Difference between **Deployments** and **StatefulSets**
* Why stateful workloads require stable identities
* Real-world use cases for StatefulSets
* A complete MongoDB StatefulSet setup
* Manual PV provisioning for local clusters
* Testing data persistence across pod restarts
* Clean-up steps

---

## 🧠 Why Not Just Use a Deployment?

A **Deployment** is perfect for **stateless applications**:

* Pods are created with *random* names (e.g., `app-7c9dbd8f6f-m74pf`)
* Pod identity does *not* matter
* Pods can be freely rescheduled without concern
* Storage, if used, is temporary unless explicitly externalized

Typical Deployment use cases:

* Web servers (Nginx, Apache)
* Microservices (Node.js, Go, Python)
* Frontend applications
* API gateways

➡️ **Deployments work when the application does not need to remember anything about the past.**

---

## 🏛️ Why StatefulSets?

StatefulSets are designed for **stateful, identity-sensitive workloads** where:

* Each pod requires a **stable and predictable name**
  Example: `mongodb-0`, `mongodb-1`, `mongodb-2`

* Each pod needs a **dedicated volume** that never attaches to another pod
  Example: `data-mongodb-0 → pv-mongodb-0`

* Pods must start in **strict order** (0 → N-1)

* Pods must terminate in **reverse order**

### ✔ Real-world examples:

| Application                    | Why StatefulSet?                                           |
| ------------------------------ | ---------------------------------------------------------- |
| **MongoDB, MySQL, PostgreSQL** | Each node has a unique replica role & must retain its data |
| **Kafka / Zookeeper**          | Brokers have node IDs and must keep message logs           |
| **Elasticsearch / OpenSearch** | Cluster membership depends on node identity                |
| **Redis (Cluster Mode)**       | Each shard must maintain its data partition                |
| **Cassandra**                  | Distributed hash ring requires stable nodes                |

If you change pod names or volumes, these databases **break**.

➡️ **StatefulSets guarantee network identity + persistent storage stability.**

---

## 🚀 What This Project Demonstrates

You will deploy a **3-node MongoDB StatefulSet** on Kubernetes with:

* A **headless service** for stable DNS entries
* **StorageClass** (manual provisioning)
* **Static PersistentVolumes**
* **Per-pod PVC binding**
* Data persistence after pod deletion/restart

DNS records created automatically by StatefulSet:

```
mongodb-0.mongodb-service.default.svc.cluster.local
mongodb-1.mongodb-service.default.svc.cluster.local
mongodb-2.mongodb-service.default.svc.cluster.local
```

---

# 📦 Project Structure

```
.
├── mongodb-svc.yaml
├── mongodb-sc.yaml
├── mongodb-pv.yaml
└── mongodb-statefulset.yaml
```

---

# 🔧 Setup Instructions

## 1️⃣ Prepare storage directories on the worker node

```bash
sudo mkdir -p /mnt/data/mongodb-{0..4}
sudo chmod 777 /mnt/data/mongodb-{0..4}
```

---

## 2️⃣ Apply the Kubernetes manifests

### 🔹 Create the Headless Service

```bash
kubectl apply -f mongodb-svc.yaml
```

### 🔹 Create the StorageClass

```bash
kubectl apply -f mongodb-sc.yaml
```

### 🔹 Create PVs (Static Provisioning)

```bash
kubectl apply -f mongodb-pv.yaml
```

### 🔹 Create StatefulSet

```bash
kubectl apply -f mongodb-statefulset.yaml
```

---

# 📊 Verify Resources

### Pods:

```bash
kubectl get pods
```

Expected:

```
mongodb-0
mongodb-1
mongodb-2
```

### PVCs:

```bash
kubectl get pvc
```

Each pod gets its own claim:

```
data-mongodb-0 → pv-mongodb-0
data-mongodb-1 → pv-mongodb-1
data-mongodb-2 → pv-mongodb-2
```

---

# 🧪 Test Persistence

### Connect to MongoDB:

```bash
kubectl exec -it mongodb-0 -- mongo
```

Insert sample data:

```javascript
use testdb
db.users.insert({name:"user1", email:"user1@example.com"})
db.users.insert({name:"user2", email:"user2@example.com"})
db.users.find()
exit
```

---

## 🔥 Delete a Pod

```bash
kubectl delete pod mongodb-0
```

Kubernetes will recreate it automatically.

Now check the data again:

```bash
kubectl exec -it mongodb-0 -- mongo
use testdb
db.users.find()
```

✔ The records persist — because the volume reattached to the same pod identity.

---

# 🎮 Explore Node Storage

SSH to the node and check the directories:

```bash
cd /mnt/data
find .
```

You’ll see dedicated folders:

```
mongodb-0/
mongodb-1/
mongodb-2/
...
```

Each folder corresponds to its respective pod.

---

# 🧹 Cleanup

```bash
kubectl delete statefulset mongodb
kubectl delete svc mongodb-service
kubectl delete pvc --all
kubectl delete pv --all
kubectl delete sc mongodb-sc
```

---

# 📘 References

📎 Kubernetes StatefulSet official docs:
[https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/)

---

# 🌟 Summary

| Feature       | Deployment         | StatefulSet                            |
| ------------- | ------------------ | -------------------------------------- |
| Pod names     | Random             | Predictable (`pod-0`)                  |
| Storage       | Shared / ephemeral | Dedicated per-pod PVC                  |
| Scaling order | Unordered          | Strict sequence                        |
| Use case      | Stateless apps     | Databases, queues, distributed systems |
| Pod identity  | Not preserved      | Always preserved                       |

➡️ Use **Deployment** for stateless workloads.
➡️ Use **StatefulSet** when identity + storage persistence matter.

---

