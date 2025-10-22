
# 🐳 Kubernetes: Taints and Tolerations

This guide explains how Taints and Tolerations work in Kubernetes to control pod scheduling. This mechanism allows you to dedicate specific nodes to specific workloads by "tainting" the node, which repels pods, and then adding "tolerations" to the pods you *do* want to run there.

---

## 🧠 The Core Concept

Let’s see how this works with an example. Suppose you have 3 nodes in your cluster, and you want **Node 1** to be dedicated to running AI workloads.

Since this node has specialized hardware (like a GPU), you apply a **Taint** to it:
`GPU=true`

Now, when the Kubernetes scheduler tries to schedule a new pod, it will check the taints on all nodes.
* The scheduler sees that Node 1 has a `GPU=true` taint.
* If the pod does not have a matching **Toleration** for this taint, the scheduler will not place it on Node 1. It will be scheduled on another node instead.

To schedule our AI pod on Node 1, we must add a `toleration` to the pod's specification. This toleration allows it to be scheduled on the tainted node.

> 💡 **Key Idea:** Here, we are not *forcing* the pod to run on a particular node. Instead, we are *instructing the node* to only accept certain pods. This particular node will only accept pods that have the `GPU=true` toleration.

### Why do we do this?
We do this for many purposes. For example, the first node may be a bigger node—it has a GPU, more memory, and other resources—and we only want this node to specialize in AI workloads.

---

## 🧩 Key Definitions & Taint Effects

### Taints vs. Tolerations
* **Taint** → Applied on a **node**.
* **Toleration** → Applied on a **pod**.

Both use key-value pairs to define what taints or tolerations exist.

### Taint Effects
Taints also have an `effect`, which defines the scheduling behavior.

* **`NoSchedule`**
    * Affects **new pods only**.
    * The scheduler will not place any new pod on this node unless it has a matching toleration.

* **`NoExecute`**
    * Affects **both existing and new pods**.
    * Any pods *already running* on the node that do not tolerate this taint will be **evicted**.

* **`PreferNoSchedule`**
    * This is a "soft" preference, not a hard enforcement.
    * The scheduler will *try* to avoid placing pods without a toleration on this node, but it gives **no guarantee**.

---

## 🧪 Hands-On Example

Let's walk through a practical demo.

### 1. Taint the Nodes

First, check the available nodes in your cluster:
```bash
kubectl get nodes
````

Next, taint one of the worker nodes. We will use the key `gpu`, value `true`, and effect `NoSchedule`.

```bash
kubectl taint node <node_name> <key>=<value>:<effect>
```

Here is a specific example:

```bash
kubectl taint node space9-v2-worker gpu=true:NoSchedule
```

> 💡 **Tip:** You can get help for the taint command at any time:
> `kubectl taint node space9-v2-worker -h`

Let's apply the same taint to another worker node as well:

```bash
kubectl taint node space9-v2-worker2 gpu=true:NoSchedule
```

To verify the taints have been applied, describe the node and `grep` for "Taints":

```bash
kubectl describe node <node_name> | grep -i taint
```

You should see the `gpu=true:NoSchedule` taint listed.

### 2\. Observe a Pending Pod

Now that our worker nodes are tainted, let's try to create a standard `nginx` pod without any tolerations:

```bash
kubectl run nginx --image=nginx
```

Check the pod's status. You will see it is stuck in the `Pending` state:

```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   0/1     Pending   0          10s
```

To find out why, describe the pod:

```bash
kubectl describe po/nginx
```

> ⚠️ **Error Message:** In the "Events" section, you’ll see a `FailedScheduling` warning with a message like this:
> `Warning: FailedScheduling — 1 node (control-plane) already tainted, and 2 worker nodes are tainted.`

This confirms our taints are working and repelling the pod.

### 3\. Add a Toleration to a Pod

To schedule a pod on the tainted nodes, we must add a `tolerations` block to its specification.

Let's create a `pod.yaml` manifest for a Redis pod using `dry-run`:

```bash
kubectl run redis --image=redis --dry-run=client -o yaml > pod.yaml
```

Now, edit the `pod.yaml` file. Inside the `spec` section (at the same level as the `containers` block), add the following `tolerations` block:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis
  labels:
    run: redis
spec:
  # Add the tolerations block here
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - image: redis
    name: redis
    # ... other container specs
```

Then, apply the new manifest:

```bash
kubectl apply -f pod.yaml
```

Check the pods again. The `redis` pod should now be running successfully because it "tolerates" the taint.

```bash
kubectl get pods -o wide
# NAME    READY   STATUS    RESTARTS   AGE   IP           NODE               ...
# nginx   0/1     Pending   0          5m    <none>       <none>
# redis   1/1     Running   0          15s   10.244.1.5   space9-v2-worker   ...
```

### 4\. Remove the Taint from a Node

To remove a taint, you use the same command but add a minus sign (`-`) at the end of the taint definition.

Let's remove the taint from `space9-v2-worker2`:

```bash
kubectl taint node space9-v2-worker2 gpu=true:NoSchedule-
```

*(Note the `-` at the end)*

Now, the scheduler can use this node freely. After a few moments, the `nginx` pod (which was `Pending`) will be scheduled successfully.

```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          8m
# redis   1/1     Running   0          3m
```

-----

## ⚙️ A Note on Node Selectors

We also have `nodeSelector`, which helps the pod decide which node it should run on. We do this using labels on nodes and matching them from the pod spec.

At the same level as the `containers` spec in your pod YAML, you would add:

```yaml
nodeSelector:
  gpu: "false"
```

This requires you to first add a matching label to a node:

```bash
kubectl label node <node_name> gpu=false
```

Check the pods again, and the `nginx` pod (if configured with this `nodeSelector`) should be scheduled properly on the labeled node.

-----

## 🧭 Comparison: Taints/Tolerations vs. NodeSelector

Here is the fundamental difference:

  * **Taints and Tolerations**

      * These work as **restrictions applied on nodes**.
      * → The **node decides** what type of pods it can accept.

  * **NodeSelector**

      * This works as an **instruction from the pod**.
      * → The **pod decides** which node it should go to.

> 💡 **Limitation:** `NodeSelector` is limited—it doesn’t support logical operators (like `AND` / `OR`) or multiple conditional matches.
>
> For advanced matching, we use **Node Affinity and Anti-Affinity**, which we’ll cover soon.

```
```