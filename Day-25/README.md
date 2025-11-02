
-----

# Day 25: Kubernetes Service Accounts

Welcome to this guide on Kubernetes Service Accounts. This document provides a production-level overview of how Service Accounts function as the primary mechanism for authenticating workloads, integrating with RBAC, and enabling secure automation within your cluster.

---

## 1. 🔑 Overview

### What are Service Accounts?

A **Service Account** provides an identity for processes that run inside a Pod. Unlike a normal *User Account* (which is intended for a human), a Service Account is a non-human identity managed by Kubernetes and is namespaced.

When your application (running in a Pod) needs to interact with the Kubernetes API server—for example, to list other Pods, read ConfigMaps, or modify Deployments—it must first authenticate. The Service Account provides this identity, complete with a JSON Web Token (JWT) that is automatically mounted into the Pod.

### Difference: Human Users vs. Service Accounts

| Feature | Human User | Service Account |
| :--- | :--- | :--- |
| **Purpose** | Intended for a human operator (e.g., a DevOps engineer using `kubectl`). | Intended for a process or application (e.g., a CI/CD pipeline). |
| **Management** | Managed **externally** (e.g., OIDC, LDAP, client certificates). | Managed **internally** by the Kubernetes API. |
| **Scope** | Typically **Cluster-wide** (with permissions controlled by RBAC). | **Namespaced**. A Service Account belongs to a single namespace. |
| **Authentication** | External methods (certs, tokens from an IdP). | Internal methods (namespaced, auto-mounted JWT tokens). |

### Why are Service Accounts critical for CI/CD?

In a modern DevOps workflow, automation is key. A CI/CD pipeline (like a Jenkins, GitLab, or ArgoCD agent) often runs as a Pod *inside* the cluster. This agent needs permission to deploy applications, which means it must interact with the Kubernetes API.

You should **never** give a CI/CD pipeline a human user's credentials (e.g., your personal `~/.kube/config`). Instead, you create a dedicated Service Account for the pipeline, grant it the *minimum required permissions* via RBAC (e.g., "create Deployments in namespace `prod`"), and configure the pipeline's Pod to use that Service Account. This is the foundation of secure, in-cluster automation.

---

## 2. ⚙️ The Default Service Account

Kubernetes is helpful and automatically creates a Service Account named `default` in every new namespace.

* Any Pod created without a `serviceAccountName` specified in its manifest will automatically use the `default` Service Account from its own namespace.
* By default, this `default` account has very limited (and often no) permissions, following the principle of least privilege.

You can list all Service Accounts (SAs) in the current namespace:

```sh
# List all service accounts in the current namespace
$ kubectl get sa

NAME      SECRETS   AGE
default   0         120d
````

You can inspect the `default` SA to see its details.

```sh
# Describe the default service account
$ kubectl describe sa/default

Name:        default
Namespace:   default
Labels:      <none>
Annotations: <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
```

> **🛡️ Security Best Practice**
> Avoid using the `default` Service Account for your workloads. Always create a dedicated, minimally-privileged Service Account for each application or automation task. This makes it easier to grant specific permissions and audit activity.

-----

## 3\. ➕ Creating a Custom Service Account

Creating a custom SA is a one-line command. Let's create one for a hypothetical build-and-deploy agent.

```sh
# Create a new Service Account named 'build-sa'
$ kubectl create sa build-sa

serviceaccount/build-sa created
```

Let's verify its creation and inspect it:

```sh
# List SAs again to see the new one
$ kubectl get sa

NAME       SECRETS   AGE
build-sa   0         5s
default    0         120d

# Describe our new SA
$ kubectl describe sa/build-sa

