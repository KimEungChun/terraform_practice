# infra/variables.tf

variable "aws_profile" {
  type        = string
  description = <<EOT
(Optional) AWS CLI profile name to pin Terraform to a single identity.
- If you keep switching credentials, destroy/apply can target a different account by mistake.
- Leave empty to use the default AWS credential resolution (env vars, default profile, SSO, etc).
Tip (Windows PowerShell):
  $env:AWS_PROFILE="myprofile"
  $env:AWS_DEFAULT_REGION="ap-northeast-2"
EOT
  default = ""
}

variable "ecr_force_delete" {
  type        = bool
  description = "Pass-through to ECR module. When true, destroy deletes repos even if images exist."
  default     = true
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "ap-northeast-2"
}

variable "project" {
  type        = string
  description = "Project/name prefix"
  default     = "devops"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR (e.g., 1.2.3.4/32)"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 KeyPair name (e.g., gun2)"
}

# FIX: Terraform does not allow multiple arguments inside single-line block syntax.
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "AZ list (length should match subnet CIDR lists)"
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# FIX: multi-line variable block (single-line syntax allows only 1 argument)
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
# FIX: multi-line variable block (single-line syntax allows only 1 argument)
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ecr_repositories" {
  type        = list(string)
  description = "ECR repos to create"
  default     = ["my-app"]
}

# FIX: multi-line variable block
variable "eks_cluster_name" {
  type    = string
  default = "devops-eks"
}
# FIX: multi-line variable block
variable "eks_cluster_version" {
  type    = string
  default = "1.29"
}

# FIX: multi-line variable block
variable "node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
# FIX: multi-line variable block
variable "node_group_desired_size" {
  type    = number
  default = 2
}
# FIX: multi-line variable block
variable "node_group_min_size" {
  type    = number
  default = 1
}
# FIX: multi-line variable block
variable "node_group_max_size" {
  type    = number
  default = 4
}

# FIX: multi-line variable block
variable "enable_irsa" {
  type    = bool
  default = true
}

# FIX: multi-line variable block
variable "bastion_instance_type" {
  type    = string
  default = "t3.small"
}
# FIX: multi-line variable block
variable "jenkins_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "create_jenkins_instance" {
  type        = bool
  description = "Optional: create Jenkins EC2"
  default     = true
}
