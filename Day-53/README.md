
---

# Day-53 — Installing **CRI-Dockerd** Container Runtime on Kubernetes

This guide documents the installation and configuration of **CRI-Dockerd** as a container runtime for a Kubernetes cluster.
The steps were tested using the **KillerCoda CKA Playground**, which closely matches the Certified Kubernetes Administrator (CKA) exam environment.

---

## 🔗 Playground Environment

Use the following playground to practice:

👉 [https://killercoda.com/playgrounds/scenario/cka](https://killercoda.com/playgrounds/scenario/cka)

Once logged in, validate the Kubernetes cluster status.

```bash
kubectl get nodes
```

Expected output:

```
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   10d   v1.34.1
node01         Ready    <none>          10d   v1.34.1
```

Check Docker service status:

```bash
sudo systemctl status docker
```

---

## 📦 Step 1: Download CRI-Dockerd

CRi-Dockerd packages are published by Mirantis:

🔗 [https://github.com/Mirantis/cri-dockerd/releases](https://github.com/Mirantis/cri-dockerd/releases)

Download the latest `.deb` package:

```bash
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.21/cri-dockerd_0.3.21.3-0.debian-bookworm_amd64.deb
```

Verify the file is downloaded:

```bash
ls
```

You should see:

```
cri-dockerd_0.3.21.3-0.debian-bookworm_amd64.deb
```

---

## 📥 Step 2: Install CRI-Dockerd

Install using `dpkg`:

```bash
sudo dpkg -i cri-dockerd_0.3.21.3-0.debian-bookworm_amd64.deb
```

---

## 🛠 Step 3: Enable & Start the CRI-Dockerd Service

Enable the service to ensure it starts during system boot:

```bash
sudo systemctl enable --now cri-docker.service
```

Start the service:

```bash
sudo systemctl start --now cri-docker.service
```

Check service status:

```bash
sudo systemctl status cri-docker.service
```

---

## ⚙️ Step 4: Configure Kernel Parameters

Create Kubernetes-required sysctl settings:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.netfilter.nf_conntrack_max = 131072
net.ipv6.conf.all.forwarding = 1
net.ipv4.ip_forward = 1
EOF
```

Apply changes without reboot:

```bash
sudo sysctl --system
```

Reload systemd to ensure updates are applied:

```bash
sudo systemctl daemon-reload
```

---

## ✅ Verification

### 1. Check CRI-Dockerd Service

```bash
sudo systemctl status cri-docker.service
```

### 2. Check CRI-Dockerd Socket

```bash
sudo systemctl status cri-docker.socket
```

### 3. View CRI-Dockerd Logs (Live)

```bash
sudo journalctl -u cri-docker.service -f
```

---

## 🎉 Conclusion

You have successfully installed and enabled **CRI-Dockerd** as the container runtime on a Kubernetes cluster. This setup is essential for environments where Docker is used instead of containerd or CRI-O, and it closely aligns with exam scenarios in the CKA environment.

---


