# infra/modules/02-vpc/variables.tf

variable "project" { type = string }
variable "tags"    { type = map(string) }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
