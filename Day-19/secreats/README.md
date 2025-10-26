
-----

# Day 19 (Part 2): Kubernetes Secrets 🔒

In the last guide, we learned about **ConfigMaps** for storing *non-sensitive* data. Now, let's talk about their critical counterpart: **Secrets**.

A **Secret** is a Kubernetes object used to store and manage **sensitive** information, such as passwords, OAuth tokens, API keys, and TLS certificates.

**The core idea:** Just like ConfigMaps, Secrets separate configuration from your Pods. However, Kubernetes treats Secrets differently to keep them secure:

  * The data is stored as Base64 (which is **encoding**, *not* encryption, but it prevents accidental viewing).
  * Kubernetes can store them in memory (`tmpfs`) on nodes instead of writing them to disk.
  * They are not shown in `kubectl describe` output by default.

### 💡 Real-Life Analogy: The Restaurant Safe

If a ConfigMap is the public **Menu** on the wall, a Secret is the **PIN code to the restaurant's safe**.

  * You would *never* write the PIN code on the public menu (don't put passwords in a ConfigMap).
  * You store the PIN securely (in a `Secret` object).
  * You only give the PIN to the trusted manager (your Pod) who needs it to open the safe (access the database).
  * When you give the PIN to the manager, you whisper it to them (inject as an env var) or give them a hidden note (mount as a volume). You don't shout it across the kitchen.

-----

## 1\. How to Create Secrets

There are two main ways to create a Secret.

### A. The Imperative Way (Quick & Easy) 🏃‍♂️

You create it directly from the command line. Kubernetes handles the Base64 encoding for you automatically.

**Command:** `kubectl create secret generic <secret-name> [data-source]`

**Source 1: `--from-literal`**
Use this for simple key=value pairs.

```bash
kubectl create secret generic db-secret \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASSWORD=MySuperSecretPassword123
```

**Source 2: `--from-file`** (Very common for `.env` files or certs)
This will use the filename as the key and the file's content as the value.

```bash
# 1. First, create your sensitive files
echo -n "postgres" > ./username.txt
echo -n "MySuperSecretPassword123" > ./password.txt

# 2. Now, create a Secret from those files
kubectl create secret generic db-secret-files \
  --from-file=./username.txt \
  --from-file=./password.txt

# This creates a secret with keys 'username.txt' and 'password.txt'
```

### B. The Declarative Way (Best Practice) 📄

This is the recommended way for GitOps, but it requires one extra step: **you must manually Base64 encode your values.**

**Step 1:** Manually encode your values.
**Important:** Use `echo -n` to avoid adding a newline character (`\n`) to your encoded string\!

```bash
# Encode the username
echo -n 'postgres' | base64
# Output: cG9zdGdyZXM=

# Encode the password
echo -n 'MySuperSecretPassword123' | base64
# Output: TXlTdXBlclNlY3JldFBhc3N3b3JkMTIz
```

**Step 2:** Create your `db-secret.yaml` file. Notice the `data` field (not `stringData`).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret-declarative
type: Opaque # This is the default type for key-value secrets
data:
  # These are your key-value pairs
  # The keys are plain text, but the values MUST be Base64 encoded
  DB_USER: cG9zdGdyZXM=
  DB_PASSWORD: TXlTdXBlclNlY3JldFBhc3N3b3JkMTIz
```

**Step 3:** Apply the file to your cluster.

```bash
kubectl apply -f db-secret.yaml
```

**How to check your secret:**
You can `get` the secret and decode the values to verify them.

```bash
# 1. Get the secret's YAML
kubectl get secret db-secret-declarative -o yaml

# 2. Copy one of the values and decode it
echo 'TXlTdXBlclNlY3JldFBhc3N3b3JkMTIz' | base64 --decode
# Output: MySuperSecretPassword123
```

-----

## 2\. How to Use Secrets in a Pod

This works **exactly like ConfigMaps**. Kubernetes **automatically decodes** the Base64 value before giving it to your container, so your application sees the plain-text password.

Let's use the `db-secret-declarative` we just made.

### Method 1: Inject a Single Key as an Environment Variable

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod-secret
spec:
  containers:
    - name: my-app-container
      image: busybox:1.28
      command: ['sh', '-c', 'echo "App is running..." && echo "My user is $DATABASE_USER" && echo "My password is $DATABASE_PASS" && sleep 3600']
      env:
        # --- This is the user variable ---
        - name: DATABASE_USER # Name of the env var INSIDE the container
          valueFrom:
            secretKeyRef:
              name: db-secret-declarative  # The name of your Secret
              key: DB_USER                # The key you want to get
        # --- This is the password variable ---
        - name: DATABASE_PASS
          valueFrom:
            secretKeyRef:
              name: db-secret-declarative
              key: DB_PASSWORD
```

**Result:** Inside the container, `echo $DATABASE_USER` will print `postgres`.

### Method 2: Inject *All* Keys as Environment Variables (envFrom)

This injects every key-value pair from the Secret as an environment variable. The key name becomes the variable name.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod-secret-envfrom
spec:
  containers:
    - name: my-app-container
      image: busybox:1.28
      command: ['sh', '-c', 'echo "User: $DB_USER" && echo "Pass: $DB_PASSWORD" && sleep 3600']
      envFrom:
      - secretRef:
          name: db-secret-declarative # The name of your Secret
```

**Result:** Inside the container, `echo $DB_USER` will print `postgres`.

### Method 3: Mount the Secret as a Volume (Files) 📁

This is often considered the **most secure method**. Instead of creating environment variables (which can sometimes be leaked in logs or error reports), this mounts the secret as files in an in-memory `tmpfs` volume.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod-secret-volume
spec:
  containers:
    - name: my-app-container
      image: busybox:1.28
      command: ['sh', '-c', "echo 'Reading secret files...' && echo 'User:' && cat /etc/db-secret/DB_USER && echo 'Pass:' && cat /etc/db-secret/DB_PASSWORD && sleep 3600"]
      volumeMounts: # <-- 2. Mount the volume into the container
      - name: secret-volume
        mountPath: /etc/db-secret # Directory inside the container
        readOnly: true
  volumes: # <-- 1. Define the volume at the Pod level
    - name: secret-volume
      secret:
        secretName: db-secret-declarative # The name of your Secret
```

**Result:**

  * A file named `DB_USER` is created at `/etc/db-secret/DB_USER`. Its content is `postgres`.
  * A file named `DB_PASSWORD` is created at `/etc/db-secret/DB_PASSWORD`. Its content is `MySuperSecretPassword123`.

Your application can now read its credentials directly from those files.