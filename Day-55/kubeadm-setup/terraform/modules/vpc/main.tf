

locals {
  vpc_cidr = var.vpc_cidr_range

  azs = var.subnet-azs

  # Non-overlapping CIDR blocks
  public_subnet_cidrs = var.public_subnet_cidrs

  private_subnet_cidrs = var.private_subnet_cidrs
}

############################
# VPC
############################
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Managed = "terraform"
    Env     = "dev"
  }
}

############################
# Internet Gateway
############################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

############################
# Public Subnets
############################
resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in local.public_subnet_cidrs : idx => {
      cidr = cidr
      az   = local.azs[idx]
    }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.value.az}"
    Tier = "public"
  }
}

############################
# Private Subnets
############################
resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in local.private_subnet_cidrs : idx => {
      cidr = cidr
      az   = local.azs[idx]
    }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-private-${each.value.az}"
    Tier = "private"
  }
}

############################
# Public Route Table
############################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # Default route to IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

############################
# Associate public subnets to Public RT
############################
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public_rt.id
  subnet_id      = each.value.id
}

############################
# Private Route Table (no NAT as requested)
############################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private

  route_table_id = aws_route_table.private_rt.id
  subnet_id      = each.value.id
}

############################
# Outputs
############################
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnets" {
  value = [for s in aws_subnet.private : s.id]
}