Name:        build-sa
Namespace:   default
Labels:      <none>
Annotations: <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
```

Notice that, by default, it has no secrets attached and no permissions. It's a blank identity, ready for us to configure.

-----

## 4\. 📜 Service Account Tokens and Secrets

For a Service Account to be useful, it needs a **token**. This token is a JWT that the process uses as a "Bearer token" in its API requests.

> 💡 **Modern Practice (Kubernetes 1.24+)**
> In modern Kubernetes versions (1.24+), long-lived tokens in Secrets are no longer created automatically. Instead, the `kubelet` requests short-lived, auto-rotating tokens via the `TokenRequest` API and mounts them into Pods. This is far more secure.
>
> You should **avoid manually creating long-lived tokens** unless you have a specific legacy or external-service use case that cannot use the modern projection-based tokens.

However, if you must create a long-lived, non-expiring token (e.g., for an external service that needs to authenticate), you can still manually create a Secret of type `kubernetes.io/service-account-token` and link it.

Here is an example manifest for creating such a secret:

```yaml
# build-robot-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: build-robot-secret
  annotations:
    # This annotation links the secret to our Service Account
    kubernetes.io/service-account.name: build-sa
type: kubernetes.io/service-account-token
```

After applying this, the Kubernetes controller manager will populate the `data` field of this Secret with a `token` and `ca.crt`.

```sh
# Apply the manifest
$ kubectl apply -f build-robot-secret.yaml

# Get the secret (it may take a second to be populated)
$ kubectl get secret build-robot-secret -o yaml

apiVersion: v1
data:
  ca.crt: LS...=
  namespace: ZGVmYXVsdA==
  token: ZXl...=
kind: Secret
metadata:
  # ...
  name: build-robot-secret
  namespace: default
  # ...
type: kubernetes.io/service-account-token
```

-----

## 5\. 🚢 Image Pull Secrets

A common use case for Service Accounts is to grant Pods permission to pull container images from a **private registry** (like Docker Hub, AWS ECR, GCR, or Artifactory).

First, you create a secret of type `docker-registry`:

```sh
# Command to create a secret for a private Docker registry
$ kubectl create secret docker-registry my-private-repo-key \
    --docker-server=my.registry.com \
    --docker-username=my-user \
    --docker-password=my-password \
    --docker-email=my-user@example.com

secret/my-private-repo-key created
```

You can then link this secret to your Service Account. This tells Kubernetes, "Any Pod using the `build-sa` Service Account should automatically be given this key to pull images."

```sh
# Patch the service account to include the imagePullSecret
$ kubectl patch serviceaccount build-sa -p '{"imagePullSecrets": [{"name": "my-private-repo-key"}]}'

serviceaccount/build-sa patched
```

Now, any Pod that uses `serviceAccountName: build-sa` will automatically have the `imagePullSecrets` field populated, allowing it to pull images from `my.registry.com`.

-----

## 6\. 🔗 RBAC Integration

An identity (the Service Account) is useless without permissions. This is where **Role-Based Access Control (RBAC)** comes in.

We link a Service Account to permissions using three components:

1.  **ServiceAccount (The "Who"):** `build-sa`
2.  **Role (The "What"):** Defines *what* actions (verbs) are allowed on *what* resources. (e.g., "get", "list", "watch" on "pods").
3.  **RoleBinding (The "Link"):** Binds the "Who" (SA) to the "What" (Role).

Let's give our `build-sa` read-only access to Pods in the `default` namespace.

### Step 1: Create the Role

First, we define the permissions. We'll create a `Role` (which is namespaced) called `build-role`.

```sh
# Create a Role named 'build-role' that allows get/list/watch on pods
$ kubectl create role build-role --verb=get,list,watch --resource=pods

role.rbac.authorization.k8s.io/build-role created
```

### Step 2: Create the RoleBinding

Next, we bind our `build-sa` Service Account to the `build-role` Role.

```sh
# Create a RoleBinding named 'rb-build'
# It binds the 'build-role' Role to the 'build-sa' ServiceAccount
# We must specify the namespace of the SA (e.g., 'default')
$ kubectl create rolebinding rb-build --role=build-role --serviceaccount=default:build-sa

