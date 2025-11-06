
-----

# 🚀 Day 29 — Mastering Kubernetes Storage: Volumes, Persistent Volumes, and PVCs

Storage is the heartbeat of any stateful application running in Kubernetes. Today, we’ll dive deep into how Kubernetes manages data persistence, moving from simple ephemeral volumes to robust, persistent storage that survives Pod restarts and redeployments.

We'll start by spinning up a Redis Pod to see firsthand the limitations of ephemeral `emptyDir` volumes. Then, we’ll build a solid foundation using **Persistent Volumes (PV)** and **Persistent Volume Claims (PVC)** — the true backbone of stateful workloads in Kubernetes.

By the end of this session, you’ll understand:

  * ⚙️ The lifecycle of `emptyDir` volumes and why they don't persist.
  * 🤝 The relationship between a **Persistent Volume (PV)** (the "storage") and a **Persistent Volume Claim (PVC)** (the "request").
  * 🔄 The difference between **Static Provisioning** (manual PV creation) and **Dynamic Provisioning** (using `StorageClass`).
  * 🧩 How **Access Modes** (`ReadWriteOnce`, `ReadWriteMany`) control storage behavior.
  * 🗑️ What **Reclaim Policies** (`Retain`, `Delete`) mean for your data's lifecycle.
  * ☁️ How to connect a Pod to a PVC to consume persistent storage.

This is real DevOps hands-on work. We’ll write and apply multiple YAML manifests, inspect resource bindings, and verify data persistence step-by-step.

-----

## 🧱 Key Learning Path

### 1\. The `emptyDir` Experiment (Ephemeral Storage)

First, we'll see what happens when we use a simple `emptyDir` volume. This type of volume is tied directly to the Pod's lifecycle.

1.  **Deploy Redis:** We'll create a Redis Pod that mounts an `emptyDir` volume at `/data/redis`.
2.  **Test Container Restart:** We'll `exec` into the pod, create a test file, and then kill the Redis process. We'll observe that the container restarts, and our file is **still there**.
3.  **Test Pod Restart:** We'll delete the entire Pod and let it be recreated. We'll observe that the file is **gone**.
4.  **Conclusion:** `emptyDir` survives container crashes but **does not** survive Pod deletion. It is not persistent.

### 2\. The PV and PVC Model (Persistent Storage)

This is the core concept for stateful applications.

  * **PersistentVolume (PV):** Think of this as a "pool" of storage in the cluster, provisioned by a Storage Administrator. It's a cluster resource, just like a Node.
  * **PersistentVolumeClaim (PVC):** This is a *request* for storage, made by a user (or DevOps engineer). The user asks for a specific size (e.g., 500Mi) and access mode (e.g., `ReadWriteOnce`).
  * **Binding:** Kubernetes' control plane watches for new PVCs and tries to *bind* them to a matching PV. For a match to happen, the PV must satisfy the PVC's request for size and have a compatible access mode.
  * **Pending State:** If no PV can satisfy the PVC, the PVC (and any Pod trying to use it) will remain in a `Pending` state until a suitable PV becomes available.

### 3\. Hands-On: Static Provisioning with `hostPath`

We will manually create a PV (static provisioning) using `hostPath` for our demo.

1.  **Create PV:** We'll define a `PersistentVolume` of 1Gi that uses a directory on our EC2 instance (`/home/ubuntu/day29`) as the storage source.
2.  **Create PVC:** We'll define a `PersistentVolumeClaim` that *requests* 500Mi of storage with `ReadWriteOnce` access.
3.  **Verify Binding:** Kubernetes will bind our `block-pvc` to our `block-pv`. We'll verify this with `kubectl get pv,pvc`.
4.  **Deploy Nginx:** We'll deploy an Nginx Pod that mounts our PVC at `/usr/share/nginx/html`.
5.  **Verify Persistence:** We will create an `index.html` file in the `/home/ubuntu/day29` directory *on the EC2 host*. Then, we'll `exec` into the Nginx Pod and use `curl localhost` to see that Nginx is serving the file from our persistent host path.

