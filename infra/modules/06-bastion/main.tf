# infra/modules/06-bastion/main.tf

# AMI 조회(data source): 최신 Ubuntu 이미지 선택
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data = templatefile("${path.module}/user_data.tpl", {
    region          = var.region
    eks_cluster_name= var.eks_cluster_name
    user_data_extra = var.user_data_extra
  })
}

# EC2 Instance 생성 (Bastion/Jenkins 재사용)
resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile = var.instance_profile_name

  user_data = local.user_data

  tags = merge(var.tags, { Name = var.project })
}
