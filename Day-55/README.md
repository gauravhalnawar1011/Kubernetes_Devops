
---

# 📘 **Kubeadm HA Cluster on AWS using Terraform**

This project provisions a full **Highly Available Kubernetes cluster** using **Terraform**, **EC2**, **HAProxy**, **custom VPC**, and **modular Infrastructure as Code (IaC)**.

The environment includes:

* **Custom Production-Grade VPC**
* **Security Group Module**
* **EC2 Master Nodes** (kubeadm control plane)
* **EC2 Worker Nodes**
* **HAProxy Load Balancer** (API server endpoint)
* **IAM Roles & SSM access**
* Fully modular, reusable, and scalable infrastructure

---

# 📂 **Project Structure**

```
.
├── main.tf                     # Root module using all child modules
├── variables.tf                # Root variables
├── outputs.tf                  # Root outputs
├── providers.tf                # AWS provider config
├── versions.tf                 # Terraform + provider versions
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf             # VPC, subnets, IGW, RTs
│   │   ├── provider.tf
│   │   └── variables.tf
│   │
│   ├── securtiy-groups/
│   │   ├── main.tf             # Master/Worker/LB security groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ec2-instance/
│   │   ├── main.tf             # EC2 launch module for masters/workers
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── userdata.tpl        # Kubeadm install/bootstrap script
│   │
│   └── haproxy/
│       ├── main.tf             # HAProxy instance (API LB)
│       ├── variables.tf
│       ├── outputs.tf
│       └── userdata.tpl        # HAProxy configuration template
```

---

# 🚀 **Architecture Overview**

## 1️⃣ VPC Module

Creates production-grade networking:

* **VPC CIDR** (10.0.0.0/16)
* **3 Public Subnets** + **3 Private Subnets**
* **Internet Gateway**
* **Public Route Table**
* No NAT Gateway (early phase → cost saving)
* Outputs:

  * `vpc_id`
  * `public_subnets`
  * `private_subnets`

This ensures all nodes are deployed into **our own isolated network**, not the AWS default VPC.

---

## 2️⃣ Security Group Module

Creates dedicated security groups for:

### 🔹 Master SG

* 6443 → kube-api server
* 10259 → scheduler
* 10257 → controller-manager
* 2379–2381 → etcd
* 10250 → kubelet
* SSH → (allowed CIDR)

### 🔹 Worker SG

* 10250 → kubelet
* 10256 → kube-proxy
* 30000–32767 → NodePort
* SSH

### 🔹 HAProxy SG

* 6443 open (API LB)
* SSH

Outputs:

* `master_sg_id`
* `worker_sg_id`
* `kube_api_lb_sg_id`

---

## 3️⃣ EC2 Instance Module

Used to provision:

* **Master nodes**
* **Worker nodes**

Includes:

* AMI
* Instance type
* Subnet
* SSM IAM Role (for parameter store)
* Userdata template that:

  * installs container runtime
  * installs kubeadm, kubelet, kubectl
  * bootstraps cluster or joins worker

---

## 4️⃣ HAProxy Module

Provisions 1 EC2 instance that acts as a **Load Balancer** for the kube-apiserver.

HAProxy forwards:

```
6443 → master nodes
```

Control plane endpoint:

```
https://<haproxy-private-ip>:6443
```

Used in kubeadm init.

---

# 🔄 **Cluster Workflow**

### Step 1 — VPC module runs first

Creates:

* VPC
* Subnets
* IGW
* Route tables

### Step 2 — Security groups

Created inside the VPC using outputs from Step 1.

### Step 3 — Master nodes

EC2 "masters" are created:

* 3 masters → 1 in each public subnet
* Uses `master_sg_id`
* Bootstrap via kubeadm

### Step 4 — Wait for masters

A `null_resource` enforces completion before HAProxy.

### Step 5 — HAProxy

HAProxy is deployed:

* Gets IPs of master nodes
* Generates dynamic HAProxy config
* Starts forwarding Kubernetes traffic

### Step 6 — Worker nodes

Workers join the cluster automatically using:

* SSM parameter store tokens
* kubeadm join command
* Worker SG

---

# 📥 **How to Deploy**

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Validate configuration

```bash
terraform validate
```

### 3. Format files (optional)

```bash
terraform fmt
```

### 4. View deployment plan

```bash
terraform plan
```

### 5. Apply infrastructure

```bash
terraform apply -auto-approve
```

Terraform will create:

✔ VPC
✔ Subnets
✔ Security groups
✔ IAM roles
✔ 3 master nodes
✔ HAProxy
✔ Worker nodes

---

# 📤 **Destroy environment**

```bash
terraform destroy
```

Make sure to delete kubeadm configs stored in SSM parameter store if needed.

---

# 🔧 **Configuration (terraform.tfvars)**

Example:

```hcl
cluster_name          = "kubeadm-ha"
aws_region            = "ap-south-1"
masters_count         = 3
workers_count         = 3
ubuntu_ami            = "ami-xxxxxxx"
master_instance_type  = "t3.medium"
worker_instance_type  = "t3.small"
haproxy_instance_type = "t3.micro"
ssh_key_name          = "mykey"

vpc_cidr_range = "10.0.0.0/16"

subnet_azs = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]
```

---

# 🧩 **What This Automates**

✔ Creates fully production-ready VPC
✔ Deploys 3 master control plane nodes
✔ Deploys HAProxy load balancer
✔ Deploys any number of worker nodes
✔ Automates join tokens via SSM
✔ Uses modular architecture for reusability
✔ Zero manual provisioning

---

# 📌 **Why This Approach?**

This project follows DevOps best practices:

* **Infrastructure as Code** (Terraform)
* **Modular Design** → reusable across different clusters
* **Highly Available Control Plane**
* **Separation of concerns**:

  * network module
  * security group module
  * EC2 module
  * HAProxy module
* **Parameter Store for automation**
* **No default VPC usage**
* **Scalable across AZs**


---

