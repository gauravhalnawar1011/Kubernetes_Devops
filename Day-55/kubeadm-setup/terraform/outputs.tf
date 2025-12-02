output "haproxy_public_ip" {
  description = "Public IP of the HAProxy instance"
  value       = module.haproxy.public_ip
}

output "haproxy_private_ip" {
  description = "Private IP of the HAProxy instance"
  value       = module.haproxy.private_ip
}

output "masters_private_ips" {
  description = "Private IPs of masters"
  value       = [for k, m in module.masters : m.private_ip]
}

output "workers_private_ips" {
  description = "Private IPs of workers"
  value       = [for k, w in module.workers : w.private_ip]
}

output "masters_public_ips" {
  description = "Public IPs of masters (for SSH)"
  value       = [for k, m in module.masters : m.public_ip]
}

output "workers_public_ips" {
  description = "Public IPs of workers (for SSH)"
  value       = [for k, w in module.workers : w.public_ip]
}

output "kubeadm_worker_ssm_parameter" {
  value = var.ssm_worker_param
}

output "kubeadm_cp_ssm_parameter" {
  value = var.ssm_cp_param
}

output "ssh_haproxy" {
  description = "SSH command for HAProxy"
  value       = "ssh -i ${var.ssh_key_path} ubuntu@${module.haproxy.public_ip}"
}

output "ssh_masters" {
  description = "SSH commands for all master nodes"
  value = [
    for k, m in module.masters :
    "ssh -i ${var.ssh_key_path} ubuntu@${m.public_ip}"
  ]
}

output "ssh_workers" {
  description = "SSH commands for all worker nodes"
  value = [
    for k, w in module.workers :
    "ssh -i ${var.ssh_key_path} ubuntu@${w.public_ip}"
  ]
}


output "ssh_all" {
  description = "SSH commands for all nodes (HAProxy + masters + workers)"
  value = concat(
    ["ssh -i ${var.ssh_key_path} ubuntu@${module.haproxy.public_ip}"],
    [for m in module.masters : "ssh -i ${var.ssh_key_path} ubuntu@${m.public_ip}"],
    [for w in module.workers : "ssh -i ${var.ssh_key_path} ubuntu@${w.public_ip}"]
  )
}
