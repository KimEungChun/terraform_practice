#!/bin/bash
# Bastion/Jenkins 공통 user-data 템플릿: AWS CLI + kubectl 설치 후 kubeconfig 초기화
# - ${user_data_extra} 로 호스트별 추가 설치(예: Jenkins docker)를 주입

set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl unzip ca-certificates apt-transport-https gnupg lsb-release

# AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update
fi

# kubectl (latest stable)
if ! command -v kubectl >/dev/null 2>&1; then
  KREL="$(curl -Ls https://dl.k8s.io/release/stable.txt)"
  curl -LO "https://dl.k8s.io/release/$(uname -r)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
fi

# Prepare kubeconfig for ubuntu user (best-effort)
su - ubuntu -c "aws eks update-kubeconfig --region ${region} --name ${eks_cluster_name} || true"

# Extra user-data
${user_data_extra}
