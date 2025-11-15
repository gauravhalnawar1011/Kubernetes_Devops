
---

# **Day 38 – Kubernetes Control Plane Troubleshooting**

Clarity is essential: this guide explains troubleshooting steps in a clean, simple, and beginner-friendly manner—no matter your prior Kubernetes experience.

---

## **Overview**

On Day 38, we focused on diagnosing and fixing common **Control Plane issues** in a Kubernetes cluster.
When `kubectl` fails, or workloads get stuck, the root cause is often tied to one of the key control-plane components:

* **kube-apiserver**
* **kube-scheduler**
* **kube-controller-manager**

This guide documents real troubleshooting scenarios and their solutions.

---

# **1. Troubleshooting kube-apiserver Issues**

### **❗ Problem**

Running:

```bash
kubectl get nodes
```

Returned:

```
The connection to the server 172.167.31.68:6443 was refused – did you specify the right host or port?
```

Since `kubectl` interacts **first** with the **kube-apiserver**, connection refusal means the API server is not running or misconfigured.

---

## **1.1 Check API Server Container**

Since Kubernetes v1.34 uses **containerd**, not Docker:

```bash
crictl ps | grep api
```

* Docker (`docker ps`) showed nothing
* `crictl ps -a` showed API server container existed, but exited

Check logs:

```bash
crictl logs <container_id>
```

If logs are missing:

```bash
cd /var/log/containers
```

No logs ⇒ container exited and logs rotated.

---

## **1.2 Inspect kube-apiserver Manifest**

Static pod manifests live at:

```
/etc/kubernetes/manifests/
```

Opening the file revealed a typo in the API server name (extra `r` in `kubeapi-server`).
After fixing the YAML, kubelet automatically recreated the pod and the API server became healthy.

### **Verification**

```bash
kubectl get nodes
```

Result:

```
NAME                               STATUS   ROLES           AGE   VERSION
cluster-custom-cni-control-plane   Ready    control-plane   12d   v1.34.0
cluster-custom-cni-worker          Ready    <none>          12d   v1.34.0
cluster-custom-cni-worker2         Ready    <none>          12d   v1.34.0
```

---

# **2. kubeconfig Troubleshooting**

Sometimes the API server is healthy but `kubectl` still errors.
The reason is often the **wrong kubeconfig file**.

### **Check the kubeconfig path**

```bash
cd $HOME/.kube
ls
```

If you’ve set a wrong kubeconfig:

```bash
export KUBECONFIG=/tmp/config
```

You will get connection errors.

---

## **Fix kubeconfig**

Use the default admin kubeconfig:

```
/etc/kubernetes/admin.conf
```

Run:

```bash
kubectl get nodes --kubeconfig /etc/kubernetes/admin.conf
```

To make this your default:

```bash
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
```

---

# **3. Troubleshooting kube-scheduler Issues**

### **Scenario**

Creating a pod:

```bash
kubectl run nginx --image=nginx
```

Pod stayed in **Pending** state.

Describing the pod:

```bash
kubectl describe pod nginx
```

* No node assigned
* No scheduler events

### **Conclusion:** kube-scheduler is not working.

---

## **3.1 Check scheduler pod**

```bash
kubectl get pods -n kube-system
```

Scheduler was in:

```
ErrImagePull
```

Check logs:

```bash
kubectl logs <kube-scheduler-pod> -n kube-system
```

Check events:

```bash
kubectl describe pod <kube-scheduler-pod> -n kube-system
```

Fix the image name/path in the static pod manifest.

Once fixed, scheduler becomes healthy, and pods begin scheduling normally.

---

# **4. Troubleshooting kube-controller-manager Issues**

### **Scenario**

You delete a pod from a Deployment expecting Kubernetes to recreate it, but it never comes back.

The component responsible for maintaining desired state = **kube-controller-manager**.

Checking:

```bash
kubectl get pods -n kube-system
```

It showed:

```
CrashLoopBackOff
```

---

## **4.1 Debug controller-manager**

```bash
kubectl logs <kcm-pod> -n kube-system
kubectl describe pod <kcm-pod> -n kube-system
```

Common issues:

* Typos in manifest YAML
* Wrong volume mounts
* Missing cert files
* Incorrect host paths

Fix the manifest:

```
/etc/kubernetes/manifests/kube-controller-manager.yaml
```

After correction, deployments became functional again.

---

# **5. Certificate-Related Issues**

Scaling a deployment:

```bash
kubectl scale deploy/nginx --replicas=4
```

If it fails again, controller-manager likely has **certificate mount issues**.
Check volume mounts in the manifest.

Fix cert path issues → scaling works correctly.

---

# **6. Useful Cluster Diagnostics**

### **Cluster info**

```bash
kubectl cluster-info
```

### **Full cluster dump**

```bash
kubectl cluster-info dump
```

---

# **Conclusion**

On Day-38, we covered real-world troubleshooting steps for Kubernetes control plane components:

* Fixing misconfigured **kube-apiserver**
* Correcting kubeconfig issues
* Resolving **kube-scheduler** failures
* Diagnosing **kube-controller-manager** crash loops
* Inspecting certificates and manifest paths

Understanding how each control-plane component works—and how to inspect its logs and manifests—is essential for keeping a Kubernetes cluster healthy.

---

