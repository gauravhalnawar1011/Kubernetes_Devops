
---

# **Day-40 – JSONPath & Advanced kubectl Commands**

*Clarity is essential: this post is written to be simple, accurate, and beginner-friendly so anyone can understand Kubernetes JSON, JSONPath, and advanced kubectl output formatting.*

---

## 🧩 **What We Learned Today**

Day-40 focused on understanding:

* What JSON is in the context of Kubernetes
* How kubectl communicates with the API server
* How to extract specific fields using **JSONPath**
* How to format kubectl output using:

  * `-o json`
  * `-o yaml`
  * `-o jsonpath=…`
  * `-o custom-columns=…`
  * `--sort-by=…`

This day unlocks the real power behind kubectl:
👉 filtering
👉 sorting
👉 extracting exact fields
👉 generating reusable YAML/JSON

---

# 1. **What is JSON in Kubernetes?**

When you run:

```bash
kubectl get nodes
```

Here’s what actually happens behind the scenes:

1️⃣ kubectl sends a **GET request** to the **kube-apiserver**
2️⃣ kube-apiserver responds with a **JSON payload**
3️⃣ kubectl formats that JSON into a human-readable table

If you want to see the RAW response:

```bash
kubectl get nodes -o json
```

You can also view it in YAML:

```bash
kubectl get nodes -o yaml
```

Both contain **much more detail** than the normal `kubectl get` output.

---

# 2. **Generating JSON/YAML for Pods**

You can generate pod manifests using:

```bash
kubectl run nginx --image=nginx --dry-run=client -o json > pod.json
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
```

### Example JSON output:

```json
{
    "kind": "Pod",
    "apiVersion": "v1",
    "metadata": {
        "name": "nginx",
        "labels": { "run": "nginx" }
    },
    "spec": {
        "containers": [
            { "name": "nginx", "image": "nginx" }
        ],
        "restartPolicy": "Always",
        "dnsPolicy": "ClusterFirst"
    }
}
```

This helps you understand the Kubernetes object structure.

---

# 3. **Understanding JSON Structure**

In JSON:

* `{ }` represents a **dictionary/object**
* `[ ]` represents a **list/array**
* Everything starts from the **root object** (`$` in JSONPath)

Examples:

| Path                         | Meaning                                       |
| ---------------------------- | --------------------------------------------- |
| `$.metadata.labels`          | Access metadata labels                        |
| `$.spec.containers[0].image` | Get image of the first container              |
| `$.items[*].metadata.name`   | Get the name of all items (nodes, pods, etc.) |

---

# 4. **Using JSONPath with kubectl**

Extract labels:

```bash
kubectl get pod -o=jsonpath='{.items[0].metadata.labels}{"\n"}'
```

Extract a mount path:

```bash
kubectl get pod -o=jsonpath='{.items[0].spec.containers[0].volumeMounts[0].mountPath}{"\n"}'
```

---

# 5. **Hands-On with Nodes (JSONPath)**

Get raw JSON:

```bash
kubectl get nodes -o json
```

Print all node objects:

```bash
kubectl get nodes -o=jsonpath='{.items[*]}'
```

Get only node names:

```bash
kubectl get nodes -o=jsonpath='{.items[*].metadata.name}{"\n"}'
```

---

# 6. **Using Custom Columns**

You can format your own table output:

```bash
kubectl get nodes -o='custom-columns=Node:{.metadata.name}'
```

Node + IP:

```bash
kubectl get nodes -o='custom-columns=Node:{.metadata.name},IP:{.status.addresses[*].address}'
```

Sample output:

```
Node                               IP
cluster-custom-cni-control-plane   172.18.0.4
cluster-custom-cni-worker          172.18.0.2
cluster-custom-cni-worker2         172.18.0.3
```

---

# 7. **Sorting Output with kubectl**

Sort nodes alphabetically:

```bash
kubectl get nodes --sort-by=.metadata.name
```

Sort pods by creation time:

```bash
kubectl get pods --sort-by=.metadata.creationTimestamp
```

This is extremely useful for real-world debugging.

---

# 8. **When to Use JSON vs YAML**

| Format   | Use Cases                                       |
| -------- | ----------------------------------------------- |
| **JSON** | Raw API response, automation, scripting         |
| **YAML** | Editing manifests, writing configs, readability |

YAML = better for humans
JSON = better for machines

---

## 🎯 **Conclusion**

Day-40 unlocked powerful kubectl skills:

* Understanding the structure of Kubernetes API objects
* Extracting ONLY the fields you need
* Sorting and customizing kubectl output
* Working with JSON, YAML, and JSONPath

These are essential skills for:

* Debugging
* Automation
* Scripting
* Cluster exploration
* Writing controllers/operators

Mastering kubectl formatting takes your Kubernetes skills to the next level.

---

