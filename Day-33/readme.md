
# 🌐 Kubernetes Ingress & Ingress Controller — Beginner’s Guide  

This guide explains **Ingress** and **Ingress Controllers** in Kubernetes — what they are, why they’re needed, and how to deploy them step-by-step using **NGINX Ingress Controller**.  

---

## 📘 Table of Contents  

| Section | Description |
|----------|-------------|
| [What is Ingress?](#-what-is-ingress) | Understand the concept of Ingress and its purpose |
| [Why Use Ingress?](#-why-use-ingress) | Limitations of LoadBalancer/NodePort and how Ingress solves them |
| [Ingress Architecture](#-ingress-architecture) | Components involved in Ingress setup |
| [Deploying NGINX Ingress Controller](#-deploying-nginx-ingress-controller) | Step-by-step guide to deploy the controller |
| [Example Setup](#-example-setup) | Example YAML files for Deployment, Service, and Ingress |
| [Troubleshooting & Testing](#-troubleshooting--testing) | Debugging and validating your setup |
| [Key Takeaways](#-key-takeaways) | Summary of important points |

---

## 🤔 What is Ingress?

In Kubernetes, **Ingress** manages **external access** to services within a cluster, typically over **HTTP/HTTPS**.  

It provides features such as:
- Path-based and host-based routing  
- Centralized traffic management  
- TLS/SSL termination  
- Load balancing  
- Custom rewrite and redirection rules  

---

## 💡 Why Use Ingress?

When you deploy your application as a **Pod**, it’s accessible **within the cluster**, but **not externally**.  
To expose it outside, we use **Services** of type:
- `NodePort`  
- `LoadBalancer`

However, both approaches have limitations:

| Approach | Drawbacks |
|-----------|------------|
| **NodePort** | Not recommended for production; limited port range; manual routing required |
| **LoadBalancer** | Depends on cloud provider; expensive (one LB per service); limited customization and security control |

👉 **Ingress** solves these issues by providing a **single entry point** (a unified Load Balancer) that intelligently routes traffic to multiple backend services within your cluster.

---

## 🏗️ Ingress Architecture

To implement Ingress, you need **three key components**:

1. **Ingress Resource** — A YAML definition specifying routing rules  
2. **Ingress Controller** — A controller (e.g., NGINX, Kong, Traefik) that watches Ingress resources and configures the load balancer accordingly  
3. **LoadBalancer or NodePort Service** — Exposes the controller itself externally  

### 🔁 How It Works

1. You define an **Ingress Resource** with routing rules.  
2. The **Ingress Controller** (e.g., NGINX) watches and interprets this configuration.  
3. It dynamically updates the **load balancer** to route external traffic to internal services.

---

## 🚀 Deploying NGINX Ingress Controller

### Step 1: Apply the Official NGINX Ingress Controller Manifest

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml
````

### Step 2: Verify the Deployment

```bash
kubectl get pods --namespace=ingress-nginx -w
```

Expected output:

```
NAME                                       READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-cc68b44bd-qlcsp   1/1     Running   0          41s
```

### Step 3: Check the Service Type

```bash
kubectl get svc -n ingress-nginx
```

If the **External IP** is `<pending>`, it means your cluster doesn’t have a cloud load balancer.
Change the service type to `NodePort` manually:

```bash
kubectl edit svc/ingress-nginx-controller -n ingress-nginx
```

Change:

```yaml
type: LoadBalancer
```

to:

```yaml
type: NodePort
```

---

## 🧩 Example Setup

We’ll deploy a simple “Hello World” app and expose it through Ingress.

### **1️⃣ Deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  labels:
    app: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: gauravhalnawar2705/cks-ingress
        ports:
        - containerPort: 80
```

---

### **2️⃣ Service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-world
spec:
  selector:
    app: hello-world
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

---

### **3️⃣ Ingress.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: "example.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-world
            port:
              number: 80
```

---

### Apply All Files

```bash
kubectl apply -f Deployment.yaml
kubectl apply -f Service.yaml
kubectl apply -f Ingress.yaml
```

---

## 🔍 Troubleshooting & Testing

### Check Ingress Status

```bash
kubectl get ing
```

Expected output:

```
NAME          CLASS   HOSTS         ADDRESS        PORTS   AGE
hello-world   nginx   example.com   10.101.14.35   80      18m
```

If you see `<pending>` in the ADDRESS field, ensure your ingress controller service type is `NodePort`.

### Test Access

#### Option 1 — Using `/etc/hosts`

Add an entry to map the IP to the hostname:

```
10.101.14.35   example.com
```

Then test:

```bash
curl http://example.com
```

✅ Output:

```
Hello, World!
```

#### Option 2 — Using `curl --resolve`

```bash
curl --resolve example.com:80:10.101.14.35 http://example.com
```

✅ Output:

```
Hello, World!
```

---

## 🧠 IngressClassName Explained

When multiple ingress controllers (e.g., **NGINX**, **Kong**) exist in the same cluster, they may compete for Ingress resources.
To avoid conflicts, Kubernetes introduced the `ingressClassName` field in the Ingress spec.

```yaml
spec:
  ingressClassName: nginx
```

This ensures that only the **NGINX Ingress Controller** handles this Ingress resource.

---

## 🧩 Example Minimal Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

---

## 🧱 Available NGINX Ingress Options

| Type                              | Maintained By        | Repository                                                              |
| --------------------------------- | -------------------- | ----------------------------------------------------------------------- |
| **Community NGINX Ingress**       | Kubernetes Community | [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx) |
| **NGINX Inc. Ingress Controller** | NGINX (F5)           | [NGINX Docs](https://docs.nginx.com/nginx-ingress-controller/)          |

---

## ✅ Key Takeaways

* **Ingress** provides smart, centralized traffic management for Kubernetes applications.
* **Ingress Controllers** (like NGINX) implement the routing logic defined in your Ingress YAML.
* Use `ingressClassName` when running multiple controllers.
* `LoadBalancer` type services are cloud-dependent and costly; Ingress provides a scalable alternative.
* Always verify your Ingress and Service configurations when troubleshooting access issues.

---

💬 **In summary:**
Kubernetes **Ingress** simplifies external access by routing multiple services through a single, intelligent entry point — making your cluster **more efficient, secure, and scalable**.


