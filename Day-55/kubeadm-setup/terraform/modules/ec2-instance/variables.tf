variable "name" { type = string }
variable "ami" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "key_name" { type = string }
variable "role" { type = string }            # "master" or "worker"
variable "index" { type = number }
variable "masters_count" { type = number }
variable "cluster_name" { type = string }
variable "ssm_worker_param" { type = string }
variable "ssm_cp_param" { type = string }
variable "iam_instance_profile" { type = string }
# variable "control_plane_endpoint" {
#   type = string
#   default     = ""
# }

