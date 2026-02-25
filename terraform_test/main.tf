terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

############################################
# Provider (Seoul)
############################################
provider "aws" {
  region = "ap-northeast-2"
}

############################################
# Variables
############################################
variable "project" {
  description = "Project prefix"
  type        = string
  default     = "devops-test"
}

variable "my_ip_cidr" {
  description = "SSH/Jenkins 접근 허용 CIDR (예: 183.99.66.203/32)"
  type        = string
  default     = "183.99.66.203/32"
}

variable "key_name" {
  description = "AWS 콘솔에 생성되어 있는 Key Pair 이름 (파일명 gun2.pem 아님)"
  type        = string
  default     = "gun2"
}

variable "app_instance_type" {
  description = "App EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "jenkins_instance_type" {
  description = "Jenkins EC2 instance type (Jenkins는 t2.micro면 버거울 수 있음)"
  type        = string
  default     = "t3.small"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "subnet_a_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "subnet_c_cidr" {
  type    = string
  default = "10.20.2.0/24"
}

############################################
# Data: Ubuntu 최신 LTS AMI (24.04 Noble)
############################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################################
# Networking: VPC + Public Subnets (2a/2c)
############################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-2a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_c_cidr
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-2c"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-rt-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

############################################
# Security Groups
############################################
# App SG: HTTP/HTTPS 공개, SSH는 내 IP + Jenkins에서 접근 허용
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-app-sg"
  description = "App SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Jenkins -> App SSH (배포/관리용)
  ingress {
    description     = "SSH from Jenkins SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-app-sg"
  }
}

# Jenkins SG: SSH/Jenkins UI는 내 IP만, 필요시 HTTP/HTTPS도 열어둠
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project}-jenkins-sg"
  description = "Jenkins SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Jenkins Web UI (기본 8080) - 내 IP만
  ingress {
    description = "Jenkins UI from my IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # (선택) nginx 페이지 확인/리버스프록시 대비
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound (GitHub, apt, docker, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-jenkins-sg"
  }
}

############################################
# User data: nginx 기본 설치 (둘 다)
############################################
locals {
  nginx_user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>${var.project} - $(hostname)</h1>" > /var/www/html/index.html
  EOF
}

############################################
# EC2 Instances (Jenkins / App)
############################################
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.nginx_user_data

  tags = {
    Name = "${var.project}-jenkins"
    Role = "jenkins"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.app_instance_type
  subnet_id                   = aws_subnet.public_c.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.nginx_user_data

  tags = {
    Name = "${var.project}-app"
    Role = "app"
  }
}

############################################
# Outputs
############################################
output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "app_public_ip" {
  value = aws_instance.app.public_ip
}

output "jenkins_url_nginx" {
  value = "http://${aws_instance.jenkins.public_ip}"
}

output "app_url_nginx" {
  value = "http://${aws_instance.app.public_ip}"
}