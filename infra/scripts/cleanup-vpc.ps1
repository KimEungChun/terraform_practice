<# 
cleanup-vpc.ps1
목적: VPC 삭제가 DependencyViolation로 막힐 때, '남아있는 의존 리소스'를 찾아 지우는 체크리스트 스크립트.

⚠️ 주의:
- 이 스크립트는 "테스트/정리" 용도. 운영 VPC에 절대 사용 금지.
- VPC 안에 실제로 사용 중인 EC2/ENI가 있으면 먼저 종료해야 함.

사용 예:
  .\cleanup-vpc.ps1 -VpcId vpc-0123456789abcdef0 -Region ap-northeast-2
#>

param(
  [Parameter(Mandatory=$true)][string]$VpcId,
  [string]$Region = "ap-northeast-2"
)

$env:AWS_DEFAULT_REGION = $Region

Write-Host "== VPC cleanup precheck ==" -ForegroundColor Cyan
aws sts get-caller-identity | Out-Host
Write-Host "Target VPC: $VpcId (Region: $Region)" -ForegroundColor Yellow

Write-Host "`n1) 남아있는 ENI(네트워크 인터페이스) 확인" -ForegroundColor Cyan
aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$VpcId | Out-Host
Write-Host "-> ENI가 있으면: 연결된 리소스(EC2/LB/NAT/VPN/Endpoint 등)부터 지워야 함" -ForegroundColor DarkYellow

Write-Host "`n2) NAT Gateway 확인" -ForegroundColor Cyan
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$VpcId | Out-Host
Write-Host "-> NAT가 남아있으면 delete-nat-gateway 후 '완전 삭제'까지 기다려야 함" -ForegroundColor DarkYellow

Write-Host "`n3) Elastic IP(EIP) 확인" -ForegroundColor Cyan
aws ec2 describe-addresses --filters Name=domain,Values=vpc | Out-Host
Write-Host "-> AssociationId/NetworkInterfaceId가 VPC 안 리소스와 매핑되면 IGW detach 불가" -ForegroundColor DarkYellow

Write-Host "`n4) VPC Endpoint 확인" -ForegroundColor Cyan
aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$VpcId | Out-Host

Write-Host "`n5) Security Group 확인" -ForegroundColor Cyan
aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VpcId | Out-Host
Write-Host "-> default SG는 VPC 삭제될 때 같이 사라짐. 다른 SG가 있으면 선삭제." -ForegroundColor DarkYellow

Write-Host "`n6) Route table 확인(blackhole route 포함)" -ForegroundColor Cyan
aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VpcId | Out-Host
Write-Host "-> NAT 삭제 후에도 route에 NatGatewayId가 남아 blackhole로 보일 수 있음(정리 대상)" -ForegroundColor DarkYellow

Write-Host "`n7) Subnet 확인" -ForegroundColor Cyan
aws ec2 describe-subnets --filters Name=vpc-id,Values=$VpcId | Out-Host

Write-Host "`n8) Internet Gateway 확인" -ForegroundColor Cyan
aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VpcId | Out-Host
Write-Host "-> 'mapped public address' 에러면 EIP/ENI/인스턴스 퍼블릭 IP 매핑이 남아있는 것" -ForegroundColor DarkYellow

Write-Host "`n== TIP: 최후의 수단(수동 삭제 순서) ==" -ForegroundColor Magenta
Write-Host @"
1) (있으면) ALB/NLB 등 로드밸런서 삭제
2) (있으면) NAT Gateway 삭제 -> 완전 삭제까지 대기
3) EIP 해제/반납(association 제거 후 release)
4) VPC Endpoint 삭제
5) Subnet 삭제
6) Custom route table 삭제 (main route table은 VPC와 함께 삭제됨)
7) IGW detach 후 삭제
8) VPC 삭제
"@ -ForegroundColor Magenta
