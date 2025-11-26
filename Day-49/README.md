
---

# **Kubernetes Custom Resources & Sample Controller – README**

## **Overview**

Kubernetes ships with many built-in API objects such as **Pods**, **Deployments**, **ConfigMaps**, **Secrets**, **ReplicaSets**, and more.
However, when your use case goes beyond what Kubernetes provides, you can extend the Kubernetes API using:

* **CRD – CustomResourceDefinition**
* **CR – Custom Resource (an instance of the CRD)**
* **Custom Controller – logic that watches & reconciles CRs**

This repository demonstrates how to create and manage custom resources using the official **kubernetes/sample-controller** project.
You will learn how Kubernetes API extensibility works, how controllers maintain desired state, and how CRDs behave similarly to built-in Kubernetes objects.

---

## **Table of Contents**

* [Prerequisites](#prerequisites)
* [Getting Started](#getting-started)

  * Step 1: Clone the Repository
  * Step 2: Build & Run the Sample Controller
  * Step 3: Create the CustomResourceDefinition (CRD)
  * Step 4: Create a Custom Resource (CR)
  * Step 5: Verify Resources
  * Step 6: Cleanup
* [Understanding Kubernetes API Extension](#understanding-kubernetes-api-extension)
* [Example YAML with Comments](#example-yaml-with-comments)
* [Useful Debug Commands](#useful-debug-commands)
* [Exam-Style Questions](#exam-style-questions)

---

## **Prerequisites**

Ensure you have the following:

* A running Kubernetes cluster (Minikube, Kind, or cloud provider cluster)
* `kubectl` configured
* Go language (v1.16+ recommended)
* Basic knowledge of Deployments, Pods, CRDs, and controllers

---

# **Getting Started**

## **Step 1: Clone the sample-controller Repository**

```bash
git clone https://github.com/kubernetes/sample-controller
cd sample-controller
```

---

## **Step 2: Build & Run the Sample Controller**

Install Go if needed:

```bash
sudo apt-get update -y
sudo apt install golang-go -y
```

Fix module issues (older sample-controller versions require updates):

```bash
sed -i 's/go 1\.24\.0/go 1.18/' go.mod
sed -i '/^godebug/d' go.mod
go mod tidy
```

Build:

```bash
go build -o sample-controller .
```

Run controller:

```bash
./sample-controller -kubeconfig=$HOME/.kube/config
```

> **Note:** Keep this running in a separate terminal—it continuously watches and reconciles Foo resources.

---

## **Step 3: Create the CustomResourceDefinition (CRD)**

```bash
kubectl create -f artifacts/examples/crd-status-subresource.yaml
```

Verify:

```bash
kubectl get crd | grep foo
```

Expected output:

```
foos.samplecontroller.k8s.io
```

---

## **Step 4: Create a Custom Resource (CR)**

```bash
kubectl create -f artifacts/examples/example-foo.yaml
```

This will trigger the controller to automatically create a Deployment.

---

## **Step 5: Verify the Created Resources**

Check CR:

```bash
kubectl get foo
```

Check Deployment created by the controller:

```bash
kubectl get deployments
```

Describe deployment:

```bash
kubectl describe deployment example-foo-deployment
```

---

## **Step 6: Cleanup**

```bash
kubectl delete -f artifacts/examples/example-foo.yaml
kubectl delete -f artifacts/examples/crd-status-subresource.yaml
```

Stop the sample-controller process (`Ctrl + C`).

---

# **Understanding Kubernetes API Extension**

### **CustomResourceDefinition (CRD)**

Defines:

* The schema of the custom resource
* Validation (string, int, boolean, object structure)
* Supported versions
* Additional features (status subresource, scale subresource, etc.)

### **Custom Resource (CR)**

An object created **from** the CRD.
Think of CRD as a “class” and CR as an “object instance.”

### **Custom Controller**

Responsible for ensuring **desired state = actual state**, similar to:

* Deployment controller
* ReplicaSet controller
* StatefulSet controller

Your custom controller watches custom resources and takes automated actions.

---

# **Example YAML with Comments**

### **CustomResourceDefinition (CRD) — simplified conceptual example**

```yaml
# Defines the API extension for Kubernetes
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: foos.samplecontroller.k8s.io
spec:
  group: samplecontroller.k8s.io
  scope: Namespaced
  names:
    plural: foos           # Used in kubectl get foos
    singular: foo
    kind: Foo              # CR kind
    shortNames:
      - fo
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                deploymentName:
                  type: string  # Controller will create a Deployment with this name
                replicas:
                  type: integer # Number of replicas for the deployment
```

---

### **Custom Resource (CR) Example**

```yaml
# Instance of Foo custom resource
apiVersion: samplecontroller.k8s.io/v1alpha1
kind: Foo
metadata:
  name: example-foo
spec:
  deploymentName: example-foo-deployment   # Controller uses this to create Deployment
  replicas: 1                               # Desired number of pods
```

---

# **Useful Debug Commands**

```bash
kubectl logs -f <controller-pod-name>             # Controller logs
kubectl describe crd foos.samplecontroller.k8s.io # CRD details
kubectl describe foo example-foo                  # CR instance details
kubectl get crd                                   # List all CRDs
```

---

# **Exam-Style Questions**

### **Q1. List all cert-manager CRDs**

```bash
kubectl describe crd | grep certificates
```

Extract docs of a specific field:

```bash
kubectl explain certificates.spec.subject
```

---

### **Q2. Install cert-manager *without CRDs***

```bash
helm repo add jetstack https://charts.jetstack.io --force-update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --set crds.enabled=false
```

---

# **Conclusion**

This project demonstrates the complete lifecycle of Kubernetes API extension:

1. Defining CRDs
2. Creating CRs
3. Running a controller that ensures desired state
4. Understanding how CRDs function similar to core Kubernetes resources