rolebinding.rbac.authorization.k8s.io/rb-build created
```

### Step 3: Validate Permissions

We can now use `kubectl auth can-i` to impersonate our Service Account and check its permissions. This is a critical debugging step.

The fully-qualified name for a Service Account is `system:serviceaccount:<namespace>:<name>`.

```sh
# Check: Can 'build-sa' get pods? (This should be 'yes')
$ kubectl auth can-i get pods --as=system:serviceaccount:default:build-sa

yes

# Check: Can 'build-sa' delete pods? (This should be 'no')
$ kubectl auth can-i delete pods --as=system:serviceaccount:default:build-sa

no
```

The "yes" and "no" responses confirm our least-privilege RBAC policy is working correctly.

-----

## 7\. 📦 Service Account in Pods

When a Pod is created, it's assigned a Service Account (either `default` or one specified by `serviceAccountName`).

The `kubelet` on the node where the Pod is scheduled then performs several actions:

1.  Requests a short-lived, auto-rotating token for the Service Account.
2.  Mounts this token as a **volume** into the Pod's container(s).
3.  The mount path is `  /var/run/secrets/kubernetes.io/serviceaccount/ `.

Let's look at a Pod manifest that uses our `build-sa`:

```yaml
# build-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: build-pod
spec:
  # This is the line that assigns the SA
  serviceAccountName: build-sa
  containers:
  - name: inspector
    image: busybox:latest
    command: ["sleep", "36000"]
```

After applying this, we can exec into the Pod and see the mounted credentials:

```sh
# Create the pod
$ kubectl apply -f build-pod.yaml

# Exec into the pod and list the contents of the token directory
$ kubectl exec build-pod -- ls -l /var/run/secrets/kubernetes.io/serviceaccount/

total 0
lrwxrwxrwx 1 root root 13 Oct 31 10:00 ca.crt -> ..data/ca.crt
lrwxrwxrwx 1 root root 16 Oct 31 10:00 namespace -> ..data/namespace
lrwxrwxrwx 1 root root 12 Oct 31 10:00 token -> ..data/token
```

  * `token`: The JWT token the application can read and use.
  * `ca.crt`: The cluster's CA certificate, used to verify the API server's identity.
  * `namespace`: The namespace of the Pod, for convenience.

This secure, volume-mounted approach means the token is **never** written to the container's disk or embedded in the image, and it's automatically rotated by Kubernetes.

-----

## 8\. 🧹 Cleanup Commands

To reset your environment, you can delete the resources we created.

```sh
# Delete the Pod
$ kubectl delete pod build-pod

# Delete the RoleBinding
$ kubectl delete rolebinding rb-build

# Delete the Role
$ kubectl delete role build-role

# Delete the Service Account
$ kubectl delete sa build-sa

# Delete the manual secret (if created)
$ kubectl delete secret build-robot-secret

# Delete the image pull secret (if created)
$ kubectl delete secret my-private-repo-key
```

-----

## 9\. 🌟 Key Takeaways & Best Practices

  * **Always use dedicated SAs:** Never use the `default` Service Account. Create a separate SA for each distinct application or CI/CD task.
  * **Embrace Least Privilege:** Always pair your SA with a `Role` or `ClusterRole` that grants *only* the permissions it needs. Start with zero permissions and add them one by one.
  * **Disable Auto-Mount:** If your application (e.g., a web server) does **not** need to talk to the Kubernetes API, disable automatic token mounting for better security.
      * Set `automountServiceAccountToken: false` in the Pod's spec.
  * **Avoid Static Tokens:** Do not manually create and export tokens from Secrets. Rely on the automatically mounted, short-lived tokens. If you must use a token externally, use `kubectl create token <sa-name>` to generate a short-lived one.
  * **Use `imagePullSecrets` on the SA:** For automation, link `imagePullSecrets` to the Service Account, not to individual Pods.

-----

## 📚 Further Reading

  * [Official Docs: Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
  * [Official Docs: Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
  * [Official Docs: Manage Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

<!-- end list -->

```
```