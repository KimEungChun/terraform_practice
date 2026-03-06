# infra/modules/06-bastion/variables.tf

variable "project" { type = string }
variable "tags"    { type = map(string) }

variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "key_name" { type = string }
variable "instance_type" { type = string }

variable "region" { type = string }
variable "eks_cluster_name" { type = string }

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name to attach"
}

variable "user_data_extra" {
  type        = string
  default     = ""
}
