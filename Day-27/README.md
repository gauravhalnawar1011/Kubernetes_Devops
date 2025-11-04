
---

# 🚀 Kubernetes Cluster Setup on AWS EC2 (Ubuntu 22.04)

This repository provides a **step-by-step guide** to deploy a Kubernetes cluster (v1.29.6) using `kubeadm`, `containerd`, and Calico networking on **AWS EC2** instances running **Ubuntu 22.04 LTS**.

The setup includes:

* 1 Control Plane node
* 2 Worker Nodes
* Container runtime: **containerd**
* Network plugin: **Calico**

---

## 📋 Prerequisites

Before you begin, ensure that:

* You have **3 EC2 instances** (1 control plane + 2 workers) running **Ubuntu 22.04**.
* All instances are in the **same VPC/Subnet** for private IP connectivity.
* Security groups allow:

  * `6443/tcp` (API Server)
  * `10250–10255/tcp` (Kubelet)
  * `8472/udp`, `4789/udp` (CNI, VXLAN)
  * SSH (`22/tcp`)
* You have SSH access to each instance using a key pair.
* Each node has a unique hostname (e.g., `control-plane`, `worker-1`, `worker-2`).

---

## ⚙️ Setup Overview

### 🧩 Step 1: Connect to Instances

SSH into each node from your local terminal:

```bash
# Control Plane
ssh -i <key.pem> ubuntu@<control-plane-public-ip>

# Worker 1
ssh -i <key.pem> ubuntu@<worker1-public-ip>

# Worker 2
ssh -i <key.pem> ubuntu@<worker2-public-ip>
```

---

### 🚀 Step 2: System Configuration (All Nodes)

Run these commands on **all nodes** (control plane + workers):

```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

Verify:

```bash
lsmod | grep br_netfilter
lsmod | grep overlay
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```

---

### 🧱 Step 3: Install and Configure `containerd`

Run on **all nodes**:

```bash
# Install containerd
curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz

# Configure systemd service
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Verify
systemctl status containerd
```

---

### 🧰 Step 4: Install `runc` and CNI Plugins

```bash
# Install runc
curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# Install CNI plugins
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz
```

---

### 🧩 Step 5: Install Kubernetes Components

Run on **all nodes**:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes APT repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1 \
  --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl

# Verify versions
kubeadm version
kubelet --version
kubectl version --client
```

---

### 🔧 Step 6: Configure CRI Socket

```bash
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
```

---

### 🧠 Step 7: Initialize the Control Plane (Only on Control Plane Node)

Use your **private IP address** for the `--apiserver-advertise-address` flag.

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=<control-plane-private-ip> \
  --node-name control-plane
```

When initialization completes, note the `kubeadm join` command printed in the output — you’ll need it for the worker nodes.

---

### 📁 Step 8: Configure `kubectl` for the Admin User

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

### 🌐 Step 9: Install Calico Network Plugin

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
kubectl apply -f custom-resources.yaml
```

Wait until all pods in the `kube-system` and `calico-system` namespaces are `Running`:

```bash
kubectl get pods -A
```

---

### ⚙️ Step 10: Join Worker Nodes

On **each worker node**, use the `kubeadm join` command printed from the control plane output, e.g.:

```bash
sudo kubeadm join <control-plane-private-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

If you lost the command, recreate it on the control plane:

```bash
kubeadm token create --print-join-command
```

---

### ✅ Step 11: Verify the Cluster

On the control plane:

```bash
kubectl get nodes -o wide
```

Expected output:

```
NAME             STATUS   ROLES           AGE   VERSION   INTERNAL-IP
control-plane    Ready    control-plane   2m    v1.29.6   <private-ip>
worker-1         Ready    <none>          1m    v1.29.6   <private-ip>
worker-2         Ready    <none>          1m    v1.29.6   <private-ip>
```

---

## 📦 Optional: Bash Automation

For automation, you can create `master-setup.sh` and `worker-setup.sh` scripts containing these commands, then run them with:

```bash
bash master-setup.sh
bash worker-setup.sh
```

---

## 🧩 Troubleshooting

* Check systemd services:

  ```bash
  systemctl status containerd kubelet
  ```
* View logs:

  ```bash
  journalctl -xeu kubelet
  ```
* Verify networking:

  ```bash
  kubectl get pods -A -o wide
  ```

---

## ☁️ Production Notes

For production environments:

* Use **AWS EKS** or another managed Kubernetes service.
* Implement **Cluster Autoscaler** for node scaling.
* Use **Horizontal Pod Autoscaler (HPA)** for pod-level scaling.
* Store configurations and manifests in **Git (GitOps)**.
* Automate provisioning with **Terraform + Packer + Ansible**.

---

## 📘 References

* [Kubernetes Official Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
* [Containerd Installation Guide](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
* [Project Calico Documentation](https://projectcalico.docs.tigera.io/)
* [Cluster Autoscaler on AWS](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)

---
