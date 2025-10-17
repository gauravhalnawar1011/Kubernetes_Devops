
-----

# Kubernetes Namespaces (Day 10)

Welcome to Day 10 of our Kubernetes series\! Today, we'll dive deep into **Namespaces**, a fundamental concept for organizing and isolating resources within a Kubernetes cluster.

## Why Do We Need Namespaces? 🤔

As a cluster grows, managing hundreds or thousands of resources can become chaotic. Namespaces provide a crucial layer of **logical isolation** within a single physical cluster. Think of them as virtual clusters or folders that allow you to group and separate your Kubernetes objects.

Key benefits include:

  * **Organization**: Group resources by team, project, or application (e.g., `dev`, `staging`, `prod` namespaces). This prevents naming collisions, as resource names only need to be unique *within* a namespace.
  * **Access Control**: Namespaces are a key part of Kubernetes security. You can apply Role-Based Access Control (RBAC) policies and resource quotas on a per-namespace basis, ensuring teams only have access to their own resources.
  * **Multi-Environment Support**: Easily run multiple development, staging, and production environments in the same cluster without them interfering with each other.

-----

## How Namespaces Work

A namespace provides a **scope for names**. When you create a namespaced object like a Pod, Deployment, or Service, it lives inside a specific namespace.

  * **Scoping**: The name of a resource must be unique within its namespace but not across the entire cluster. For example, you can have a `Deployment` named `nginx-deploy` in both the `dev` and `prod` namespaces.
  * **Default Behavior**: If you create an object without specifying a namespace, Kubernetes automatically places it in the `default` namespace.

> **Note:**
> Not all Kubernetes objects are namespaced. Cluster-wide resources like `Nodes`, `PersistentVolumes`, and `StorageClasses` do not belong to any namespace.

-----

## Initial Namespaces in a Cluster

When you set up a Kubernetes cluster, it starts with four initial namespaces:

| Namespace         | Purpose                                                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default`         | The default namespace for objects with no other namespace assigned. It's a starting point for users without needing to create a namespace first.                    |
| `kube-system`     | Reserved for objects created and managed by the Kubernetes system itself, such as control plane components. **Do not modify or create objects here.** |
| `kube-public`     | This namespace is readable by all users (including unauthenticated ones). It's mainly used to expose cluster information that should be publicly visible.          |
| `kube-node-lease` | Contains `Lease` objects for each node. Kubelets send heartbeats (leases) to the control plane from here to signal node health.                                     |

> **⚠️ Best Practice:**
> Avoid creating namespaces with the `kube-` prefix, as this is reserved for Kubernetes system namespaces.

-----

## Managing Namespaces with `kubectl` 🛠️

Here are the essential commands for working with namespaces.

### Viewing Namespaces

To see all namespaces in your cluster:

```bash
kubectl get namespace

# Abbreviated version
kubectl get ns
```

### Creating Namespaces

#### Imperative Command

The quickest way to create a namespace is with an imperative command.

```bash
# Creates a namespace named 'dev'
kubectl create namespace dev
```

#### Declarative YAML

For GitOps and infrastructure-as-code, it's best to define namespaces declaratively in a YAML file.

**`dev-namespace.yaml`**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

Apply it with:

```bash
kubectl apply -f dev-namespace.yaml
```

### Working with Objects in a Namespace

To run commands against a specific namespace, use the `--namespace` or `-n` flag.

```bash
# Create a deployment in the 'dev' namespace
kubectl create deployment nginx-deploy --image=nginx --namespace=dev

# Get pods from the 'dev' namespace
kubectl get pods -n dev
```

### Setting Your Namespace Preference

To avoid typing `-n <namespace>` for every command, you can set a default namespace for your current context.

```bash
# Set the current context to use the 'dev' namespace by default
kubectl config set-context --current --namespace=dev

