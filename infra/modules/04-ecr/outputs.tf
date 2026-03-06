# infra/modules/04-ecr/outputs.tf

output "repository_urls" {
  value = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}