### 4\. Key Concepts: Access Modes & Reclaim Policies

  * **Access Modes:** Control how the volume can be mounted.
      * `ReadWriteOnce` (RWO): Can be mounted as read-write by a **single node**.
      * `ReadOnlyMany` (ROX): Can be mounted as read-only by **many nodes**.
      * `ReadWriteMany` (RWX): Can be mounted as read-write by **many nodes**.
      * `ReadWriteOncePod` (RWOP): Can be mounted as read-write by a **single Pod**.
  * **Reclaim Policy:** Defines what happens to the PV after the PVC is deleted.
      * `Retain` (Default): The PV is "released" but the data on the underlying volume is kept. An admin must manually clean it up.
      * `Delete`: As soon as the PVC is deleted, the PV and the underlying storage (e.g., the AWS EBS volume) are also deleted.

-----

## YAML Manifests

### 1\. `redis-pod.yaml` (Ephemeral `emptyDir`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-pod
  labels:
    app: redis
spec:
  containers:
    - image: redis
      name: redis
      volumeMounts:
        - name: redis-storage
          mountPath: /data/redis
  volumes:
    - name: redis-storage
      emptyDir: {}
```

### 2\. `pv.yaml` (Static `hostPath` PV)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: block-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  # Note: hostPath is for single-node demo ONLY.
  hostPath:
    path: "/home/ubuntu/day29"
```

### 3\. `pvc.yaml` (Our Storage Request)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: block-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

### 4\. `pod-with-pvc.yaml` (Nginx Consuming the PVC)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-block-volume
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        # This name must match the PVC metadata.name
        claimName: block-pvc
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          # This name must match the volumes.name above
          name: task-pv-storage
```

-----

## 🧠 Command Line Practice

```bash
# --- Part 1: emptyDir Experiment ---

# Create the Redis pod
kubectl apply -f redis-pod.yaml

# Exec into the pod
kubectl exec -it redis-pod -- sh

# (Inside Pod) Install procps to use 'ps'
apt-get update && apt-get install procps -y

# (Inside Pod) Create a file in the volume
echo "hello from k8s" > /data/redis/hello.txt

# (Inside Pod) Find the redis process ID and kill it
ps -aux
pkill -9 <redis-user_id>

# (Inside Pod) The container restarts. Check if the file is still there:
ls /data/redis/
# It will be!

# (Exit Pod) Now, delete the Pod entirely
kubectl delete pod redis-pod

# Re-create the pod
kubectl apply -f redis-pod.yaml

# Exec back in and check for the file
kubectl exec -it redis-pod -- sh
ls /data/redis/
# It will be GONE!

# Clean up
kubectl delete pod redis-pod

# --- Part 2: PV/PVC Experiment ---

# (On Host) Create the hostPath directory
mkdir /home/ubuntu/day29
echo "Hello from Persistent Volume!" > /home/ubuntu/day29/index.html

# Apply the PV and PVC
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml

# Check the status - you should see them "Bound"
kubectl get pv,pvc

# Apply the Nginx pod that uses the PVC
kubectl apply -f pod-with-pvc.yaml

# Wait for the pod to be running
kubectl get pods

# Exec into the Nginx pod and test it
kubectl exec -it pod-with-block-volume -- curl localhost
# You should see "Hello from Persistent Volume!"
```

-----

## 💡 Pro Tip: `hostPath` vs. `StorageClass`

The `hostPath` volume we used is **NOT suitable for production**. It’s only for single-node demos because it ties the Pod to a specific node's filesystem.

In a real, multi-node cluster, you would use **Dynamic Provisioning**. Instead of manually creating a PV, you define a `StorageClass`. The `StorageClass` tells Kubernetes *how* to provision storage (e.g., "use `ebs.csi.aws.com` to create an AWS EBS volume").

When a user creates a PVC, they just specify the `storageClassName`, and Kubernetes automatically:

1.  Calls the cloud provider to create a new disk (e.g., an EBS volume).
2.  Creates a `PersistentVolume` (PV) for that disk.
3.  Binds the new PV to the user's `PersistentVolumeClaim` (PVC).

## 🏁 Final Thought

Kubernetes is all about declarative infrastructure — and storage is no exception. By mastering PVs, PVCs, and StorageClasses, you enable your cluster to manage data with the same flexibility and resilience as your workloads. Keep building, keep automating, and remember — in DevOps, persistence is power. 💪