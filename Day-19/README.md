
-----

# Day 19: Kubernetes ConfigMaps & Secrets 🛠️

Welcome back\! On Day 11, we looked at `env` variables defined directly inside a container. That works, but it's not ideal.

What happens when you have 10 pods that all need to know the same database URL? Or when you want to change a setting without rebuilding your container image?

This is where **ConfigMaps** come in. We separate our configuration from our application.

-----

## 🧐 What is a ConfigMap?

A **ConfigMap** is a Kubernetes object used to store non-sensitive configuration data in key-value pairs.

Think of it as an external "settings file" for your application that lives inside your Kubernetes cluster. Your Pods can then "read" from this object when they start up.

**The core idea:** Decouple configuration from your container image. This lets you:

  * Use the same container image in different environments (dev, staging, prod) just by pointing it to a different ConfigMap.
  * Update configuration without rebuilding and redeploying your entire application.
  * Share one configuration among many different Pods.

### 💡 Real-Life Analogy: The Restaurant Menu

Imagine your application is a **Chef** (your Pod/Container).

  * **The Bad Way (env):** You tattoo the recipe directly onto the Chef's arm (`DB_HOST=localhost`). If the recipe changes (e.g., you run out of salt), you have to... get a new Chef? That's crazy.
  * **The Good Way (ConfigMap):** The recipe is on a **Menu** (the `ConfigMap`) posted on the kitchen wall.
      * The Chef (Pod) just reads the menu (`valueFrom: configMapKeyRef`) when they start their shift.
      * If the recipe changes, you just update the menu (apply the `ConfigMap`). The next Chef that starts (a new Pod) will automatically read the new recipe.
      * Multiple Chefs (Pods) can all read from the same menu.

-----

## 🤫 A Quick Note: ConfigMap vs. Secret

The title mentions Secrets, so let's be clear:

  * 🔑 **ConfigMap:** For **non-sensitive** data. Think of database hosts, port numbers, URLs, feature flags, or logging levels. The data is stored in plain text (technically Base64, which is *not* encryption).
  * 🔒 **Secret:** For **sensitive** data. Use this for API keys, database passwords, and TLS certificates. Kubernetes handles Secrets with more care (e.g., storing them in `tmpfs` in memory on nodes where possible).

**Rule of thumb:** If you wouldn't be comfortable pasting it into a public chat, use a **Secret**.

-----

## 1\. How to Create ConfigMaps

There are two main ways to create a ConfigMap.

### A. The Imperative Way (Quick & Easy) 🏃‍♂️

You create it directly from the command line. This is great for quick tests.

**Command:** `kubectl create configmap <configmap-name> [data-source]`

**Source 1: `--from-literal`**
Use this for simple key=value pairs.

```bash
# The \ just lets you break the command onto multiple lines
kubectl create configmap app-cm \
  --from-literal=FIRST_NAME=Gaurav \
  --from-literal=LAST_NAME=Halnawar
```

**Source 2: `--from-file`** (A very common pattern\!)
Use this to grab configuration from an existing file.

```bash
# 1. First, create a file
echo "ENV=production" > config.properties
echo "API_URL=https://api.prod.space9cloud.com" >> config.properties

# 2. Now, create a ConfigMap from that file
# This will create a key named "config.properties" with the file's content as the value
kubectl create configmap app-config-file --from-file=config.properties
```

### B. The Declarative Way (Best Practice) 📄

This is the **recommended** way for real projects. You define the ConfigMap in a YAML file and check it into Git (this is GitOps\!).

**Step 1:** Use `kubectl create ... --dry-run=client -o yaml` to generate the file for you.

```bash
kubectl create configmap custom-cm \
  --from-literal=firstname=gaurav \
  --from-literal=lastname=halanwar \
  --from-literal=course=devops \
  --dry-run=client -o yaml > custom-cm.yaml
```

**Step 2:** Your `custom-cm.yaml` file will look like this. You can also just write this file by hand.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-cm
data:
  # These are your key-value pairs
  firstname: gaurav
  lastname: halanwar
  course: devops
