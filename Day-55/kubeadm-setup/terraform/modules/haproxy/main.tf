resource "aws_instance" "haproxy" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name == "" ? null : var.key_name
  iam_instance_profile   = var.iam_instance_profile
  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/userdata.tpl",
    {
      master_ips = var.master_private_ips
    }
  )

  tags = {
    Name    = var.name
    Cluster = var.cluster_name
    Role    = "haproxy"
  }
}
