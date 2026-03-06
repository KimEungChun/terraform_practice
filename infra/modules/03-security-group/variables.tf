# infra/modules/03-security-group/variables.tf

variable "project" { type = string }
variable "tags"    { type = map(string) }
variable "vpc_id"  { type = string }
variable "my_ip_cidr" { type = string }
