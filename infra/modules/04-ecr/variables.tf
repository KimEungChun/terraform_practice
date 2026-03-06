# infra/modules/04-ecr/variables.tf

variable "project" { type = string }
variable "tags"    { type = map(string) }

variable "repositories" {
  type        = list(string)
  description = "ECR repository names to create."
}

variable "force_delete" {
  type        = bool
  description = <<EOT
When true, Terraform will delete the repository even if it still contains images.
✅ This prevents the common destroy failure:
  RepositoryNotEmptyException: repository cannot be deleted because it still contains images
EOT
  default = true
}
