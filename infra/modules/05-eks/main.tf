# infra/modules/05-eks/main.tf

# IAM Policy JSON 생성(data source)
data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# IAM Role 생성 (AssumeRole 정책 포함)
resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = var.tags
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role      = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "cluster_vpc_resource" {
  role      = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# IAM Policy JSON 생성(data source)
data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role 생성 (AssumeRole 정책 포함)
resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "node_worker" {
  role      = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# AWS 관리형 Policy를 Role에 Attachfrfrfr
resource "aws_iam_role_policy_attachment" "node_cni" {
  role      = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "node_ecr_read" {
  role      = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster 생성 (control plane)
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = merge(var.tags, { Name = var.cluster_name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource
  ]
}

# EKS Managed Node Group 생성 (worker nodes)
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_group_instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-ng" })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_read
  ]
}

# OIDC issuer의 TLS 인증서 thumbprint 계산(IRSA용)
data "tls_certificate" "oidc" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# IRSA용 OIDC Provider (EKS issuer 기반)
resource "aws_iam_openid_connect_provider" "oidc" {
  count = var.enable_irsa ? 1 : 0

  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc[0].certificates[0].sha1_fingerprint]

  tags = var.tags
}


# --- (추가) destroy 직전 k8s 정리 단계 ---
# 목적: AWS Load Balancer Controller / Service(LoadBalancer) / Ingress 등이 생성한 ELB/TargetGroup/SG/ENI 잔재를 먼저 내려
#       VPC/서브넷/IGW destroy가 DependencyViolation로 멈추는 것을 줄입니다.
#
# 주의:
# - kubectl이 설치되어 있어야 합니다.
# - kubeconfig 접근이 가능해야 합니다.
# - 정리 명령이 실패해도 destroy 전체를 막지 않도록, 각 단계는 best-effort로 수행합니다.
# resource "null_resource" "pre_destroy_k8s_cleanup" {
#   count = var.enable_pre_destroy_cleanup ? 1 : 0

#   # cluster/nodegroup가 만들어진 뒤에 이 리소스를 생성 → destroy 시에는 이 리소스가 먼저 내려감
#   depends_on = [
#     aws_eks_cluster.this,
#     aws_eks_node_group.default
#   ]

#   triggers = {
#     cluster_name = aws_eks_cluster.this.name
#   }

#   provisioner "local-exec" {
#     when = destroy

#     # Windows PowerShell 기준 (형 환경)
#     interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

#     command = join(" ", compact([
#       # kubeconfig 지정(있으면)
#       var.kubeconfig_path != "" ? "$env:KUBECONFIG='${var.kubeconfig_path}';" : "",
#       # context 옵션(있으면)
#       "$ctx = " + (var.kubectl_context != "" ? "'--context ${var.kubectl_context}'" : "''") + ";",
#       # Ingress 삭제
#       "kubectl $ctx delete ingress --all -A --ignore-not-found; ",
#       # LoadBalancer Service 삭제 (field-selector 사용)
#       "kubectl $ctx delete svc -A --field-selector spec.type=LoadBalancer --ignore-not-found; ",
#       # AWS LBC CRD가 있다면 TargetGroupBinding도 정리(없어도 무시)
#       "kubectl $ctx delete targetgroupbindings.elbv2.k8s.aws --all -A --ignore-not-found 2>$null; ",
#       # 잠깐 대기 (AWS에서 ELB/SG 정리 시간)
#       "Start-Sleep -Seconds 20; ",
#       "exit 0"
#     ]))
#   }
# }
