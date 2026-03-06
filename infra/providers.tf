# infra/providers.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  

null = {
  source  = "hashicorp/null"
  version = "~> 3.2"
}
}
}

# ----------------------------------------------------------------------------
# Provider 주의사항 (오늘 겪은 이슈 반영)
# - Terraform은 "현재 인증된 AWS 계정/리전"에 대해 동작함
# - AWS CLI / SSO / profile이 바뀌면, 같은 코드/같은 state라도 다른 계정에 적용될 수 있음
# ✅ 가능하면 aws_profile로 '한 개 프로필'을 고정해서 적용/삭제를 반복하자
# ----------------------------------------------------------------------------
provider "aws" {
  region  = var.region
  profile = var.aws_profile != "" ? var.aws_profile : null

  # 모든 리소스에 기본 태그 적용 (콘솔에서 추적/정리 쉬움)
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}
