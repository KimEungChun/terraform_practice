# infra/modules/01-iam/outputs.tf

output "bastion_instance_profile_name" { value = aws_iam_instance_profile.bastion.name }
output "jenkins_instance_profile_name" { value = aws_iam_instance_profile.jenkins.name }
