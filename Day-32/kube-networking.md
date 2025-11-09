
---

## 🔍 What Happens When a Pod Runs — Understanding Network Namespaces

When a Pod is created in Kubernetes, multiple containers can share the same **network namespace**, enabling them to communicate using `localhost`. The **pause container** is responsible for holding this shared namespace.

Below is an example Pod specification with two containers sharing a single network namespace.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-namespace
spec:
  containers:
    - name: p1
      image: busybox
      command: ['/bin/sh', '-c', 'sleep 10000']
    - name: p2
      image: nginx
```

---

### 🧠 Step-by-Step: Inspecting Pod Network Namespaces

#### 1️⃣ List all network namespaces

```bash
ip netns list
```

---

#### 2️⃣ Identify the Pause Container

Create a simple Pod and check which process holds the network namespace:

```bash
kubectl run nginx --image=nginx
lsns | grep nginx
```

Copy the **process ID (PID)** from the output and run:

```bash
lsns -p <pid>
```

This will show all namespaces associated with the process — look for the `net` namespace.

---

#### 3️⃣ List All Network Namespace Files

Each namespace is represented under `/var/run/netns`:

```bash
ls -lt /var/run/netns
```

---

#### 4️⃣ Inspect Interfaces Inside a Specific Namespace

You can inspect the interfaces inside any namespace using:

```bash
ip netns exec <namespace> ip link
```

Alternatively, inspect from within the Pod:

```bash
kubectl exec -it shared-namespace -- ip addr
```

---

#### 5️⃣ Trace veth Pairs

When inspecting the Pod’s network interfaces, you’ll see something like:

```
eth0@if9
```

The number after `@` (e.g., `9`) refers to the **peer interface index** on the host.
To locate it, run:

```bash
ip link | grep -A1 ^9
```

You’ll find the corresponding veth pair on the node — this represents the connection between the **Pod’s network namespace** and the **host network bridge**, managed by the CNI plugin.

---

## 🧰 Additional Network Inspection Commands

1. **List all network interfaces on the host**

   ```bash
   ip link show
   ```

2. **List all network namespaces**

   ```bash
   sudo ip netns list
   ```

3. **Inspect interfaces within a specific namespace**

   ```bash
   sudo ip netns exec <namespace> ip link
   ```

4. **Find veth pairs created by the CNI plugin**

   ```bash
   ip link show | grep cali
   ```

5. **Verify veth pair statistics**

   ```bash
   sudo ethtool -S <interface>
   ```

---

### 🧩 Example Workflow

```bash
# 1. List interfaces on the host
ip link show

# 2. List all network namespaces
sudo ip netns list

# 3. Inspect a specific namespace
sudo ip netns exec cni-6bbf75c3-3284-407a-5869-90772afb5472 ip link

# 4. Find veth pairs (Calico example)
ip link show | grep cali

# 5. Inspect veth statistics
sudo ethtool -S caliede2c6f02d9
```

These commands together let you trace the **network path** from your Pod → veth pair → bridge → host → and finally the **CNI-managed virtual network**.

---

