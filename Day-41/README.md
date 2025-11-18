
-----

# ☸️ Ultimate CKA Exam Preparation Guide & Cheatsheet

  

> **Note:** This repository serves as a quick reference guide and study companion for the **Certified Kubernetes Administrator (CKA)** exam. It is based on the latest curriculum (v1.30+) and includes video notes, hands-on tasks, and strategic tips to help you pass on your first attempt.

-----

## 📚 Table of Contents

  - [Exam Logistics & Preparation](https://www.google.com/search?q=%23-exam-logistics--preparation)
  - [The Exam Environment](https://www.google.com/search?q=%23-the-exam-environment)
  - [DevOps Specialist Strategy](https://www.google.com/search?q=%23-devops-specialist-strategy-tips--tricks)
  - [Linux & Vim Cheatsheet](https://www.google.com/search?q=%23-linux--vim-cheatsheet)
  - [Sample Exam Tasks (Memory Bank)](https://www.google.com/search?q=%23-sample-exam-tasks-memory-bank)
  - [Contributing](https://www.google.com/search?q=%23-contributing)

-----

## 📋 Exam Logistics & Preparation

Before you dive into the CLI, ensure your administrative house is in order.

  * **💰 Registration & Discounts:** Look for **25-40% discounts** (often available during Cyber Monday or KubeCon). If a discount isn't active, wait a few weeks if possible.
  * **💻 Format:** Online proctored exam. You can take it from home.
  * **📖 Critical Resources:**
      * **[Official Exam Guide](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2):** Read this to understand the domain weights.
      * **[Preparation Checklist](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-preparation-checklist):** Complete this before scheduling.
      * **[Exam Rules & Policies](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-rules-and-policies):** Don't get disqualified for a minor rule violation.
      * **[Official FAQs](https://docs.linuxfoundation.org/tc-docs/certification/tips-cka-and-ckad):** Answers to common logistical questions.

### 🛠️ Practice Labs

1.  **Killer.sh:** After registering, you get **2 free sessions**. These are *harder* than the real exam. Use them to build speed.
2.  **Killercoda:** Free scenarios to practice specific topics.
3.  **User Interface:** Familiarize yourself with the [Exam UI](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams) so you don't waste time figuring out the browser on exam day.

-----

## 🖥️ The Exam Environment

You will be working in a Remote Desktop environment inside your browser.

  * **OS:** Ubuntu Virtual Machine.
  * **K8s Version:** Latest (Currently v1.30 as of July 2024).
  * **Documentation:** You have access to one browser tab for `kubernetes.io/docs`, `kubernetes.io/blog`, and related subdomains.

### ⚠️ The "Copy & Paste" Trap

The terminal inside the browser is a **Linux Terminal Emulator**. Standard Windows/Mac shortcuts often fail.

| Action | Terminal Shortcut | External App (Browser/Notepad) |
| :--- | :--- | :--- |
| **Copy** | `Ctrl` + `Shift` + `C` | `Ctrl` + `C` |
| **Paste** | `Ctrl` + `Shift` + `V` | `Ctrl` + `V` |

> **Pro Tip:** You can also use the Right-Click context menu, but learning the keyboard shortcuts will save you precious seconds.

-----

## 🧠 DevOps Specialist Strategy: Tips & Tricks

Passing isn't just about knowledge; it's about **time management**.

### 1\. The "Imperative First" Rule

Never write a YAML file from scratch if you can avoid it. Use `kubectl` to generate the skeleton.

```bash
# Save this alias immediately upon starting the exam
export do="--dry-run=client -o yaml"

# Usage example: Create a pod yaml without creating the pod
kubectl run nginx --image=nginx $do > nginx.yaml
```

### 2\. Master `kubectl explain`

Don't browse the web docs for every field. Use the built-in documentation to find spec definitions quickly.

```bash
# Forgot how to define a PersistentVolume?
kubectl explain pv.spec.capacity
```

### 3\. Context Switching is Critical

**You will fail if you execute commands in the wrong cluster.**
Every question starts with a context command (e.g., `kubectl config use-context k8s`).

  * **Habit:** Read the question ➝ **Copy Context Command** ➝ **Paste in Terminal** ➝ Read the rest of the question.

### 4\. Time Management Algorithm

  * **Tier 1 (Quick Wins):** Simple Pods, Scaling, Node Troubleshooting. Do these immediately.
  * **Tier 2 (Process Heavy):** ETCD Backup, Upgrades. Do these mid-exam.
  * **Tier 3 (Complex/Unknown):** Network Policies, intricate JSONPath. Bookmark and do these last.

-----

## ⌨️ Linux & Vim Cheatsheet

You need to edit YAML fast. Here are the essential shortcuts.

### Bash Setup

Setup an alias for kubectl to save typing:

```bash
alias k=kubectl
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
```

### Vim Shortcuts

| Key | Action |
| :--- | :--- |
| `i` | Insert mode |
| `Esc` | Exit Insert mode |
| `:wq!` | Save and Quit (Force) |
| `:q!` | Quit without saving |
| `dd` | Delete current line |
| `u` | Undo |
| `Shift` + `g` | Jump to end of file |
| `o` | Insert new line below current |
| `A` | Insert at end of current line |

-----

## 📝 Sample Exam Tasks (Memory Bank)

*Based on exam experiences from July 2024.*

1.  **Node Selection:** Check the number of schedulable nodes (excluding those with `NoSchedule` taints) and write the count to a file.
2.  **Scaling:** Scale a specific deployment to 4 replicas.
3.  **Network Policy:** Create a policy allowing access *only* from `pod: nginx` (dev namespace) to `pod: redis` (test namespace).
4.  **ETCD Backup/Restore:**
      * Backup ETCD to `/etc/backup`.
      * Restore from a provided snapshot file at `/var/lib/etcd_bkp`.
5.  **Service Exposure:** Expose an existing deployment as a `NodePort` service on port `8080`.
6.  **Log Analysis:** Monitor pod logs for the string `error-not-found` and pipe the specific lines to a file.
7.  **Metric Filtering:** Identify pods with label `env=xyz`, find the one with the highest CPU utilization, and write its name to a file.
8.  **Multi-Container Pods:** Create a pod containing both `redis` and `memcached` containers.
9.  **InitContainers:** Edit an existing pod to add an `initContainer` (using `busybox`) that runs a specific setup command.
10. **Node Troubleshooting:** Fix a worker node in `NotReady` state (requires SSH access). Ensure the fix persists after reboot.
11. **RBAC:** Create a ClusterRole, ClusterRoleBinding, and ServiceAccount allowing creation of Deployments, Services, and DaemonSets in the `test` namespace.
12. **Maintenance:** Mark a node as unschedulable (cordon) and evict its pods (drain) to other nodes.
13. **Manual Scheduling:** Create a pod and manually assign it to `worker01` (using `nodeName` in spec).
14. **Ingress:** Create an Ingress resource (See: [Day 33 Task](https://github.com/piyushsachdeva/CKA-2024/blob/main/Resources/Day33/task.md)).
15. **Storage:**
      * Create a PV (1Gi, ReadWriteOnce, no StorageClass).
      * Create a PVC (500Mi, ReadWriteOnce) that binds to the PV.
      * Mount this PVC to a pod at `/data`.
16. **StatefulSet:** Scale a statefulset from 2 to 5 replicas.
17. **Cluster Upgrade:**
      * Drain controlplane.
      * Upgrade components (kubeadm, kubelet, kubectl, apiserver, etc.) from `v1.31.0` to `v1.31.1`.
      * **Note:** Do not upgrade etcd or CNI unless specified. Uncordon when done.
18. **Deployment Updates:** Update a deployment's port and Environment Variables, then expose via `NodePort` 30007.
19. **Scoped RBAC:** Grant permission to a cluster-wide resource, but restrict the permission scope to a specific namespace (Hint: Use RoleBinding with a ClusterRole).
20. **PVC Resizing:** Create a 10Mi PVC, mount it to `/var/new-vol`. Then, edit and resize the PVC to 50Mi.
21. **Sidecar Logging:** Given a pod, add a sidecar container that tails logs from a shared volume (`/var/log`) used by the main container.

-----

## 🤝 Contributing

We welcome contributions from the community\! If you have recently taken the exam and have new tips or non-NDA breaking task examples:

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/NewTips`).
3.  Commit your changes.
4.  Push to the branch.
5.  Open a Pull Request.

Good luck with your exam\! **You've got this.** 🚀

-----
