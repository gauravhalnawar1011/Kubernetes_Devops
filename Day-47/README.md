
---

# 🚀 Day-47

# **Kubernetes Gateway API — Clear & Conceptual Explanation**

The **Gateway API** is the modern, more powerful replacement for the old **Ingress API**.
It provides **better routing**, **more protocols**, **standardized configuration**, and **better separation of responsibilities** for teams.

This write-up explains:
✔️ How Ingress worked
✔️ Why it had limitations
✔️ How Gateway API improves the model
✔️ Real-life scenarios
✔️ Demo steps you followed (NGINX Gateway Fabric)

---

# 🏁 **How Things Worked Earlier — Ingress**

Ingress was the traditional way to expose applications to the outside world.

### 🧭 Ingress flow:

```
User → HTTP/HTTPS → Ingress Resource → Ingress Controller → Service → Pod
```

You define **host/path rules** inside the Ingress resource, and the Ingress Controller (NGINX, HAProxy, Traefik, etc.) handles routing.

### ❌ Limitations of Ingress

1. **Only supports HTTP/HTTPS routing**
   No native TCP, UDP, gRPC routing.

2. **Heavy reliance on annotations**

   * NGINX annotations
   * Kong annotations
   * Traefik annotations
     These were **vendor-specific** → making migration very hard.

3. **No standard support for advanced routing**

   * Header-based routing
   * Method-based routing
   * Traffic splitting / canary rollout
   * Request/response modification

4. **Teams couldn’t share responsibility**
   Infra team & app team both touched the same Ingress resource.

---

# 🌉 **Gateway API — Modern Replacement for Ingress**

Gateway API introduces **CRDs (Custom Resources)** that offer much deeper control and flexibility.

### ✨ What Gateway API supports:

* HTTP routing
* HTTPS routing
* TCP routing
* UDP routing
* gRPC routing
* Header-based routing
* Query-based routing
* Method-based routing
* Traffic-splitting (canary rollout)
* Request/response rewrite
* Multi-team ownership model

---

# 🧩 **Key Components of Gateway API**

### 1️⃣ **GatewayClass**

Defines **what type of load balancer** you are using.
Example: nginx, istio, kong, haproxy

*(Infra team manages this)*

---

### 2️⃣ **Gateway**

Actual load balancer instance created in the cluster.

It defines:

* Which ports to listen on
* Which protocols (HTTP, HTTPS, TCP, etc.)
* Which routes it will accept

*(Cluster/operators manage this)*

---

### 3️⃣ **Route resources**

Different route types for different protocols:

* **HTTPRoute**
* **TLSRoute**
* **TCPRoute**
* **UDPRoute**
* **GRPCRoute**

Routes contain **routing rules** that forward traffic to Services.

*(Application team manages these)*

---

# 🏛️ **Layered Ownership Model** — Industry Standard

Unlike Ingress (single file doing everything), Gateway API separates responsibilities:

| Layer       | Managed By          | Resource                    |
| ----------- | ------------------- | --------------------------- |
| Infra Layer | Infra/Platform Team | **GatewayClass**            |
| Cluster Ops | DevOps/SRE          | **Gateway**                 |
| App Layer   | App/Dev Team        | **HTTPRoute/TCPRoute/etc.** |

This matches how real companies work.

---

# 🎯 Real-Life Scenarios Where Gateway API Shines

### **Scenario 1 — Canary Deployment (Weighted Traffic Splitting)**

You want:

* 90% traffic → v1 backend
* 10% traffic → v2 backend

Ingress: ❌ Not supported (requires vendor extension/annotations)
Gateway API: ✅ Native support in HTTPRoute

---

### **Scenario 2 — Microservices Needing Different Protocols**

* Service A → HTTP
* Service B → gRPC
* Service C → TCP
* Service D → UDP

Ingress: ❌ Only HTTP/HTTPS
Gateway API: ✅ Supports all

---

### **Scenario 3 — Standard YAML Across All Vendors**

Migration from:

* NGINX → Kong
* Kong → Istio
* Istio → HAProxy

Ingress: ❌ YAML must be rewritten — annotations differ
Gateway API: ✅ No change in YAML, controllers follow the same spec

