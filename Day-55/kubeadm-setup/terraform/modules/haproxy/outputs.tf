output "instance_id" {
  value = aws_instance.haproxy.id
}
output "private_ip" {
  value = aws_instance.haproxy.private_ip
}

output "public_ip" {
  value = aws_instance.haproxy.public_ip
}