# Verify the change
kubectl config view --minify | grep namespace:
```

-----

## Namespaces and DNS 🌐

Kubernetes has a built-in DNS service that is tightly integrated with namespaces. When you create a `Service`, it automatically gets a DNS entry.

The Fully Qualified Domain Name (FQDN) for a service follows this pattern:
`<service-name>.<namespace-name>.svc.cluster.local`

  * **Intra-Namespace Communication**: From a Pod, you can reach a Service in the *same namespace* by using just its short name (e.g., `curl <service-name>`).
  * **Cross-Namespace Communication**: To reach a Service in a *different namespace*, you **must** use its FQDN (e.g., `curl my-service.prod.svc.cluster.local`).

> ### 🔐 Security Warning: Avoid Public TLDs
>
> Do not create namespaces with names that match public Top-Level Domains (TLDs) like `com`, `org`, or `net`. If you create a namespace called `com` and a service called `example` within it, a DNS query for `example.com` from any pod in the cluster might resolve to your internal service instead of the public website. This can cause unexpected behavior and security vulnerabilities. Limit namespace creation privileges to trusted users to mitigate this risk.

-----

## Namespaced vs. Cluster-Wide Resources

It's critical to know which resources live inside a namespace and which are global.

### Namespaced Resources

These objects are isolated within a namespace.

  * Pods
  * Deployments
  * Services
  * ConfigMaps
  * Secrets
  * ReplicaSets
  * PersistentVolumeClaims

You can list all namespaced resource types with:

```bash
kubectl api-resources --namespaced=true
```

### Non-Namespaced (Cluster-Wide) Resources

These objects are global and visible across all namespaces.

  * Nodes
  * PersistentVolumes
  * StorageClasses
  * Namespaces (a namespace cannot be inside another namespace)
  * ClusterRoles

You can list all non-namespaced resource types with:

```bash
kubectl api-resources --namespaced=false
```

-----

## A Look Inside System Namespaces

### `kube-system`

This namespace is the brain of your cluster. It contains all the core control plane components.

| Component                 | Function                                                                           |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `coredns`                 | Handles DNS resolution for services and pods within the cluster.                   |
| `etcd`                    | The key-value store where all cluster state and configuration are stored.          |
| `kube-apiserver`          | The front-end for the control plane; exposes the Kubernetes API.                   |
| `kube-controller-manager` | Runs controller processes that regulate the state of the cluster.                  |
| `kube-scheduler`          | Watches for new pods and assigns them to a node to run on.                         |
| `kube-proxy`              | A network proxy that runs on each node, maintaining network rules.                 |
| `kindnet` (or other CNI)  | The Container Network Interface (CNI) plugin responsible for pod networking.       |

### `local-path-storage`

You may see this namespace in development clusters (like Kind or Minikube). It runs the `local-path-provisioner`, which automatically provisions `PersistentVolumes` using storage directories on the host node. This is useful for simple, dynamic stateful storage without needing a cloud provider.

-----

## Practical Example: Deploying and Communicating Across Namespaces

Let's see how DNS and namespaces work together.

**1. Create two namespaces: `dev` and `prod`**

```bash
kubectl create ns dev
kubectl create ns prod
```

**2. Create a deployment and service in `dev`**

```bash
# Create the NGINX deployment
kubectl create deployment nginx-web --image=nginx -n dev

# Expose it with a service
kubectl expose deployment nginx-web --port=80 -n dev
```

**3. Create a test pod in `prod`**

```bash
# Run a temporary busybox pod to act as a client
kubectl run tester --image=busybox -n prod --rm -it -- sh
```

**4. Attempt to communicate**
Inside the `tester` pod's shell (which is in the `prod` namespace):

```sh
# This will FAIL because 'nginx-web' does not exist in the 'prod' namespace
wget -qO- nginx-web

# Output:
# wget: bad address 'nginx-web'

# This will SUCCEED because we use the FQDN to specify the exact service and namespace
wget -qO- nginx-web.dev.svc.cluster.local

# Output:
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
```

**5.To check the FQDN inside pod**
```bash
cat /etc/resolv.conf
```
This demonstrates that Pod IPs are cluster-wide, but service discovery via short names is namespaced. Always use the FQDN for reliable cross-namespace communication.

-----

## ✅ Key Takeaways

  * **Isolate & Organize**: Namespaces are the primary tool for logical separation of resources in a multi-tenant or multi-environment cluster.
  * **Scoped by Default**: Most resources you create (Pods, Deployments, Services) are namespaced. If you don't specify one, they go into `default`.
  * **Cluster-Wide Resources**: Resources like Nodes and StorageClasses are global and not bound by namespaces.
  * **DNS is Key**: For services to communicate across namespaces, you **must use the Fully Qualified Domain Name (FQDN)**: `<service-name>.<namespace>.svc.cluster.local`.
  * **Security Boundary**: Combine namespaces with RBAC and ResourceQuotas to enforce security and resource limits for different teams or applications.