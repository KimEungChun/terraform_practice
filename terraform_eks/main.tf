provider "aws" {
  region = var.region
}

############################
# 기존 VPC / Public Subnet
############################

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "pub2a" {
  id = var.public_subnet_2a
}

data "aws_subnet" "pub2c" {
  id = var.public_subnet_2c
}

############################
# Private Subnet 2개 추가
############################

resource "aws_subnet" "priv2a" {
  vpc_id            = var.vpc_id
  availability_zone = data.aws_subnet.pub2a.availability_zone
  cidr_block        = var.private_subnet_cidr_2a

  tags = {
    Name = "eks-private-2a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "priv2c" {
  vpc_id            = var.vpc_id
  availability_zone = data.aws_subnet.pub2c.availability_zone
  cidr_block        = var.private_subnet_cidr_2c

  tags = {
    Name = "eks-private-2c"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

############################
# NAT 1개 (Public-2a에)
############################

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_2a
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.priv2a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.priv2c.id
  route_table_id = aws_route_table.private.id
}

############################
# EKS
############################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = [
    aws_subnet.priv2a.id,
    aws_subnet.priv2c.id
  ]

  cluster_endpoint_public_access = true
  enable_irsa = true

  # 👇 추가
  enable_cluster_creator_admin_permissions = true
  access_entries = {}

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3

      subnet_ids = [
        aws_subnet.priv2a.id,
        aws_subnet.priv2c.id
      ]

      iam_role_additional_policies = {
        ecr = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }
}