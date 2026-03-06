<#
cleanup-ecr.ps1
목적: ECR RepositoryNotEmptyException 예방/해결. (destroy 전에 이미지 정리)

사용 예:
  .\cleanup-ecr.ps1 -Repo simple-java-app -Region ap-northeast-2
#>

param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [string]$Region = "ap-northeast-2"
)

$env:AWS_DEFAULT_REGION = $Region

Write-Host "== ECR cleanup ==" -ForegroundColor Cyan
aws sts get-caller-identity | Out-Host

Write-Host "Listing images in repo: $Repo" -ForegroundColor Yellow
$images = aws ecr list-images --repository-name $Repo --query 'imageIds[*]' --output json | ConvertFrom-Json

if ($images.Count -eq 0) {
  Write-Host "No images found. Nothing to delete." -ForegroundColor Green
  exit 0
}

Write-Host "Deleting $($images.Count) image(s)..." -ForegroundColor Yellow
# batch-delete-image expects JSON array
$payload = $images | ConvertTo-Json -Compress
aws ecr batch-delete-image --repository-name $Repo --image-ids $payload | Out-Host

Write-Host "Done. Re-run list-images to confirm." -ForegroundColor Green
