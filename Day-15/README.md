
-----

# Day 15: Deep Dive into Node Affinity and Anti-Affinity in Kubernetes

In this section, we’ll explore **Node Affinity** and **Anti-Affinity**, and understand how they provide more flexible and expressive scheduling options compared to Taints and Tolerations.

## 1\. Recap: Taints and Tolerations

First, let's recall **taints and tolerations**, which are mechanisms to control which pods can be scheduled on specific nodes (primarily for exclusion).

If a node has a taint:

```yaml
# Node is "tainted"
key=gpu, value=true, effect=NoSchedule
```

A pod must have a matching "toleration" to be scheduled on it:

```yaml
# Pod "tolerates" the taint
tolerations:
- key: "gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

However, taints and tolerations have limitations:

  * They don't allow for complex conditions (e.g., "this OR that").
  * They cannot express *preferences* (e.g., “prefer SSD nodes, but allow HDD if needed”).
  * They are better suited for *exclusion* rather than intelligent *placement*.

-----

## 2\. Introducing Node Affinity

**Node Affinity** solves these limitations by allowing expressive scheduling rules based on node labels. It tells the scheduler which nodes a pod *should* be scheduled on.

### Example Cluster

Let’s consider a cluster with 3 nodes, each with a `disk` label:

| Node | Label | Description |
| :--- | :--- | :--- |
| `node1` | `disk=hdd` | Standard storage |
| `node2` | `disk=ssd` | High-performance storage |
| `node3` | `disk=ssd` | High-performance storage |

We can now control pod placement with rules:

| Pod | Affinity Rule | Scheduling Behavior |
| :--- | :--- | :--- |
| **Pod A** | `disk != ssd` | Avoids SSD nodes, schedules on `node1`. |
| **Pod B** | `disk = ssd` | Runs only on SSD nodes (`node2` or `node3`). |
| **Pod C** | `disk in (ssd, hdd)` | Can run on any node with this label. |

### Required vs. Preferred

Node Affinity comes in two main types, which define how the scheduler enforces the rule:

| Property | Description | Impact |
| :--- | :--- | :--- |
| `requiredDuringSchedulingIgnoredDuringExecution` | **Hard Rule.** The pod will *only* be scheduled if the rule is met. | Strict placement. If no nodes match, the pod remains pending. |
| `preferredDuringSchedulingIgnoredDuringExecution` | **Soft Rule.** The scheduler *tries* to find a node that meets the rule. | Flexible preference. If no nodes match, the pod is scheduled on any available node. |

**Note:** The `IgnoredDuringExecution` part means that if a node's labels change *after* the pod is scheduled, the pod is **not** evicted.

### Example 1: Preferred Node Affinity (Soft Rule)

This pod *prefers* to run on a node with `disktype=hdd`, but it will run elsewhere if no such node is available.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-preferred
spec:
  containers:
  - name: redis
    image: redis
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - hdd
  restartPolicy: Always
```

### Example 2: Affinity Based on Label Existence

This pod prefers any node that simply *has* the `disktype` label, regardless of its value.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-exists
spec:
  containers:
  - name: redis
    image: redis
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: Exists
  restartPolicy: Always
```

-----

## 3\. Node Anti-Affinity

**Node Anti-Affinity** is the opposite: it defines where a pod should *not* run, allowing you to repel pods from nodes with specific labels.

### Example: Avoid a Specific Zone (Hard Rule)

Let's use a cluster with nodes labeled by availability zone:

| Node | Label |
| :--- | :--- |
| `node1` | `zone=us-east-1a` |
| `node2` | `zone=us-east-1b` |
| `node3` | `zone=us-east-1c` |

This manifest ensures the pod **will not** be scheduled in `us-east-1a`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-anti
spec:
  containers:
  - name: redis
    image: redis
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: zone
            operator: NotIn
            values:
            - us-east-1a
  restartPolicy: Always
```

### Example: Preferred Node Anti-Affinity (Soft Rule)

This manifest tells the scheduler to *try* to avoid `us-east-1a`, but it will schedule there if no other nodes are available.

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: zone
          operator: NotIn
          values:
          - us-east-1a
```

-----

## 4\. Pod Anti-Affinity (for High Availability)

While **Node Anti-Affinity** avoids nodes with certain *labels*, **Pod Anti-Affinity** avoids nodes where certain *pods* are already running.

This is critical for high availability (HA). You use it to ensure that replicas of your application (e.g., 3 Redis pods) don't all land on the same node, which would create a single point of failure.

### Example: HA Redis Deployment

This `Deployment` creates 3 Redis replicas and uses `podAntiAffinity` to ensure no two `app=redis` pods are placed on the same node.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-ha
spec:
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - redis
            topologyKey: "kubernetes.io/hostname"
```

**Explanation:**

  * `labelSelector`: This rule applies to any pod on the node that has the `app=redis` label.
  * `topologyKey: "kubernetes.io/hostname"`: This defines the "domain" for the anti-affinity rule. In this case, it's the node's hostname. It means "do not schedule this pod on any node (hostname) that is already running a pod with the label `app=redis`."

-----

## 5\. Summary & Key Takeaways

You can combine all these concepts for fine-grained scheduling control.

| Concept | Type | Behavior | Use Case |
| :--- | :--- | :--- | :--- |
| **Taints & Tolerations** | Hard Exclusion | Prevents *most* pods from landing on a node. | Dedicated GPU or infrastructure nodes. |
| **Node Affinity** | Hard/Soft Inclusion | Attracts pods to nodes with specific labels. | Schedule on SSDs or in a specific zone. |
| **Node Anti-Affinity** | Hard/Soft Exclusion | Repels pods from nodes with specific labels. | Avoid scheduling in a problematic zone. |
| **Pod Anti-Affinity** | Hard/Soft Exclusion | Prevents pods from co-locating on the same node. | **High Availability** for replicated apps. |

### Final Thoughts

  * **Taints/Tolerations** decide who *cannot* run on a node.
  * **Node Affinity** decides who *should* run on a node.
  * For production HA, **Pod Anti-Affinity** is the standard way to ensure replicas are spread across different nodes or zones for fault tolerance.
  * Always label your nodes meaningfully (`zone`, `disktype`, `role`, `env`, etc.)—these labels are the foundation of all affinity rules.