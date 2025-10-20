
# Day 13 — Static Pods & Scheduling

A guide to understanding how Kubernetes schedules pods, with a focus on static pods, manual scheduling, labels, and selectors. This covers the core mechanisms that ensure your cluster's control plane runs reliably and how you can influence pod placement.

---

## Why This Matters

* **Control-Plane Reliability:** Understand how essential components like the API server and scheduler run without depending on the scheduler itself.
* **Debugging:** Learn to diagnose why pods are stuck in a `Pending` state, which often points to scheduler or kubelet issues.
* **Scheduling Behavior:** Gain insight into the default scheduling flow and learn how to override it for specific use cases using manual assignments.

---

## Overview: The Scheduling Flow

When you create a Pod using `kubectl`, the request first hits the **API Server**, which validates it and stores the new object's definition in **etcd**. The **Scheduler**, constantly watching the API Server for unscheduled pods (in the `Pending` state), selects the best Node for the Pod based on resource requirements and other constraints. Finally, the scheduler updates the Pod object in etcd with the chosen Node name, and the **kubelet** on that specific Node creates and runs the Pod's containers.

---

## Static Pods

Static Pods are managed directly by the **kubelet** daemon on a specific node, without the API server observing them. Kubernetes' own control-plane components (etcd, API server, controller manager, and scheduler) run as static pods to solve the "chicken-and-egg" problem—they must run for the cluster to function, but they cannot be scheduled by a scheduler that isn't yet running.

The `kubelet` on a control-plane node continuously watches a local directory, typically `/etc/kubernetes/manifests`, for pod definition files. Any YAML or JSON manifest placed in this directory is automatically run as a pod on that node.

Typical manifests found here include:
* `etcd.yaml`
* `kube-apiserver.yaml`
* `kube-controller-manager.yaml`
* `kube-scheduler.yaml`

---

### Example: Static Pod Manifest

Here is a minimal snippet of a static pod manifest for the `kube-scheduler`. The kubelet reads this file from `/etc/kubernetes/manifests/kube-scheduler.yaml` and ensures the pod is always running on the control-plane node.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    # ... additional arguments
    image: registry.k8s.io/kube-scheduler:v1.28.2
    name: kube-scheduler


-----

## Manual Scheduling

You can bypass the scheduler entirely and manually assign a Pod to a specific Node by setting the `spec.nodeName` field in the Pod's manifest. This is useful for specific workloads that must run on a particular machine. The key limitation is that once a Pod is assigned this way, it cannot be moved by Kubernetes; it is bound to that node for its entire lifecycle.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-manual
spec:
  containers:
  - name: nginx
    image: nginx
  nodeName: worker-node-01 # Manually assigns this pod to 'worker-node-01'
```

-----

## Labels & Selectors

**Labels** are key-value pairs attached to Kubernetes objects, such as Pods, to organize and select subsets of objects. **Selectors** are used in other objects (like Services or ReplicaSets) to identify which Pods they should manage.

  * Get all pods with the label `env=production`:
    ```bash
    kubectl get pods --selector env=production
    ```
  * Get all pods with the label `app=nginx` across all namespaces:
    ```bash
    kubectl get pods --all-namespaces --selector app=nginx
    ```

-----

## Annotations

**Annotations** are also key-value pairs used to attach arbitrary non-identifying metadata to objects. They are useful for storing information for tools and libraries, such as build timestamps, release IDs, or contact information for the person who deployed the resource.

```yaml
metadata:
  name: my-app
  annotations:
    "kubernetes.io/created-by": "admin-user"
    "build-version": "1.4.2"
```

-----

## Troubleshooting

If the scheduler is missing or broken, you'll notice specific symptoms:

  * **Symptoms:** Newly created pods remain indefinitely in the `Pending` state. When you `describe` the pod, the `Node` field is blank and there are no scheduling-related events.
  * **Checks:**
    1.  Verify the static pod manifests exist: `ls /etc/kubernetes/manifests`.
    2.  Check the `kubelet` service status on the control-plane node: `systemctl status kubelet`.
    3.  Confirm the control-plane pods are running: `kubectl get pods -n kube-system`.
  * **Quick Fixes:** If a manifest file like `kube-scheduler.yaml` was accidentally deleted, restore it from a backup. If `kubelet` is down, restart it.

-----

## Useful Commands

```bash
# List control-plane static pods
kubectl get pods -n kube-system

# Inspect a pod to check its status and events
kubectl describe pod <pod-name> -n kube-system

# View static pod manifests on the control-plane node
ls /etc/kubernetes/manifests

# Find pods using a specific label
kubectl get pods --selector key=value
```

-----

## Further Reading

  * [Kubernetes Documentation - Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
  * [Kubernetes Documentation - Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
  * [Kubernetes Documentation - Scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)

-----

Try it yourself—check `/etc/kubernetes/manifests` on a control-plane node\!

```
```