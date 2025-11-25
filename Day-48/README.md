
---

# 🚀 Day-48 — Migrating from Ingress to Gateway API

### A Complete, Production-Ready, DevOps-Oriented Migration Guide (With Extra Comments)

As we know, **Ingress will no longer be maintained**, which means **no new features, no long-term improvements, and limited support** after **March 2026**.
This pushes the Kubernetes community toward a better, modern alternative:

👉 **The Gateway API — the future of Kubernetes traffic management.**

The Gateway API introduces a cleaner design, improved routing, broader protocol support, and powerful multi-team separation.

---

# 📘 Table of Contents

1. [Why Migrate?](#why-migrate)
2. [Migration Approaches](#migration-approaches)
3. [Solution: Migrating from Ingress to Gateway API](#solution-migrating-from-ingress-to-gateway-api)
4. [Step-by-Step Implementation](#step-by-step-implementation)
5. [Gateway API Migration Steps](#gateway-api-migration-steps)
6. [Migration YAML Files](#migration-yaml-files)
7. [Testing the Migration](#testing-the-migration)
8. [Troubleshooting](#troubleshooting)
9. [DevOps SOC Migration Checklist](#devops-soc-migration-checklist)

---

# 🧭 Why Migrate?

### Ingress API Limitations (Now Outdated)

* Limited routing capabilities
* Depends too heavily on annotations
* Hard to extend or apply consistent policies
* Poor multi-tenant support
* No major updates after **2026**

---

# 🌐 Gateway API Advantages

| Feature             | Ingress     | Gateway API                              |
| ------------------- | ----------- | ---------------------------------------- |
| Extensible?         | ❌ No        | ✅ Yes — highly extensible                |
| Multi-protocol?     | ❌ Only HTTP | ✅ HTTP/HTTPS/gRPC/TCP/UDP                |
| Multi-team support? | ❌ Weak      | ✅ Excellent (GatewayClass, Routes, etc.) |
| Policy Framework?   | ❌ Limited   | ✅ Strong                                 |
| Long-term support?  | ❌ Ends 2026 | ✅ Actively developed                     |

---

# 🔄 Migration Approaches

### **1. Automated Migration Tool (ingress2gateway)**

```bash
ingress2gateway --provider ingress-nginx
```

This tool automatically converts:

* Ingress → Gateway YAML
* TLS blocks → Listener configs
* Host/path → HTTPRoute rules

Useful for **quick conversion**, but not ideal for understanding.

---

### **2. Manual Migration (Recommended)**

✔ Helps understand Gateway architecture
✔ Better control over routing
✔ Production-ready clarity
✔ Teaches TLS handling & multi-namespace interactions

---

# 🟦 Solution: Migrating from Ingress to Gateway API

Below is the fully revised, structured, detailed explanation.

---

## ✔ Prerequisites

* Kubernetes v1.24+
* kubectl installed
* Basic understanding of:

  * Deployments
  * Services
  * Ingress
* A Kubernetes cluster via:

  * Minikube
  * KIND
  * Kodekloud Playground
  * Any cloud provider

---

# 🛠️ Step-by-Step Implementation

---

# **Step 1 — Deploy the Sample Web Application**

```bash
kubectl create namespace web-app
```

---

## `deployment-service.yaml` (With Helpful Comments)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-service                 # Application name — can be changed
  namespace: web-app                # Namespace to isolate app components
spec:
  replicas: 2                       # Two pods for availability; adjust as needed
  selector:
    matchLabels:
      app: web-service              # Must match pod labels below
  template:
    metadata:
      labels:
        app: web-service            # Identifies pods for the Service selector
    spec:
      containers:
      - name: web
        image: nginx:latest         # Replace with your actual web app image
        ports:
        - containerPort: 80         # Container listens on port 80
        volumeMounts:
        - name: web-config
          mountPath: /usr/share/nginx/html  # Mount static content
      volumes:
      - name: web-config
        configMap:
          name: web-content         # ConfigMap serving HTML files
---
apiVersion: v1
kind: Service
metadata:
  name: web-service                 # Stable internal endpoint
  namespace: web-app
spec:
  ports:
  - port: 80                        # Exposed service port
    targetPort: 80                  # Pod containerPort
  selector:
    app: web-service                # Must match Deployment labels
```

---

# **Step 2 — Create Web Content (ConfigMap)**

## `web-content.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content                 # Name referenced by Deployment volume
  namespace: web-app
data:
  index.html: |                     # Customize this HTML content
    <!DOCTYPE html>
    <html>
    <body>
      <h1>Web Application Content</h1>
      <p>This is the web front-end service.</p>
    </body>
    </html>
```

Apply:

```bash
kubectl apply -f web-content.yaml
```

---

# **Step 3 — Create TLS Secret (Self-Signed Cert)**

This is needed for **HTTPS listener in Gateway API**.

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=gateway.web.k8s.local" \
  -addext "subjectAltName = DNS:gateway.web.k8s.local"

kubectl create secret tls web-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n web-app
```

---

# **Step 4 — Install NGINX Ingress Controller**

```bash
helm install ingress-nginx \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30082 \
  --set controller.service.nodePorts.https=30443 \
  --repo https://kubernetes.github.io/ingress-nginx \
  ingress-nginx
```

---

## `ingress.yaml` (With Clarifying Comments)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web                          # Name of this Ingress resource
  namespace: web-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: "/"     # Rewrite path
    nginx.ingress.kubernetes.io/ssl-redirect: "false"   # Keep HTTP allowed
spec:
  ingressClassName: nginx             # Must match Installed Ingress controller
  tls:
  - hosts:
    - gateway.web.k8s.local           # Domain used for HTTPS
    secretName: web-tls-secret        # TLS secret created earlier
  rules:
  - host: gateway.web.k8s.local       # Your access hostname
    http:
      paths:
      - path: "/"                     # Root route
        pathType: Prefix
        backend:
          service:
            name: web-service         # Backend service
            port:
              number: 80
```

---

# 🌐 Step 5 — Test Ingress

```bash
curl -k http://gateway.web.k8s.local
curl -k https://gateway.web.k8s.local
```

---

# 🧩 Step 6 — Install Gateway API CRDs

```bash
kubectl kustomize \
  "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.5.1" \
  | kubectl apply -f -
```

---

# 🧩 Step 7 — Install NGINX Gateway Fabric (Gateway Controller)

```bash
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/nodeport/deploy.yaml
```

Patch for predictable NodePorts:

```bash
kubectl patch svc nginx-gateway -n nginx-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
  {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30081}
]'
```

---

# 🟥 IMPORTANT

**Gateway API DOES NOT read secrets across namespaces by default.**
You *must use ReferenceGrant* when Gateway and Secret are in different namespaces.

---

# 🟦 Step 8 — Create GatewayClass & Gateway

## `gatewayclass.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx                                # Arbitrary name
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
  # MUST match your installed Gateway controller (NGINX in this case)
```

---

## `gateway.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-gateway
  namespace: nginx-gateway                   # Where the controller runs
spec:
  gatewayClassName: nginx                    # Must match GatewayClass
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: gateway.web.k8s.local          # Your HTTPS domain
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls-secret                 # TLS Secret in web-app namespace
        namespace: web-app                   # Cross-namespace access (needs ReferenceGrant)

  - name: http
    port: 80
    protocol: HTTP
    hostname: gateway.web.k8s.local          # Same domain for HTTP
```

---

# 🟧 Step 9 — Create HTTPRoute Resources

## `httproute-http.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: web-app                          # Routes usually live with apps
spec:
  parentRefs:
  - name: nginx-gateway                       # Gateway name
    namespace: nginx-gateway                  # Gateway namespace
    sectionName: http                         # Must match gateway listener
  hostnames:
  - gateway.web.k8s.local                     # Domain that this route serves
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: "/"                            # All paths routed to backend
    backendRefs:
    - name: web-service
      port: 80
```

---

## `httproute-https.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route-https
  namespace: web-app
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
    sectionName: https                        # HTTPS listener
  hostnames:
  - gateway.web.k8s.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: "/"
    backendRefs:
    - name: web-service
      port: 80
```

---

# 🔐 Step 10 — Cross-Namespace Permission (ReferenceGrant)

## `referencegrant.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-to-web-app-secrets
  namespace: web-app                            # Must be namespace OF secret
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: Gateway
    namespace: nginx-gateway                    # Namespace of Gateway
  to:
  - group: ""                                   # Empty group → core API
    kind: Secret
    name: web-tls-secret                        # Secret allowed to be referenced
```

---

# 🧪 Step 11 — Test Gateway API Routing

```bash
curl -v -H "Host: gateway.web.k8s.local" http://$NODE_IP:30080/
curl -v -k https://gateway.web.k8s.local:30081/
```

---

# 🧹 Step 12 — Delete Old Ingress

```bash
kubectl delete ingress web -n web-app
```

---

# 🐞 Troubleshooting Guide

### ❗ Gateway Not Programmed

```bash
kubectl logs -n nginx-gateway deployment/nginx-gateway
kubectl describe gateway nginx-gateway -n nginx-gateway
```

### ❗ HTTPRoute Not Accepted

```bash
kubectl describe httproute web-route -n web-app
```

### ❗ TLS Issues

* Usually namespace mismatch
* Confirm:

```bash
kubectl get secret web-tls-secret -n web-app
```

---

# ✔ DevOps SOC Migration Checklist

### Planning

* [ ] Identify existing Ingress usage
* [ ] Map TLS secrets and hostnames
* [ ] Validate Gateway controller support

### Pre-Migration

* [ ] Install Gateway API CRDs
* [ ] Install Gateway controller
* [ ] Define GatewayClass

### Migration

* [ ] Create Gateway
* [ ] Add route rules
* [ ] Apply ReferenceGrant

### Cutover

* [ ] DNS → Gateway
* [ ] Delete Ingress
* [ ] Remove Ingress controller

### Post-Migration

* [ ] Setup monitoring (Prometheus/Grafana)
* [ ] Update developer docs
* [ ] Apply governance policies

---

# 🎉 Final Notes

You now have:

✔ Fully working Gateway API setup
✔ TLS termination with proper namespace permissions
✔ HTTP and HTTPS routing via NGINX Gateway Fabric
✔ Complete Ingress → Gateway migration
✔ SOC-grade validation steps and troubleshooting

---

