
---

# Day-37 – Application Troubleshooting Guide

This document walks through troubleshooting steps for the **Example Voting App** deployed on Kubernetes.

## 1. Clone the Repository

```bash
git clone https://github.com/piyushsachdeva/example-voting-app
cd example-voting-app
```

## 2. Application Architecture

The Example Voting App consists of **five pods/services**:

1. **Frontend (Vote UI)** – exposed via **NodePort : 31000**
2. **Redis** – backend service (ClusterIP)
3. **.NET Worker** – reads votes from Redis and writes to DB
4. **PostgreSQL** – backend DB (ClusterIP)
5. **Result App (Node.js)** – exposed via **NodePort : 31001**

## 3. Deploy the Application

Apply all YAML manifests from the current directory:

```bash
kubectl apply -f .
```

---

## 4. Accessing the Application

To access NodePort services externally, you need the **public IP of the Kubernetes worker node** hosting the pods.

### Step 1: Check Pod Placement

```bash
kubectl get po -o wide
```

Identify which **worker node** is running the frontend and result pods.

### Step 2: Get Node Public IP

Open your cloud console and retrieve the public IP of the worker node hosting these pods.

---

## 5. Troubleshooting Services & Endpoints

### Check service status:

```bash
kubectl get svc
kubectl get endpoints
```

If endpoints are missing:

* Validate service **selectors/labels**
* Ensure labels on pods match labels on service selectors

---

## 6. Fixing Result Service Port Misconfiguration

The **result service** exposes port **8080**, but the pod actually listens on **80**.

### Verify Pod Ports:

```bash
kubectl get pod <pod_name> -o yaml
```

### Patch the Service:

```bash
kubectl edit svc result
```

Update:

```yaml
targetPort: 80
```

This restores connectivity for the **Result UI**.

---

## 7. Votes Not Being Submitted (Redis Issue + NetworkPolicy)

If the frontend loads but votes are not submitted:

### Step 1: Verify Redis Service

```bash
kubectl get svc redis
kubectl get endpoints redis
```

### Step 2: Check Network Policies

A restrictive NetworkPolicy might block communication.

```bash
kubectl get netpol access-redis
```

The policy currently allows traffic from pods labeled:

```yaml
app: frontend
```

But our actual pod labels are:

* `app: vote`
* `app: result`

### Step 3: Fix the NetworkPolicy

```bash
kubectl edit netpol redis
```

Update `matchLabels` to include:

```yaml
app: vote
```

Save the file and reapply.
This will allow vote submission traffic to reach **Redis**.

---

## 8. Summary

After fixing:

* Service label mismatches
* Result application `targetPort`
* NetworkPolicy rules for Redis

The application should be fully functional:

* Frontend reachable via NodePort 31000
* Result app reachable via NodePort 31001
* Votes successfully submitted to Redis
* Results visible from PostgreSQL via the Result UI

---

