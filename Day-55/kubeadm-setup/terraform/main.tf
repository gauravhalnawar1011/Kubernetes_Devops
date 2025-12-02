module "vpc" {
  source = "./modules/vpc"

  project_name         = var.cluster_name
  vpc_cidr_range       = var.vpc_cidr_range
  subnet-azs           = var.subnet-azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


locals {
  name_prefix     = var.cluster_name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
}




# --------------------------
# IAM ROLE FOR EC2 (SSM + Parameter Store)
# --------------------------

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${local.name_prefix}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "kubeadm_ssm" {
  name = "${local.name_prefix}-ssm-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:PutParameter"]
      Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/kubeadm/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kubeadm_ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.kubeadm_ssm.arn
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}




# --------------------------
# SECURITY-GROUP-MODULE
# --------------------------

module "security_group" {
  source       = "./modules/securtiy-groups"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr_range
  cluster_name = "kubeadm-cluster"


}

# --------------------------
# CREATE ALL MASTERS
# --------------------------

module "masters" {
  source = "./modules/ec2-instance"

  for_each = { for i in range(var.masters_count) : i => i }

  name          = "${local.name_prefix}-master-${each.key}"
  ami           = var.ubuntu_ami
  instance_type = var.master_instance_type
  subnet_id     = module.vpc.public_subnets[each.key]

  security_group_ids = [module.security_group.master_sg_id]
  key_name           = var.ssh_key_name

  role                 = "master"
  index                = each.key
  masters_count        = var.masters_count
  cluster_name         = var.cluster_name
  ssm_worker_param     = var.ssm_worker_param
  ssm_cp_param         = var.ssm_cp_param
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  # control_plane_endpoint = module.haproxy.private_ip
}

# --------------------------
# FORCE HAPROXY TO WAIT FOR ALL MASTERS
# --------------------------

resource "null_resource" "masters_ready" {
  depends_on = [
    module.masters
  ]
}

# --------------------------
# HAPROXY MODULE
# --------------------------

module "haproxy" {
  source = "./modules/haproxy"

  name          = "${local.name_prefix}-haproxy"
  ami           = var.ubuntu_ami
  instance_type = var.haproxy_instance_type
  subnet_id     = module.vpc.public_subnets[0]

  security_group_ids = [module.security_group.kube_api_lb_sg_id]
  key_name           = var.ssh_key_name

  master_private_ips   = [for k, m in module.masters : m.private_ip]
  cluster_name         = var.cluster_name
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  depends_on = [null_resource.masters_ready]
}

# --------------------------
# WORKER MODULES
# --------------------------

module "workers" {
  source = "./modules/ec2-instance"

  for_each = { for i in range(var.workers_count) : i => i }

  name               = "${local.name_prefix}-worker-${each.key}"
  ami                = var.ubuntu_ami
  instance_type      = var.worker_instance_type
  subnet_id          = module.vpc.public_subnets[each.key % length(module.vpc.public_subnets)]
  security_group_ids = [module.security_group.worker_sg_id]
  key_name           = var.ssh_key_name

  role          = "worker"
  index         = each.key
  masters_count = var.masters_count
  cluster_name  = var.cluster_name

  ssm_worker_param     = var.ssm_worker_param
  ssm_cp_param         = var.ssm_cp_param
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  depends_on = [
    null_resource.masters_ready,
    module.haproxy
  ]
}


