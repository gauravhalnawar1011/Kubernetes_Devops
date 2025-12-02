terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}


#############################
# Master nodes security group
#############################

resource "aws_security_group" "master" {
  name        = "${var.cluster_name}-master-sg"
  description = "Security group for Kubernetes control-plane (master) nodes"
  vpc_id      = var.vpc_id

  # Kubernetes API server
  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kube-scheduler
  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kubelet on master
  ingress {
    description = "kubelet (master)"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kube-controller-manager
  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd (client + peer) – using range 2379-2381 as requested
  ingress {
    description = "etcd (client + peer)"
    from_port   = 2379
    to_port     = 2381
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH to master nodes
  # In production, restrict allowed_ssh_cidrs to your own IP(s)
  ingress {
    description = "SSH access to master nodes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Allow all outbound (typical for nodes)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.cluster_name}-master-sg"
    Role    = "kubernetes-master"
    Managed = "terraform"
  }
}

#############################
# Worker nodes security group
#############################

resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  # kube-proxy
  ingress {
    description = "kube-proxy"
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kubelet on workers
  ingress {
    description = "kubelet (worker)"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort Services
  ingress {
    description = "Kubernetes NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH to worker nodes (same note as masters)
  ingress {
    description = "SSH access to worker nodes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.cluster_name}-worker-sg"
    Role    = "kubernetes-worker"
    Managed = "terraform"
  }
}

#############################
# Load balancer security group
#############################

resource "aws_security_group" "kube_api_lb" {
  name        = "${var.cluster_name}-kubeapi-lb-sg"
  description = "Security group for Kubernetes API load balancer"
  vpc_id      = var.vpc_id

  # Expose Kubernetes API via LB on 6443 to the world (or restricted CIDRs)
  ingress {
    description = "Kubernetes API via Load Balancer"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_kubeapi_cidrs
  }

  # SSH (only if you REALLY need SSH to the LB instance, e.g. if it's a bastion)
  ingress {
    description = "SSH access to LB"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.cluster_name}-kubeapi-lb-sg"
    Role    = "kubernetes-api-lb"
    Managed = "terraform"
  }
}

#############################
# Useful outputs
#############################

output "master_sg_id" {
  description = "Security group ID for master nodes"
  value       = aws_security_group.master.id
}

output "worker_sg_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.worker.id
}

output "kube_api_lb_sg_id" {
  description = "Security group ID for Kubernetes API load balancer"
  value       = aws_security_group.kube_api_lb.id
}
