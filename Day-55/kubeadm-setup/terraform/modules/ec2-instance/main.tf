resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name == "" ? null : var.key_name
  iam_instance_profile   = var.iam_instance_profile
  associate_public_ip_address = true

  tags = {
    Name    = var.name
    Cluster = var.cluster_name
    Role    = var.role
    Index   = tostring(var.index)
  }

  user_data = templatefile("${path.module}/userdata.tpl", {
    role              = var.role,
    index             = var.index,
    masters_count     = var.masters_count,
    cluster_name      = var.cluster_name,
    ssm_worker_param  = var.ssm_worker_param,
    ssm_cp_param      = var.ssm_cp_param
  })
}






