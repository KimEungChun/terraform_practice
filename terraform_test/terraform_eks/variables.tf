variable "region" {
  default = "ap-northeast-2"
}

variable "cluster_name" {
  default = "devops-test-eks"
}

# 기존 값 (형 스샷 기준)
variable "vpc_id" {
  default = "vpc-0b04445a0cb9ba7c8"
}

variable "public_subnet_2a" {
  default = "subnet-04f3b4ad4590425ec"
}

variable "public_subnet_2c" {
  default = "subnet-05f3a6f9c2526ab89"
}

# 겹치지 않는 CIDR로 조정 가능
variable "private_subnet_cidr_2a" {
  default = "10.20.64.0/20"
}

variable "private_subnet_cidr_2c" {
  default = "10.20.80.0/20"
}