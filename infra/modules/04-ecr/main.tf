# infra/modules/04-ecr/main.tf

# ECR Repository: 이미지 저장소(스캔 on push)
resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name         = each.value
  force_delete = var.force_delete  # ⭐ destroy 시 이미지가 남아있어도 repo 삭제

  image_scanning_configuration { scan_on_push = true }
  tags = merge(var.tags, { Name = "${var.project}-${each.value}" })
}

# ECR Lifecycle Policy: 오래된 이미지 정리 규칙
resource "aws_ecr_lifecycle_policy" "keep_last_50" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 50 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 50
      }
      action = { type = "expire" }
    }]
  })
}
