# ----------------------------------------------------------------------------
# Root locals: 공통 태그/메타데이터를 한 곳에서 정의해서 모든 모듈에 전달
# ----------------------------------------------------------------------------
locals {
  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}


# IAM 모듈: EC2(Bastion/Jenkins) Instance Profile, EKS 관련 IAM Role 등을 생성
module "iam" {
  source  = "./modules/01-iam"
  project = var.project
}


# VPC 모듈: VPC, Subnet(public/private), IGW, NAT, RouteTable 구성
module "vpc" {
  source               = "./modules/02-vpc"
  project              = var.project
  tags                 = local.tags
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


# SG 모듈: Bastion/Jenkins/App/EKS 접근 제어용 보안그룹 생성
module "sg" {
  source     = "./modules/03-security-group"
  project    = var.project
  tags       = local.tags
  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = var.my_ip_cidr
}


# ECR 모듈: 리포지토리 생성 + 이미지 스캔 + Lifecycle policy(보관 정책)
module "ecr" {
  source       = "./modules/04-ecr"
  project      = var.project
  tags         = local.tags
  repositories = var.ecr_repositories
  force_delete = var.ecr_force_delete  # ⭐ ECR 이미지 남아도 destroy 가능
}


# EKS 모듈: Cluster/NodeGroup 생성 + (옵션) IRSA용 OIDC Provider 생성
module "eks" {
  source                    = "./modules/05-eks"
  project                   = var.project
  tags                      = local.tags
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_name              = var.eks_cluster_name
  cluster_version           = var.eks_cluster_version
  node_group_instance_types = var.node_group_instance_types
  desired_size              = var.node_group_desired_size
  min_size                  = var.node_group_min_size
  max_size                  = var.node_group_max_size
  enable_irsa               = var.enable_irsa
}


# Bastion EC2: kubectl/awscli 실행용(운영/트러블슈팅) 호스트
# - Public subnet에 배치 (편의상). 필요 시 SSM + private subnet으로 개선 가능
module "bastion" {
  source                = "./modules/06-bastion"
  project               = "${var.project}-bastion"
  tags                  = local.tags
  subnet_id             = module.vpc.public_subnet_ids[0]
  security_group_id     = module.sg.bastion_sg_id
  key_name              = var.key_name
  instance_type         = var.bastion_instance_type
  region                = var.region
  eks_cluster_name       = module.eks.cluster_name
  instance_profile_name = module.iam.bastion_instance_profile_name
}


# Jenkins EC2(옵션): create_jenkins_instance=true 일 때만 생성
# - Bastion 모듈을 재사용(같은 EC2 템플릿)하면서 SG/InstanceProfile/UserData만 다르게 주입
# - count로 조건부 생성 (0이면 미생성)
module "jenkins" {
  source = "./modules/06-bastion"
  count  = var.create_jenkins_instance ? 1 : 0

  project               = "${var.project}-jenkins"
  tags                  = local.tags
  subnet_id             = module.vpc.public_subnet_ids[0]
  security_group_id     = module.sg.jenkins_sg_id
  key_name              = var.key_name
  instance_type         = var.jenkins_instance_type
  region                = var.region
  eks_cluster_name       = module.eks.cluster_name
  instance_profile_name = module.iam.jenkins_instance_profile_name

  # Minimal extras for Jenkins host (docker install). Customize as needed.
  user_data_extra = <<-EOT
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOT
}