---

### **Scenario 4 — Security Separation Between Teams**

Infra team sets up Gateway (ports, TLS).
App teams only create Routes.

Reduces mistakes and aligns with enterprise security best practices.

---


#  Demo Kubernetes Gateway API

## Solution & Full Demo Guide

## Prerequisites

* Kubernetes cluster (minikube, kind, KodeKloud playground, cloud providers)
* kubectl installed and configured
* Basic understanding of pods, deployments, services, and Ingress

---

## Step 1: Install Gateway API Resources

```bash
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.5.1" | kubectl apply -f -

kubectl get crd | grep gateway
```

Expected CRDs include:

* gatewayclasses.gateway.networking.k8s.io
* gateways.gateway.networking.k8s.io
* httproutes.gateway.networking.k8s.io

---

## Step 2: Configure NGINX Gateway Fabric

### Install CRDs

```bash
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/crds.yaml
```

### Deploy NGINX Gateway Fabric

```bash
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/nodeport/deploy.yaml
kubectl get pods -n nginx-gateway
```

Expected output:

```
NAME                             READY   STATUS    RESTARTS   AGE
nginx-gateway-5d4d9b47c4-x8z6l   1/1     Running   0          30s
```

### Patch service to expose ports 30080 & 30081

```bash
kubectl patch svc nginx-gateway -n nginx-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
  {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30081}
]'
```

Verify:

```bash
kubectl get svc -n nginx-gateway nginx-gateway
```

Expected:

```
80:30080/TCP,443:30081/TCP
```

---

## Step 3: Create GatewayClass & Gateway Resources

`gateway-resources.yaml`:

```yaml
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-gateway
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
```

Apply:

```bash
kubectl apply -f gateway-resources.yaml
kubectl get gatewayclass
kubectl get gateway
```

Expected:

```
nginx   gateway.nginx.org/nginx-gateway-controller   True
```

---

## Step 4: Create Frontend Pod

Create a pod named `frontend-app` exposing container port 8080.

---

## Step 5: Create Service for Frontend

Create a service `frontend-svc` exposing port 80 → targetPort 8080.

---

## Step 6: Create HTTPRoute

`frontend-route.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: default
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: frontend-svc
      port: 80
```

Apply:

```bash
kubectl apply -f frontend-route.yaml
kubectl get httproute frontend-route
kubectl describe httproute frontend-route
```

Expected: Route shows **Accepted**.

---

## Step 7: Test the Setup

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
curl http://$NODE_IP:30080/
```

Open in browser:

```
http://<NODE_IP>:30080/
```

You should see your frontend app response.

---

## Troubleshooting

* Check Gateway:

```bash
kubectl describe gateway nginx-gateway -n nginx-gateway
```

* Check Route:

```bash
kubectl describe httproute frontend-route
```

* Check controller logs:

```bash
kubectl logs -n nginx-gateway deployment/nginx-gateway
```

* Check service endpoints:

```bash
kubectl get endpoints
```

---

## Key Concepts

* **GatewayClass** → defines implementation
* **Gateway** → actual gateway instance
* **HTTPRoute** → routing rules
* Supports advanced routing: headers, methods, path prefixes, traffic-splitting

---

## Advantages of Gateway API

* Standardized (no vendor-specific annotations)
* Multi-protocol (HTTP/HTTPS/TCP/UDP/gRPC)
* Canary rollouts supported
* Clear team separation
* Highly extensible
---

# 📝 Final Summary — Why Gateway API Matters

| Feature                  | Ingress         | Gateway API |
| ------------------------ | --------------- | ----------- |
| Multi-protocol (TCP/UDP) | ❌ No            | ✅ Yes       |
| HTTP advanced routing    | Limited         | Advanced    |
| Canary rollout           | Vendor-specific | Native      |
| Standard across vendors  | ❌ No            | ✅ Yes       |
| Team ownership model     | ❌ No            | ✅ Yes       |
| Replace annotations      | ❌ No            | ✅ Yes       |

**Gateway API is the future of traffic routing in Kubernetes** and solves almost all the pain points of Ingress.

---

