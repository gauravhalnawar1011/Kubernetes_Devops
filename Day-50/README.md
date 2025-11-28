
---

# 🚀 **Day-50 — Kubernetes Operators (Complete Guide)**

*"Become a master in Kubernetes Operators with real production examples + YAMLs"*

---

# 📌 **1. Traditional vs Operator Pattern**

## 🧱 **Traditional (Manual) Approach**

You deploy and manage applications using:

* Raw YAML files (`kubectl apply`)
* Helm chart installs
* Kustomize overlays
* Manual configuration updates
* Manual scaling (without HPA/VPA/KEDA)
* Manual rollbacks
* Manual lifecycle tasks:

  * backups
  * upgrades
  * secret rotation
  * certificate renewal

Example manual tasks:

* Update deployment image → redeploy
* Rotate TLS certificates manually
* Backup/restore DB via scripts
* Manually watch pod health and recreate

➡️ **Very high maintenance**
➡️ Requires continuous DevOps intervention
➡️ Error-prone

---

## ⚙️ **Operator Pattern**

An **operator automates all day-2/day-3 operations** of an application.

### Instead of manual actions, you:

1. **Install the Operator**
2. **Define the desired state** using **Custom Resources (CRs)**

The Operator:

* installs the app
* configures it
* scales it
* upgrades it
* rotates secrets
* renews certificates
* handles rollbacks
* self-heals when something drifts from desired state

Think of an Operator as:

> **"A DevOps engineer encoded into software — watching your cluster 24/7."**

---

# 📌 **2. How Does an Operator Work? (Reconciliation Loop)**

### Workflow:

### 1️⃣ You define **desired state** via a Custom Resource (CR):

Example:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-tls
spec:
  dnsNames:
  - demo.example.com
  issuerRef:
    name: selfsigned
```

### 2️⃣ Operator **watches CRs continuously**

A controller inside the operator receives events:

* CR created
* CR updated
* CR deleted

### 3️⃣ Operator **compares actual state vs desired state**

(“Reconciling Loop”)

### 4️⃣ Operator takes actions:

* create/update k8s resources
* call APIs (e.g., Let's Encrypt)
* rotate certificates
* update secrets
* scale deployments
* run backup/restore tasks

### 5️⃣ Loop repeats forever

If something breaks, Operator fixes it automatically.

---

# 📌 **3. Key Components of a Kubernetes Operator**

## ✔️ **1. Custom Resource Definition (CRD)**

Extends Kubernetes API with new resource types.

Example:

```
certificates.cert-manager.io
issuers.cert-manager.io
mysqlclusters.mysql.presslabs.org
```

## ✔️ **2. Custom Resource (CR)**

Instance of the CRD.

Example:

```
Certificate
Issuer
MySQLCluster
KafkaTopic
MongoDBRestore
```

## ✔️ **3. Controller**

The “brain” of the Operator:

* watches CRs
* runs reconciliation
* performs operations

---

# 📌 **4. Why Do We Use Operators?**

| Use Case                             | Benefit                                  |
| ------------------------------------ | ---------------------------------------- |
| 🚀 Automate Day-2/Day-3 ops          | certificates, scaling, backups, upgrades |
| 🎯 Encode domain knowledge           | app expertise → reusable automation      |
| 🔁 Continuous reconciliation         | constant drift correction                |
| 🧩 Extend Kubernetes like a platform | add new API types                        |
| 🔒 Security automation               | secret rotation, TLS renewal             |
| ☁️ Cloud-native lifecycle mgmt       | complex apps (DB, Kafka, Redis)          |

Examples of Production-level Operators:

* **cert-manager** → TLS automation
* **Prometheus Operator** → monitoring stack automation
* **Kafka Operator (Strimzi)** → cluster mgmt
* **ElasticSearch Operator (ECK)** → ES lifecycle
* **MongoDB Operator**
* **Vault Operator**

---

# 📌 **5. How Operators Differ from GitOps & CI/CD**

## 🆚 GitOps (ArgoCD, Flux)

* Git stores desired state
* GitOps applies manifests automatically
* GitOps does **deployment & drift mgmt**

GitOps DOES NOT:

* renew certificates
* run backups
* rotate secrets
* manage complex distributed systems

## 🆚 CI/CD (Jenkins, GitHub Actions)

* builds & pushes artifacts
* triggers deployments
* no lifecycle management

## 🏆 Operators

* automate complex workflows & logic
* run 24/7 inside cluster
* continuously reconcile
* integrate external services (AWS, CA, DB engine)

---

# 📌 **6. Operator Installation Methods**

### ✔️ `kubectl apply`

Apply CRDs + deployment manifests

### ✔️ Helm chart

Most operators ship a Helm chart

### ✔️ OLM (Operator Lifecycle Manager)

Production-grade operator marketplace + upgrade manager
(Source: operatorhub.io)

---

# 📌 **7. Real Demo: Install cert-manager Operator via OLM**

We will install:

* OLM
* cert-manager operator
* Create Issuer
* Create Certificate
* Validate reconciliation

---

# 🧪 **Step 1 — Install OLM**

```bash
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.32.0/install.sh | bash -s v0.32.0
```

Check:

```bash
kubectl get pods -n olm
```

---

# 🧪 **Step 2 — Install cert-manager Operator**

```bash
kubectl create -f https://operatorhub.io/install/cert-manager.yaml
```

Check status:

```bash
kubectl get csv -n operators
```

Look for:

```
cert-manager.vX.X.X   Succeeded
```

---

# 🧪 **Step 3 — Verify CRDs Installed**

```bash
kubectl get crds | grep cert-manager
```

Expected:

```
certificates.cert-manager.io
issuers.cert-manager.io
clusterissuers.cert-manager.io
```

---

# 🧪 **Step 4 — Create OperatorGroup**

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cert-manager-operatorgroup
  namespace: operators
spec:
  targetNamespaces:
    - operators
```

