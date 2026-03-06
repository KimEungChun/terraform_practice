# Terraform Infra (VPC + SG + ECR + EKS + Bastion)

Single root stack controlling multiple modules:
- 01-iam: IAM roles/instance profiles for bastion/jenkins (no access keys)
- 02-vpc: VPC with public/private subnets, IGW, NAT (single)
- 03-security-group: SGs for bastion/jenkins/app
- 04-ecr: ECR repositories
- 05-eks: EKS cluster + managed node group + (optional) OIDC for IRSA
- 06-bastion: Bastion EC2 with awscli/kubectl installed (user_data)

## Quick start
1) Copy `terraform.tfvars.example` -> `terraform.tfvars` and edit values.
2) `terraform init`
3) `terraform plan`
4) `terraform apply`

> Production notes
- Consider multi-AZ NAT, VPC endpoints (ECR/S3), and tighter IAM policies.
- `aws-auth` (RBAC) is intentionally not automated here; manage it per your org policy.



## Destroy가 안 될 때 체크리스트 (오늘 시행착오 반영)

Terraform으로 만든 리소스는 `terraform destroy`가 기본적으로 역순 삭제를 해주지만,
**콘솔/CLI로 추가로 만든 리소스**(또는 k8s 애드온이 자동 생성한 리소스)가 있으면
VPC/EKS 삭제 단계에서 `DependencyViolation`로 멈출 수 있어.

### 1) ECR RepositoryNotEmptyException
ECR에 이미지가 남아있으면 repo 삭제가 실패함.

- 이 템플릿은 기본값으로 `force_delete = true`를 넣어두었어.
- 그래도 정리하고 싶으면 `infra/scripts/cleanup-ecr.ps1` 사용.

### 2) VPC DependencyViolation (IGW detach / Subnet delete / VPC delete 실패)
대부분 **남은 ENI / NAT / EIP 매핑 / Endpoint**가 원인.

- `infra/scripts/cleanup-vpc.ps1`로 VPC 안에 남은 의존 리소스를 빠르게 점검 가능.

### 3) EKS 관련 "자동 생성 리소스" 주의
아래는 Kubernetes 애드온/Ingress/Service(LoadBalancer) 등이 자동으로 만들 수 있음:
- ELB/ALB/NLB
- Security Group (특히 ALB Controller가 만드는 SG)
- ENI

✅ 원칙: 가능하면 애드온/Ingress/Service도 Terraform(helm/kubernetes provider)로 관리해서
`destroy` 순서가 보장되게 하자.  
❗ 최소한 destroy 전에 `kubectl delete ingress,svc(type=LoadBalancer)` 를 먼저 해두면 깔끔함.

test
