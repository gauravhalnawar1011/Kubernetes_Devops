variable "cluster_name" {
  description = "Name of the Kubernetes cluster (used as prefix in SG names)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster is created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (for intra-cluster communication)"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to nodes (use your IPs in production!)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_kubeapi_cidrs" {
  description = "CIDR blocks allowed to access the Kubernetes API (LB:6443)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
