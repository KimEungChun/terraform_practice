# infra/modules/05-eks/variables.tf

variable "project" { type = string }
variable "tags"    { type = map(string) }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "cluster_name" { type = string }
variable "cluster_version" { type = string }

variable "node_group_instance_types" { type = list(string) }
variable "desired_size" { type = number }
variable "min_size" { type = number }
variable "max_size" { type = number }

# FIX: multi-line variable block (single-line syntax allows only 1 argument)
variable "enable_irsa" {
  type    = bool
  default = true
}
# --- (추가) destroy 안정화 옵션 ---
# EKS를 지우기 전에, kubectl로 Ingress/LoadBalancer Service 등 AWS 리소스를 생성하는 객체를 먼저 정리합니다.
# (오늘 이슈: k8s/컨트롤러가 만든 SG/ELB 잔재로 VPC destroy가 멈추는 케이스 방지)
# FIX: multi-line variable block (single-line syntax allows only 1 argument)
variable "enable_pre_destroy_cleanup" {
  type    = bool
  default = true
}

# Windows/로컬 환경에서 kubectl이 사용할 kubeconfig 경로(지정 시 KUBECONFIG 환경변수로 주입)
# FIX: multi-line variable block (single-line syntax allows only 1 argument)
variable "kubeconfig_path" {
  type    = string
  default = ""
}

# kubectl context가 필요하면 지정 (예: "arn:aws:eks:ap-northeast-2:...:cluster/devops-test-eks")
# FIX: multi-line variable block (single-line syntax allows only 1 argument)
variable "kubectl_context" {
  type    = string
  default = ""
}