```

**Step 3:** Apply the file to your cluster.

```bash
kubectl apply -f custom-cm.yaml
```

You can check that it was created:

```bash
kubectl get configmap custom-cm -o yaml
```

-----

## 2\. How to Use ConfigMaps in a Pod

Creating a ConfigMap is useless unless your Pods can read it. Here are the **three main ways** to use them.

Let's assume we are using the `custom-cm` (declarative) we just created.

### Method 1: Inject a Single Key as an Environment Variable

This is what your original example showed. You map one specific key from the ConfigMap to one specific environment variable in the container.

**Use Case:** You need to map the ConfigMap key `firstname` to an environment variable named `APP_USER_NAME`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod
spec:
  containers:
    - name: my-app-container
      image: busybox:1.28
      command: ['sh', '-c', 'echo "App is running..." && echo "My name is $FIRST_NAME $LAST_NAME" && sleep 3600']
      env:
        # --- This is the first variable ---
        - name: FIRST_NAME # This is the name of the env var INSIDE the container
          valueFrom:
            configMapKeyRef:
              name: custom-cm     # The name of your ConfigMap
              key: firstname     # The key you want to get from the ConfigMap
        # --- This is the second variable ---
        - name: LAST_NAME
          valueFrom:
            configMapKeyRef:
              name: custom-cm
              key: lastname
```

**To test this:**

1.  `kubectl apply -f pod.yaml`
2.  `kubectl logs my-app-pod`
3.  **Output:** `App is running...` and `My name is gaurav halanwar`
4.  **This is key:** Inside the container, you *must* use `echo $FIRST_NAME`, not `echo $firstname`. You defined the mapping.

### Method 2: Inject *All* Keys as Environment Variables (envFrom)

This is a very powerful method. It takes *every key* in the ConfigMap and turns it into an environment variable.

**Use Case:** You have 20 keys in your ConfigMap and don't want to write 20 `env` blocks.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod-envfrom
spec:
  containers:
    - name: my-app-container
      image: busybox:1.28
      command: ['sh', '-c', 'echo "App is running..." && echo "User: $firstname $lastname, Course: $course" && sleep 3600']
      envFrom:
      - configMapRef:
          name: custom-cm # The name of your ConfigMap
```

**To test this:**

1.  `kubectl apply -f pod-envfrom.yaml`
2.  `kubectl logs my-app-pod-envfrom`
3.  **Output:** `App is running...` and `User: gaurav halanwar, Course: devops`
4.  **This is key:** With `envFrom`, the environment variable name **is** the key name from the ConfigMap. So here, you *must* use `echo $firstname`, not `echo $FIRST_NAME`. This is what your original notes were trying to explain\!

### Method 3: Mount the ConfigMap as a Volume (Files) 📁

This is the most flexible method, especially for old applications that expect to read configuration from a file (like `nginx.conf`, `settings.py`, or `log4j.properties`).

**Use Case:** You want your application to read its config from `/etc/config/firstname` and `/etc/config/lastname`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod-volume
spec:
  containers:
    - name: my-app-container
      image: busybox:1.28
      command: ['sh', '-c', "echo 'Reading config files...' && cat /etc/app-config/firstname && cat /etc/app-config/lastname && sleep 3600"]
      volumeMounts: # <-- 2. Mount the volume into the container
      - name: config-volume
        mountPath: /etc/app-config # The directory inside the container
  volumes: # <-- 1. Define the volume at the Pod level
    - name: config-volume
      configMap:
        name: custom-cm # The name of your ConfigMap
        # Each key in the ConfigMap (firstname, lastname, course)
        # will become a file in the /etc/app-config directory.
```

**To test this:**

1.  `kubectl apply -f pod-volume.yaml`
2.  `kubectl exec my-app-pod-volume -- ls /etc/app-config`
3.  **Output:** `course firstname lastname` (You'll see the keys as filenames\!)
4.  `kubectl logs my-app-pod-volume`
5.  **Output:** `Reading config files...` followed by `gaurav` and `halanwar`.