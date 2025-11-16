
---

# **Day-39 – Troubleshooting Worker Node Failure in Kubernetes**

Clarity is essential: this guide explains the troubleshooting process clearly and concisely, so anyone can follow it regardless of prior Kubernetes experience.

---

## **Overview**

Today we focused on diagnosing **worker node failures**—a common issue in Kubernetes clusters.
When worker nodes show a `NotReady` state, workloads cannot run, and pod scheduling stops.
This usually indicates problems with:

* The **CNI plugin** (networking)
* The **kubelet service**
* Node certificates or configuration

This guide covers how to systematically identify and fix these issues.

---

# **1. Detecting the Problem**

The first sign of node failure comes from:

```bash
kubectl get nodes
```

If worker nodes appear as **`NotReady`**, Kubernetes cannot communicate with them.

---

# **2. Step 1 – Verify CNI (Container Network Interface)**

Worker nodes require a CNI plugin (Calico, Flannel, Canal, etc.) for:

* Pod-to-Pod networking
* Node-to-Node communication
* Pod IP allocation

If the CNI is missing or broken, nodes often turn **NotReady**.

### **Check cluster-wide CNI pods**

```bash
kubectl get pods -A
kubectl get ds -A
kubectl get ns
```

Most CNIs run as **DaemonSets** in namespaces like:

* `kube-system`
* `calico-system`
* `kube-flannel`

### **Check the CNI config directory**

On any node:

```bash
cd /etc/cni/net.d
ls
```

Typical files might include:

* `10-calico.conflist`
* `calico-kubeconfig`

If these files exist and the DaemonSet is healthy, CNI is likely not the issue.

---

# **3. Step 2 – Inspect the Kubelet Service**

The **kubelet** is the node’s local agent.
It reports node health to the API server and manages pods on that node.

A failed kubelet → node appears **NotReady**.

SSH into the worker node:

```bash
sudo service kubelet status
```

### Possible states:

* **inactive** → kubelet stopped
* **activating** → kubelet failing to start
* **failed** → configuration or certificate issue

---

# **4. Step 3 – Check Kubelet Logs**

If kubelet isn’t running, check logs using `journalctl`:

```bash
journalctl -u kubelet
```

Use:

* `Shift + G` → jump to the last line
* Look for log lines starting with:

  * **I** → Information
  * **E** → Error

Most kubelet startup failures come from:

* Wrong certificate paths
* Misconfigured kubelet config file
* Missing CA file

---

# **5. Step 4 – Fix Kubelet Configuration**

Kubelet config file is usually located at:

```bash
/var/lib/kubelet/config.yaml
```

Open it:

```bash
sudo vi /var/lib/kubelet/config.yaml
```

Cross-check any certificate paths shown in error logs.

### Certificate files live under:

```
/etc/kubernetes/pki/
```

Typical files:

* `ca.crt`
* `apiserver.crt`
* `apiserver-kubelet-client.crt`

If kubelet config references the wrong cert or wrong path, fix it.

---

# **6. Step 5 – Restart the Kubelet**

After correcting config:

```bash
sudo service kubelet restart
```

Then verify kubelet is active:

```bash
sudo service kubelet status
```

---

# **7. Step 6 – Validate From Control Plane**

Return to the control plane and check node health:

```bash
kubectl get nodes
```

If kubelet starts successfully and networking is fine, worker nodes should report as:

```
Ready
```

---

# **Conclusion**

On Day-39, we learned how to systematically troubleshoot worker node failures by:

* Verifying CNI installation and DaemonSets
* Checking kubelet status and logs
* Validating certificate paths
* Correcting kubelet configuration
* Restarting kubelet and confirming node health

Understanding how worker nodes communicate with the control plane is essential for maintaining a healthy Kubernetes cluster.

---

