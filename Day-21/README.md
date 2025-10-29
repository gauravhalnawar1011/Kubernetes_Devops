
-----

### Day-21 

🧐 How do you securely onboard a new engineer to your Kubernetes cluster?

You **don't** just copy your `admin.conf` file\! 🛑

Let's talk about the right way: using **TLS** and **Certificate Signing Requests (CSRs)**. This is a core part of K8s security, authenticating users and components (like the kubelet) to the API server.

-----

### 🤔 First, How Does TLS Work in K8s?

Think of it like a secure handshake 🤝.

1.  A **client** (like a user or a `kubelet`) wants to talk to the **server** (the `kube-api-server`).
2.  The client requests a certificate from a **Certificate Authority (CA)**. In Kubernetes, the cluster *is its own CA* (or can be).
3.  The client proves its identity by creating a **Certificate Signing Request (CSR)** using its own private key.
4.  The CA (in our case, a K8s admin) validates and **approves** the CSR.
5.  The CA signs the certificate using its own private key and issues the public certificate to the client.
6.  Now, when the client talks to the API server, it presents this trusted certificate. The server verifies it's signed by the cluster CA and is valid.

This ensures all communication is encrypted and that both sides are who they say they are.

-----

### 👨‍💻 Real-World Example: Onboarding "Adam"

Let's say a new DevOps engineer, Adam, joins your team. He needs access, but only to the `development` namespace.

Here is the secure workflow:

#### **Step 1: Adam (The User) Generates a Key and CSR**

Adam runs these commands on his own machine. **He NEVER shares his private key.**

```bash
# 1. Create a private key
openssl genrsa -out adam.key 2048

# 2. Create a CSR
# Note: The /CN=adam becomes his username in K8s!
# You can also add groups with /O=group-name
openssl req -new -key adam.key -out adam.csr -subj "/CN=adam"
```

Adam then sends you the `adam.csr` file (and *only* that file).

#### **Step 2: You (The Cluster Admin) Create and Approve the CSR**

Now it's your turn.

```bash
# 1. Get the base64-encoded content of Adam's CSR
# We need this for the YAML manifest
CSR_DATA=$(cat adam.csr | base64 | tr -d '\n')

# 2. Create a CertificateSigningRequest K8s object
# Save this as adam-csr.yaml
cat <<EOF > adam-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user-adam
spec:
  request: $CSR_DATA
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # 1 day (or longer)
  usages:
    - client auth
EOF

# 3. Apply the CSR to the cluster
kubectl apply -f adam-csr.yaml
```

At this point, the CSR is "Pending." You must review and approve it.

```bash
# 4. Check the CSR status
kubectl get csr
# NAME        AGE   SIGNERNAME                            REQUESTER     CONDITION
# user-adam   10s   kubernetes.io/kube-apiserver-client   your-username   Pending

# 5. Approve the request
kubectl certificate approve user-adam
```

#### **Step 3: Provide the Certificate to Adam**

Now that it's approved, the signed certificate is available in the CSR object's status.

```bash
# 6. Extract the signed certificate and send it to Adam
kubectl get csr user-adam -o jsonpath='{.status.certificate}' | base64 -d > adam.crt
```

You can now send the `adam.crt` file back to Adam. He'll use it with his `adam.key` to configure his `kubeconfig` file.

-----

### ⭐ Summary & Next Steps

You've just **authenticated** Adam. But he has no permissions yet\!

The final (and most important) step is **authorization**. Now that K8s knows `User "adam"`, you can use **RBAC** (Role-Based Access Control) to grant him specific permissions.

Create a `Role` and `RoleBinding` to give him `get` and `list` pod access *only* in the `development` namespace. This is the **principle of least privilege** in action.

This CSR flow is fundamental to a secure, multi-tenant Kubernetes cluster\!

\#DevOps \#Kubernetes \#K8s \#Security \#CloudNative \#TLS \#Cybersecurity \#ZeroTrust \#RBAC