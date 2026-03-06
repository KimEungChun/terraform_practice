# 05-eks (EKS) 모듈

이 모듈은 **EKS Cluster + Managed NodeGroup + (옵션) IRSA(OIDC Provider)** 를 생성합니다.

## 왜 보강했나 (2026-03-03 이슈 반영)
형이 겪은 것처럼, EKS 사용 중 **콘솔/CLI/kubectl/컨트롤러가 만든 리소스(특히 ELB/SG/ENI)** 가 Terraform state 밖에 생기면,
`terraform destroy` 단계에서 VPC/서브넷/IGW 삭제가 **DependencyViolation** 로 자주 멈춥니다.

이를 줄이기 위해 아래 2가지를 추가했습니다.

1. **(옵션) pre-destroy Kubernetes 정리 단계**
   - `enable_pre_destroy_cleanup=true` 일 때, destroy 직전에 `kubectl` 로
     - Ingress 전체 삭제
     - LoadBalancer 타입 Service 삭제
     - TargetGroupBinding(있으면) 삭제
   - 목적: AWS Load Balancer Controller 등이 만든 **ELB/TargetGroup/SG** 잔재를 먼저 내려 `destroy` 성공률을 높임

2. **(권장) EKS core addon을 TF로 관리하도록 확장 가능**
   - 이 템플릿은 최소구성으로 두었고, 필요 시 `aws_eks_addon` 리소스를 추가/확장하세요.

## 변수
- `enable_pre_destroy_cleanup` (bool, default: true)
- `kubeconfig_path` (string, default: "")
  - Windows에서 Terraform 실행 시, kubectl이 이 kubeconfig를 쓰도록 `KUBECONFIG` 환경변수로 주입합니다.
- `kubectl_context` (string, default: "")
  - 필요 시 `--context`로 지정

## 주의
- 이 pre-destroy는 **kubectl이 설치되어 있고**, 해당 kubeconfig로 클러스터 접근이 되는 환경에서만 동작합니다.
- 실패해도 terraform 자체가 바로 멈추지 않도록, 커맨드에 `|| exit 0` 패턴을 사용했습니다(최대한 “정리 시도” 목적).