Apply:

```bash
kubectl apply -f cert-manager-operatorgroup.yaml
```

---

# 🧪 **Step 5 — Create Issuer (Self-Signed)**

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: default
spec:
  selfSigned: {}
```

Apply:

```bash
kubectl apply -f selfsigned-issuer.yaml
```

Check:

```bash
kubectl get issuer -n default
```

---

# 🧪 **Step 6 — Create Certificate**

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-certificate
  namespace: default
spec:
  secretName: my-app-tls
  dnsNames:
    - my-app.example.com
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
```

Apply:

```bash
kubectl apply -f my-app-certificate.yaml
```

---

# 🧪 **Step 7 — Validate Operator Reconciliation**

### Check Certificate:

```bash
kubectl get certificate -n default
```

### Check TLS Secret:

```bash
kubectl get secret my-app-tls -n default
```

Output should be:

```
kubernetes.io/tls
```

### Inspect logs (optional):

```bash
kubectl logs -n operators -l app.kubernetes.io/component=controller
```

---

# 📌 **8. Clean Up**

```bash
kubectl delete -f my-app-certificate.yaml
kubectl delete -f selfsigned-issuer.yaml
kubectl delete -f cert-manager-operatorgroup.yaml
kubectl delete namespace operators
kubectl delete namespace olm
```

---

# 🎯 **Summary (What You Should Remember)**

| Concept              | Importance                              |
| -------------------- | --------------------------------------- |
| CRD                  | Defines new Kubernetes API              |
| CR                   | Desired state provided by user          |
| Controller           | Implements logic to reach desired state |
| Reconciliation Loop  | Heart of the operator                   |
| Operators            | Automate day-2/3 operations             |
| cert-manager Example | Automates full certificate lifecycle    |

---

#Kubernetes #Operators #DevOps #K8s #PlatformEngineering #CloudNative #SRE #LearningInPublic #certmanager #OLM #CRD #Automation #OpenSource