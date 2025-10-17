````markdown
#  laboratorio 🧪 Day 11: Multi-Container Pods in Kubernetes

A deep dive into using multiple containers within a single Kubernetes Pod, focusing on the distinct roles and behaviors of **Init Containers** and **Sidecar Containers**.

---

## 💡 What are Multi-Container Pods?

In Kubernetes, a **Pod** is the smallest deployable unit and can contain one or more containers. While single-container pods are common, multi-container pods are a powerful pattern where containers share the same network namespace, IPC namespace, and storage volumes.

This co-location allows them to communicate efficiently (e.g., via `localhost`) and share files, enabling patterns that separate concerns and extend functionality without modifying the primary application's code.

---

## 🆚 Init Containers vs. Sidecar Containers

While both are types of containers that run within a pod alongside the main application container(s), they serve very different purposes and have distinct lifecycles.

### Init Containers
An **Init Container** is a specialized container that runs and **must complete successfully** before the main application containers are started. They are perfect for performing prerequisite tasks.

* **Lifecycle**:
    * Runs sequentially. If multiple Init Containers are defined, they execute one after the other.
    * The next Init Container only starts after the previous one has exited successfully.
    * All Init Containers must run to completion before any app container is started.
    * If an Init Container fails, the Pod is restarted (respecting the Pod's `restartPolicy`) until it succeeds.
* **Use Cases**:
    * **Pre-flight Checks**: Waiting for a dependent service (like a database or API) to become available.
    * **Setup Tasks**: Running a database migration script, preparing configuration files, or downloading necessary assets.
    * **Permissions**: Modifying filesystem permissions or setting up necessary directory structures in a shared volume.
    * **Security**: Injecting secrets into a configuration file that the main application will read.

### Sidecar Containers
A **Sidecar Container** runs **alongside** the main application container for the entire life of the Pod. It's designed to augment or enhance the functionality of the primary container. As of Kubernetes v1.29, sidecars are officially supported by setting `restartPolicy: Always` on an init container, which makes it behave like a sidecar.

* **Lifecycle**:
    * Starts before the main application container but continues to run concurrently with it.
    * Shares the entire lifecycle of the Pod; if the Pod is running, the sidecar is running.
    * Can be restarted independently of the main application container.
* **Use Cases**:
    * **Logging**: A logging agent that collects logs from the main app and forwards them to a centralized logging system.
    * **Monitoring**: An agent that gathers metrics from the application and exposes them to a monitoring system like Prometheus.
    * **Service Mesh**: A proxy (like Envoy or Linkerd) that handles all inbound and outbound network traffic for service discovery, retries, and circuit breaking.
    * **File Syncing**: A container that syncs files from a remote source (like a Git repository) into a shared volume for the main app to use.

### Comparison Table

| Feature            | Init Container                                        | Sidecar Container                                      |
| ------------------ | ----------------------------------------------------- | ------------------------------------------------------ |
| **Purpose**        | Perform setup or prerequisite tasks.                  | Enhance or extend the main application's functionality.|
| **Execution**      | Runs sequentially before the main app starts.         | Runs concurrently alongside the main app.              |
| **Lifecycle**      | Runs to completion. Must exit with code `0`.          | Runs for the entire lifetime of the Pod.               |
| **Probes**         | Does not support `livenessProbe` or `readinessProbe`. | Supports all probes (`liveness`, `readiness`, etc.).   |
| **Primary Goal**   | Delay the start of the main app until ready.          | Add auxiliary services to the main app.                |

---

## ⚙️ Lab 1: Init Container in Action

In this example, we have a Pod with two Init Containers (`init-service` and `mydb`) that must complete before the main application container (`my-appcontiner`) starts. These Init Containers use `nslookup` to wait for dependent services to be available.

### Manifest: `init-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-pod
  labels:
    name: init-pod
spec:
  containers:
    - name: my-appcontiner
      image: busybox:1.28
      command: ['sh','-c', 'echo "✅ Application is now running!" && sleep 3600']
  initContainers:
  - name: init-service
    image: busybox:1.28
    command: ['sh','-c']
    args: ['until nslookup myservice.default.svc.cluster.local; do echo "⏳ Waiting for myservice..."; sleep 2; done']
  - name: mydb
    image: busybox:1.28
    command: ['sh','-c']
    args: ['until nslookup my-db.default.svc.cluster.local; do echo "⏳ Waiting for my-db..."; sleep 2; done']
````

### Commands

1.  **Deploy the Pod**:

    ```bash
    kubectl create -f init-pod.yaml
    ```

2.  **Inspect the Pod's Status**: You will see the status as `Init:0/2` or `Init:1/2` as the Init Containers run. Use the `-w` flag to watch the changes.

    ```bash
    kubectl get pod init-pod -w
    # NAME       READY   STATUS     RESTARTS   AGE
    # init-pod   0/1     Init:0/2   0          2s
    # init-pod   0/1     Init:1/2   0          5s
    # init-pod   0/1     PodInitializing   0          8s
    # init-pod   1/1     Running           0          10s
    ```

3.  **Check Logs**: To see the output of a specific Init Container:

    ```bash
    # Check logs for the first init container
    kubectl logs init-pod -c init-service

    # Check logs for the main container (only after init containers succeed)
    kubectl logs init-pod -c my-appcontiner
    ```

4.  **Clean Up**:

    ```bash
    kubectl delete pod init-pod
    ```

-----

## ⚙️ Lab 2: Sidecar Container in Action

Here, we deploy an application that writes logs to a file in a shared volume. A sidecar container (`logshipper`) runs alongside it, reading from that same file and streaming the logs. This separates the logging logic from the application logic.

### Manifest: `sidecar-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  labels:
    app: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      # Main Application Container
      containers:
        - name: myapp-container
          image: alpine:latest
          command: ['sh', '-c', 'while true; do echo "Application is writing a log at $(date)" >> /opt/logs.txt; sleep 5; done']
          volumeMounts:
            - name: shared-logs
              mountPath: /opt
      # Sidecar Container (defined as a restartable Init Container)
      initContainers:
        - name: logshipper-sidecar
          image: alpine:latest
          restartPolicy: Always # This makes it a Sidecar
          command: ['sh', '-c', 'tail -F /opt/logs.txt']
          volumeMounts:
            - name: shared-logs
              mountPath: /opt
      # Shared Volume for both containers
      volumes:
        - name: shared-logs
          emptyDir: {}
```

### Commands

1.  **Deploy the Deployment**:

    ```bash
    kubectl create -f sidecar-deployment.yaml
    ```

2.  **Check Pod Status**: Verify that the Pod is running and shows `2/2` containers as ready.

    ```bash
    kubectl get pods
    # NAME                                READY   STATUS    RESTARTS   AGE
    # myapp-deployment-5f7b9b8b9c-xxxxx   2/2     Running   0          30s
    ```

3.  **Check Logs of the Main App**: This container doesn't output to `stdout`, it writes to a file.

    ```bash
    kubectl logs myapp-deployment-5f7b9b8b9c-xxxxx -c myapp-container
    # (Output will be empty)
    ```

4.  **Check Logs of the Sidecar**: This container tails the log file and streams it, effectively shipping the logs.

    ```bash
    kubectl logs myapp-deployment-5f7b9b8b9c-xxxxx -c logshipper-sidecar -f
    # Application is writing a log at Fri Oct 17 08:00:00 UTC 2025
    # Application is writing a log at Fri Oct 17 08:00:05 UTC 2025
    # ...
    ```

5.  **Exec into a Container**: You can enter either container to inspect the shared volume.

    ```bash
    # Get a shell inside the main application container
    kubectl exec -it <pod-name> -c myapp-container -- sh

    # Once inside, check the log file
    # / # cat /opt/logs.txt
    ```

6.  **Clean Up**:

    ```bash
    kubectl delete deployment myapp-deployment
    ```

-----

## 📝 Summary

  * **Multi-container pods** allow tightly coupled containers to share resources and work together.
  * **Init Containers** are for **setup tasks**. They run sequentially and must complete successfully *before* the main application starts.
  * **Sidecar Containers** are for **auxiliary services**. They run *alongside* the main application for its entire lifecycle.
  * Use **Init Containers** to block app startup until dependencies are ready or one-time tasks are done.
  * Use **Sidecar Containers** to offload responsibilities like logging, monitoring, and network proxying from your main application.

<!-- end list -->

