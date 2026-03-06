# infra/modules/01-iam/main.tf

# IAM Policy JSON 생성(data source)
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role 생성 (AssumeRole 정책 포함)
resource "aws_iam_role" "bastion" {
  name               = "${var.project}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "bastion_ecr_read" {
  role      = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "bastion_eks_read" {
  role      = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSReadOnlyAccess"
}

# EC2에 Role을 붙이기 위한 Instance Profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# IAM Role 생성 (AssumeRole 정책 포함)
resource "aws_iam_role" "jenkins" {
  name               = "${var.project}-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "jenkins_ecr_power" {
  role      = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# AWS 관리형 Policy를 Role에 Attach
resource "aws_iam_role_policy_attachment" "jenkins_eks_read" {
  role      = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSReadOnlyAccess"
}

# EC2에 Role을 붙이기 위한 Instance Profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}
