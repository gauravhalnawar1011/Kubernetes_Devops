
-----

# Day 07: Understanding YAML and Pods in Kubernetes 

Welcome to Day 7\! Today, we'll dive into the core concepts of Kubernetes: **Pods** and the language we use to define them, **YAML**. Throughout this series, YAML will be the primary way we define our Kubernetes objects.

-----

## Creating Pods: Imperative vs. Declarative

In Kubernetes, there are two primary methods for creating resources like Pods:

  * **Imperative Approach:** You directly tell the Kubernetes API what to do by running commands. This is great for quick tests, learning, and one-off tasks. Think of it as giving direct orders.
  * **Declarative Approach:** You write a configuration file (a "manifest") that describes the *desired state* of your system. You then tell Kubernetes to make the cluster match the state defined in your file. This is the standard for production environments because it's version-controllable, repeatable, and scalable.

For our journey, we'll use the **imperative** way for quick learning and the **declarative** way for building robust, production-ready configurations.

-----

## The Imperative Approach: Quick Pod Creation

Let's create an Nginx Pod imperatively. This involves using the `kubectl run` command.

**Command:**

```bash
kubectl run nginx-pod --image=nginx
```

This command tells Kubernetes to create a Pod named `nginx-pod` using the official `nginx` container image from Docker Hub.

**Verify the Pod's Status:**
To check if our Pod is running, we use `kubectl get pods`.

```bash
kubectl get pods
```

**Output:**

```
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          88m
```

Let's break down the output:

  * **NAME:** The name of our Pod (`nginx-pod`).
  * **READY:** Shows `1/1`, which means 1 container is running out of the 1 container defined in the Pod. This can be `n/m` if there are multiple containers.
  * **STATUS:** The current phase of the Pod. `Running` is what we want to see\!
  * **RESTARTS:** The number of times the container(s) within the Pod have been restarted. `0` indicates a healthy, stable container.
  * **AGE:** How long the Pod has been running.

-----

## The Declarative Approach: Using YAML

For production, we use configuration files. While Kubernetes supports JSON, **YAML** is heavily preferred due to its readability.

### YAML Basics

YAML (YAML Ain't Markup Language) is a human-friendly data serialization standard. Here's why it's great for Kubernetes:

  * **Clean and Readable:** Its indentation-based structure is easy to read.
  * **Comments:** You can add comments using the `#` symbol to explain your configuration.
  * **Data Types:** It supports key data types like strings, integers, lists (arrays), and dictionaries (maps/objects).

**YAML Data Structure Example:**
YAML uses key-value pairs. A list is denoted by a dash (`-`).

```yaml
# This is a dictionary (or map)
employee:
  name: Gaurav
  age: 24
  address: xyz

# This is a list of dictionaries
employees:
  - name: devops
    age: 24
    address: xyz
  - name: Gaurav
    age: 24
    address: xyzt
```

### Creating a Pod with a YAML Manifest

A Pod manifest is a YAML file that describes the Pod's desired state.

**`pod-definition.yaml`**

```yaml
# API version for the Pod object
apiVersion: v1
# The kind of object we are creating
kind: Pod
# Data that helps uniquely identify the object
metadata:
  name: my-nginx-pod
  labels:
    env: test
    type: frontend
# The specification of the Pod's desired state
spec:
  containers:
  - name: nginx-container
    image: nginx
    ports:
    - containerPort: 80
```

To create the Pod from this file, you use the `kubectl apply` command:

```bash
kubectl apply -f pod-definition.yaml
```

**Key Fields in the Manifest:**

  * **`apiVersion`**: Specifies which version of the Kubernetes API to use to create this object. You can find the correct version for an object with `kubectl explain <object_type>`.
  * **`kind`**: The type of Kubernetes object you want to create (e.g., `Pod`, `Deployment`, `Service`).
  * **`metadata`**: Information about the object, such as its `name` and `labels`. Labels are key-value pairs that are crucial for organizing and selecting objects.
  * **`spec`**: The most important section, defining the desired state. For a Pod, this includes the list of `containers` to run. Each container needs an `image` and a `name`.

-----

## Troubleshooting Common Pod Issues

What happens if you make a mistake, like specifying an image that doesn't exist?

Let's say we change the image name in our YAML from `nginx` to `nginx12345`. When we apply this, the Pod will be created, but the container will fail to start.

If you run `kubectl get pods`, you might see a status like `ErrImagePull` or `ImagePullBackOff`.

To find out what went wrong, use `kubectl describe pod <pod_name>`:

```bash
kubectl describe pod my-nginx-pod
```

In the `Events` section at the bottom, you'll see messages that explain the problem:

```
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  1m                   default-scheduler  Successfully assigned default/pod to worker-node-1
  Normal   Pulling    20s (x3 over 70s)    kubelet            Pulling image "nginx12345"
  Warning  Failed     18s (x3 over 60s)    kubelet            Failed to pull image "nginx12345": rpc error: code = Unknown desc = failed to pull and unpack image...
  Warning  Failed     18s (x3 over 60s)    kubelet            Error: ErrImagePull
  Normal   BackOff    5s (x4 over 60s)     kubelet            Back-off pulling image "nginx12345"
  Warning  Failed     5s (x4 over 60s)     kubelet            Error: ImagePullBackOff
```

This clearly shows the cluster is trying, and failing, to pull an image named `nginx12345`. To fix this, you would correct the image name in your YAML file and run `kubectl apply -f pod-definition.yaml` again.

-----

## Smart Work: Generating YAML from Commands 💡

Writing YAML from scratch can be time-consuming. You can generate a basic manifest using an imperative command with a couple of special flags.

  * `--dry-run=client`: Tells `kubectl` not to actually create the resource, but to print what it *would* have created.
  * `-o yaml`: Specifies the output format as YAML.

**Command to Generate YAML:**

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
```

You can directly save this output to a file:

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml > new-pod.yaml
```

You can even generate JSON if you prefer:

```bash
kubectl run nginx --image=nginx --dry-run=client -o json > new-pod.json
```

This gives you a great starting template that you can then modify for your specific needs.

-----

## Inspecting Pods and Using Labels

Beyond `get` and `describe`, here are more useful commands for inspecting your resources.

  * **View Pod Labels:**
    Labels are powerful for grouping resources. For example, you can find all your `frontend` pods.

    ```bash
    kubectl get pods --show-labels
    ```

  * **Get Extended Information:**
    Use the `-o wide` flag to see more details, like the Pod's IP address and the **Node** it's scheduled on.

    ```bash
    kubectl get pods -o wide
    ```

    **Output:**

    ```
    NAME           READY   STATUS    RESTARTS   AGE   IP          NODE           NOMINATED NODE   READINESS GATES
    my-nginx-pod   1/1     Running   0          10m   10.244.1.5  worker-node-1  <none>           <none>
    ```

You can use the same `-o wide` flag on other resources, like nodes:

```bash
kubectl get nodes -o wide
```