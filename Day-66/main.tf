provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_instance" "minikube_host" {
  ami                    = "ami-02b8269d5e85954ef" 
  instance_type          = "m7i-flex.large"
  vpc_security_group_ids = [data.aws_security_group.default.id]
  key_name = "kubeadm-cluster"

  user_data = file("install_k8s_stack.sh")

  tags = {
    Name = "minikube-argocd-server"
  }
}

output "instance_public_ip" {
  value = aws_instance.minikube_host.public_ip
}
