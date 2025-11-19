
---

# 📦 Day-42 Deploying a Private Docker Registry on Kubernetes (Day-42 – CNCF Project)

This project guides you through deploying a **secure private container registry** inside Kubernetes using:

* Self-signed TLS certificates
* Basic Authentication (htpasswd)
* Kubernetes Secrets
* Persistent storage (PV + PVC)
* Deployment + Service
* Pushing an image to your registry
* Pulling the image inside a pod using imagePullSecrets

---

# 1️⃣ Create Local Registry Directory

```bash
mkdir registry
cd registry
mkdir certs auth
```

---

# 2️⃣ Generate Self-Signed TLS Certificate

```bash
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -sha256 \
  -keyout certs/tls.key \
  -out certs/tls.crt \
  -subj "/CN=my-registry" \
  -addext "subjectAltName = DNS:my-registry"
```

Verify:

```bash
ls certs/
# must contain: tls.key tls.crt
```

---

# 3️⃣ Create Basic Authentication (htpasswd)

```bash
docker run --entrypoint htpasswd httpd:2 \
  -Bbn myuser mypasswd > auth/htpasswd
```

Meaning:

* `-B` → bcrypt encryption
* `-b` → take password from CLI
* `-n` → print to stdout

Verify:

```bash
cat auth/htpasswd
```

---

# 4️⃣ Create Kubernetes Secrets

## TLS Secret:

```bash
kubectl create secret tls certs-secret \
  --cert=certs/tls.crt \
  --key=certs/tls.key
```

## Authentication Secret:

```bash
kubectl create secret generic auth-secret \
  --from-file=auth/htpasswd
```

Check:

```bash
kubectl get secrets
```

---

# 5️⃣ Create PV & PVC (volume.yaml)

```yaml
# volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: registry-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/home/ubuntu/repo"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

Apply:

```bash
kubectl apply -f volume.yaml
```

---

# 6️⃣ Create Registry Deployment (deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  labels:
    app: registry
spec:
  replicas: 2
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2.8.2
          env:
            - name: REGISTRY_AUTH
              value: "htpasswd"
            - name: REGISTRY_AUTH_HTPASSWD_REALM
              value: "Registry Realm"
            - name: REGISTRY_AUTH_HTPASSWD_PATH
              value: "/auth/htpasswd"
            - name: REGISTRY_HTTP_TLS_CERTIFICATE
              value: "/certs/tls.crt"
            - name: REGISTRY_HTTP_TLS_KEY
              value: "/certs/tls.key"
          volumeMounts:
            - name: repo-vol
              mountPath: "/var/lib/registry"
            - name: certs-vol
              mountPath: "/certs"
              readOnly: true
            - name: auth-vol
              mountPath: "/auth"
              readOnly: true
      volumes:
        - name: repo-vol
          persistentVolumeClaim:
            claimName: registry-pvc
        - name: certs-vol
          secret:
            secretName: certs-secret
        - name: auth-vol
          secret:
            secretName: auth-secret
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

---

# 7️⃣ Create Service (svc.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
spec:
  selector:
    app: registry
  ports:
    - port: 5000
      targetPort: 5000
      protocol: TCP
  type: ClusterIP
```

Apply:

```bash
kubectl apply -f svc.yaml
```

---

# 8️⃣ Add Registry DNS Entry

Get service IP:

```bash
kubectl get svc docker-registry
```

Set environment variable:

```bash
export REGISTRY_NAME="my-registry"
export REGISTRY_IP="<SERVICE_IP>"
```

Edit `/etc/hosts` on **all nodes**:

```
<SERVICE_IP> my-registry
```

---

# 9️⃣ Fix Docker “unknown certificate authority” Error

Copy TLS cert to all nodes:

```bash
sudo cp certs/tls.crt /usr/local/share/ca-certificates/my-registry.crt
sudo update-ca-certificates --fresh
```

Create Docker certs dir on each node:

```bash
sudo mkdir -p /etc/docker/certs.d/my-registry:5000
sudo cp certs/tls.crt /etc/docker/certs.d/my-registry:5000/
sudo systemctl restart docker
```

Now test login:

```bash
docker login my-registry:5000 -u myuser -p mypasswd
```

---

# 🔟 Push a Test Image

```bash
docker pull nginx
docker tag nginx:latest my-registry:5000/mynginx:v2
docker push my-registry:5000/mynginx:v2
```

---

# 1️⃣1️⃣ Create Image Pull Secret for Kubernetes

```bash
kubectl create secret docker-registry nginx-secret \
  --docker-server=my-registry:5000 \
  --docker-username=myuser \
  --docker-password=mypasswd
```

---

# 1️⃣2️⃣ Create Pod Using Image From Registry (nginx-pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    run: nginx-pod
spec:
  containers:
    - name: nginx-pod
      image: my-registry:5000/mynginx:v2
  imagePullSecrets:
    - name: nginx-secret
  restartPolicy: Always
```

Apply:

```bash
kubectl apply -f nginx-pod.yaml
```

If you **don’t** use imagePullSecrets → crashloop due to authorization.

---

# ✔️ Final Notes

* Registry is secure (TLS + htpasswd)
* Kubernetes secrets manage credentials & certificates
* Docker is configured to trust the registry
* You can now push/pull images privately inside your cluster

---

