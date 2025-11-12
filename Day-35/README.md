
---

# Day 35 – ETCD Backup and Restore (Kubernetes Cluster)

## 🧩 Overview

ETCD is the **key-value store** used by Kubernetes to persist all cluster state data — including pods, secrets, config maps, and more.
Taking regular ETCD backups ensures you can **restore your cluster** in case of data corruption, accidental deletion, or during major upgrades.

---

## 📚 Why Not Just `kubectl get all`?

While commands like:

```bash
kubectl get all
kubectl get all -A
kubectl get all -A -o yaml > backup.yaml
```

can export cluster objects, this is **not a complete backup**.
They don’t include PersistentVolumes (PVs), PersistentVolumeClaims (PVCs), or other resources not stored as Kubernetes objects.

A true backup requires copying the **ETCD datastore**, since it holds all Kubernetes state data.

---

## 💾 What We Need to Back Up

We need to back up:

* The **ETCD database** (`/var/lib/etcd`)
* The **certificates** used by ETCD (typically under `/etc/kubernetes/pki/etcd`)

If we have these, we can restore the entire cluster state.

> 📘 Note: On **managed clusters** (EKS, AKS, GKE), you **don’t have direct access** to ETCD.
> In that case, use third-party tools like **[Velero](https://velero.io)** for backups and restores.

---

## ⚙️ ETCD Configuration Path

On a self-managed cluster, you can find ETCD configuration at:

```bash
cd /etc/kubernetes/manifests
cat etcd.yaml
```

Important configuration flags inside `etcd.yaml`:

| Flag                                                                 | Description                          |
| -------------------------------------------------------------------- | ------------------------------------ |
| `--data-dir=/var/lib/etcd`                                           | Directory where ETCD stores its data |
| `--listen-client-urls=https://127.0.0.1:2379,https://<NODE-IP>:2379` | Client access endpoints              |
| `--cert-file=/etc/kubernetes/pki/etcd/server.crt`                    | Server certificate                   |
| `--key-file=/etc/kubernetes/pki/etcd/server.key`                     | Server private key                   |
| `--peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt`             | CA certificate for ETCD peers        |
| `image: registry.k8s.io/etcd:3.6.4-0`                                | ETCD version used                    |

The ETCD pod mounts two key volumes:

```yaml
volumeMounts:
  - mountPath: /var/lib/etcd
    name: etcd-data
  - mountPath: /etc/kubernetes/pki/etcd
    name: etcd-certs
```

---

## 🧰 Installing ETCDCTL Utility

To interact with ETCD directly, install the client utility:

```bash
sudo apt install etcd-client -y
```

Set the ETCD API version (v3 is required):

```bash
export ETCDCTL_API=3
```

---

## 🗂️ Taking an ETCD Snapshot

Use the following command to take a backup snapshot:

```bash
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/etcd-backup.db
```

> 📁 The backup file should always have a `.db` extension.

Verify the backup file:

```bash
ls -lh /opt/etcd-backup.db
du -sh /opt/etcd-backup.db
```

Check the backup status in table format:

```bash
etcdctl --write-out=table snapshot status /opt/etcd-backup.db
```

Example output:

```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| fe01cf57 |       10 |          7 | 2.1 MB     |
+----------+----------+------------+------------+
```

---

## 🔄 Restoring from an ETCD Snapshot

If data is lost or corrupted, restore the cluster as follows:

```bash
etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore-from-backup
```

This creates a new restored data directory:

```
/var/lib/etcd-restore-from-backup
```

---

## 🧩 Updating ETCD Configuration

After restoring, modify `etcd.yaml` to point to the new restored data directory.

Update:

```yaml
- --data-dir=/var/lib/etcd-restore-from-backup
```

Also update the `volumes` section if needed:

```yaml
volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd-restore-from-backup
      type: DirectoryOrCreate
    name: etcd-data
```

---

## 🚀 Restarting ETCD and Kubelet

Once configuration is updated, restart the ETCD pod and services:

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Alternatively, if using static pod manifests:

```bash
cd /etc/kubernetes/manifests
sudo mv *.yaml /tmp/
sudo mv /tmp/*.yaml .
```

This triggers a **pod restart** managed by the kubelet.

---

## 🧾 Summary

| Action              | Command                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------- |
| Install ETCD client | `sudo apt install etcd-client -y`                                                           |
| Set API version     | `export ETCDCTL_API=3`                                                                      |
| Take snapshot       | `etcdctl snapshot save /opt/etcd-backup.db`                                                 |
| Verify snapshot     | `etcdctl snapshot status /opt/etcd-backup.db --write-out=table`                             |
| Restore snapshot    | `etcdctl snapshot restore /opt/etcd-backup.db --data-dir=/var/lib/etcd-restore-from-backup` |
| Restart kubelet     | `sudo systemctl restart kubelet`                                                            |

---

## 🔐 Notes

* Always back up **ETCD** before:

  * Cluster upgrades
  * Major version upgrades
  * Before applying large-scale configuration changes
* Keep snapshots in **secure, versioned storage** (e.g., S3, Git, or NAS).
* Use **Velero** for managed clusters or multi-cloud environments.

---

## ✅ Best Practice

Automate ETCD backups with a **cron job** on the control plane node or via a CI/CD pipeline, ensuring you always have recent cluster state snapshots.

---
