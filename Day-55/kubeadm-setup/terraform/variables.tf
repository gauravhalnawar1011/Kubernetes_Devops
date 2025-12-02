# General
variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region to deploy into"
}

variable "aws_profile" {
  type        = string
  default     = ""
  description = "Optional AWS CLI profile name"
}

# Reuse your earlier AMI by default (override if desired)
variable "ubuntu_ami" {
  type        = string
  default     = "ami-02b8269d5e85954ef"
  description = "Ubuntu AMI ID to use (can override to keep up-to-date AMI)"
}

variable "ssh_key_name" {
  type        = string
  default     = "kubeadm-cluster"
  description = "Existing EC2 key pair name to enable SSH access"
}

# counts
variable "masters_count" {
  type    = number
  default = 3
}

variable "workers_count" {
  type    = number
  default = 2
}

# instance sizes
variable "master_instance_type" {
  type    = string
  default = "c7i-flex.large"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "haproxy_instance_type" {
  type    = string
  default = "t3.micro"
}

# cluster
variable "cluster_name" {
  type    = string
  default = "kubeadm-ha"
}

# networking
variable "use_default_vpc" {
  type        = bool
  default     = true
  description = "If true, use AWS default VPC and its default subnet(s) and default security group."
}

# SSM parameter names (can keep defaults)
variable "ssm_worker_param" {
  type    = string
  default = "/kubeadm/join_command"
}

variable "ssm_cp_param" {
  type    = string
  default = "/kubeadm/control_plane_join"
}


variable "ssh_key_path" {
  default = "/home/gaurav-h/Downloads/kubeadm-cluster.pem"

}




variable "vpc_cidr_range" {
  description = "this for the vpc cidr range"
  default     = "10.0.0.0/16"


}

variable "project_name" {
  type        = string
  description = "Project or cluster name"
  default     = "my-prod-vpc"
}

variable "private_subnet_cidrs" {
  description = "this for the vpc private subnet cidr range"
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
  "10.0.13.0/24"]
}

variable "public_subnet_cidrs" {
  description = "this for the vpc public subnet cidr range"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}


variable "subnet-azs" {
  description = "this for the avilavlity zone for the subnet"
  default = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1c"
  ]
}


