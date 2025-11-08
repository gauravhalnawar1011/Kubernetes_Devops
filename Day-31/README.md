
---

# Day-31 — Understanding CoreDNS in Kubernetes

## Overview

**CoreDNS** is the default DNS server in Kubernetes.
It provides **service discovery** by allowing communication between Pods and Services using names instead of IP addresses.

For example, a Pod can access another Pod or Service using its name (`nginx-service`) instead of the IP. CoreDNS handles this name-to-IP resolution automatically.

---

## Example Setup

We’ll demonstrate DNS resolution inside a Kubernetes cluster using two NGINX Pods and a ClusterIP Service.

### Pod Definitions

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-1
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-2
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80
```

### Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-clusterip-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

---

## Testing Communication

Check if one Pod can reach another by **service name** or **IP address**.

### Using Service/Pod Name (Fails)

```bash
kubectl exec -it nginx-pod-1 -n dev -- curl nginx-pod-2
```

**Output:**

```
curl: (6) Could not resolve host: nginx-pod-2
command terminated with exit code 6
```

### Using Pod IP (Succeeds)

```bash
kubectl exec -it nginx-pod-1 -n dev -- curl 192.168.116.195
```

**Output:**

```
<!DOCTYPE html>
<html>
<head><title>Welcome to nginx!</title></head>
<body><h1>Welcome to nginx!</h1></body>
</html>
```

✅ This means networking is fine, but **DNS resolution** is not working properly.

---

## DNS Investigation

### 1. Check CoreDNS Service

```bash
kubectl get svc -n kube-system
```

Example output:

```
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   65m
```

* `kube-dns` is the Kubernetes Service exposing **CoreDNS**.
* It listens on port **53**, the default DNS port.
* The ClusterIP (`10.96.0.10`) is used by all Pods for DNS lookups.

---

### 2. Verify Pod DNS Configuration

```bash
kubectl exec -it nginx-pod-1 -n dev -- cat /etc/resolv.conf
```

Output:

```
search dev.svc.cluster.local svc.cluster.local cluster.local ap-south-1.compute.internal
nameserver 10.96.0.10
options ndots:5
```

* `nameserver 10.96.0.10` → Points to the CoreDNS Service.
* All DNS queries from this Pod go through that IP.

---

### 3. Check Hosts File

```bash
kubectl exec -it nginx-pod-1 -n dev -- cat /etc/hosts
```

Output:

```
# Kubernetes-managed hosts file.
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
192.168.116.194 nginx-pod-1
```

This only contains local Pod entries — it doesn’t handle DNS resolution between Pods.
That’s handled by **CoreDNS**.

---

## Inspecting CoreDNS Configuration

### Check CoreDNS Deployment

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Each CoreDNS Pod mounts a **ConfigMap** that defines how DNS queries are processed.

### View CoreDNS ConfigMap

```bash
kubectl describe cm coredns -n kube-system
```

Example output:

```text
Corefile:
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

---

## CoreDNS Plugin Explanation

| Plugin          | Purpose                                                |
| --------------- | ------------------------------------------------------ |
| **errors**      | Logs DNS query errors                                  |
| **health**      | Monitors CoreDNS pod health                            |
| **ready**       | Signals readiness to Kubernetes                        |
| **kubernetes**  | Handles cluster domain queries (`*.svc.cluster.local`) |
| **prometheus**  | Exposes CoreDNS metrics on port 9153                   |
| **forward**     | Forwards unresolved DNS queries to upstream resolvers  |
| **cache**       | Improves performance by caching DNS results            |
| **loop**        | Detects and prevents infinite query loops              |
| **reload**      | Automatically reloads CoreDNS config on changes        |
| **loadbalance** | Balances load across multiple upstream DNS servers     |

---

## Troubleshooting Checklist

If DNS resolution fails inside the cluster:

1. **Check CoreDNS Pod status**

   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. **Inspect CoreDNS logs**

   ```bash
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```

3. **Verify ConfigMap**

   ```bash
   kubectl describe cm coredns -n kube-system
   ```

4. **Check Pod DNS**

   ```bash
   kubectl exec -it <pod-name> -- cat /etc/resolv.conf
   ```

5. **Restart CoreDNS**

   ```bash
   kubectl rollout restart deployment coredns -n kube-system
   ```

---

## Testing DNS Resolution

Test DNS directly inside a Pod:

```bash
kubectl exec -it nginx-pod-1 -- nslookup nginx-clusterip-service
```

Expected output:

```
Name:   nginx-clusterip-service.dev.svc.cluster.local
Address: 10.100.12.85
```

If you see the service name resolved to an IP, DNS is working correctly.

---

## Summary

* **CoreDNS** provides name resolution for Pods and Services in Kubernetes.
* Every Pod automatically gets DNS configuration in `/etc/resolv.conf`.
* **ClusterIP (10.96.0.10)** of `kube-dns` acts as the cluster-wide DNS server.
* If Pods communicate via IP but not by name → DNS misconfiguration.
* CoreDNS behavior is defined in its **ConfigMap** and managed as a Deployment.

---

## Key Concepts

| Concept                 | Description                                        |
| ----------------------- | -------------------------------------------------- |
| **Service Discovery**   | Enables Pods to find and connect via service names |
| **CoreDNS**             | Kubernetes DNS server for internal name resolution |
| **ClusterIP**           | Internal virtual IP for Services                   |
| **ConfigMap (coredns)** | Stores CoreDNS configuration                       |
| **/etc/resolv.conf**    | Pod-level DNS configuration file                   |


---
