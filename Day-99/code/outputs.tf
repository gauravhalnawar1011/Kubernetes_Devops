############################################
# VPC Outputs
############################################

output "vpc_id" {
  description = "ID of the existing VPC used by this stack"
  value       = data.aws_vpc.main_vpc.id
}

############################################
# Subnet Outputs
############################################

output "subnet_id" {
  description = "ID of the shared subnet where EC2 is deployed"
  value       = data.aws_subnet.shared.id
}

############################################
# AMI Outputs
############################################

output "ami_id" {
  description = "Latest Amazon Linux 2 AMI ID resolved via data source"
  value       = data.aws_ami.linux2.id
}
