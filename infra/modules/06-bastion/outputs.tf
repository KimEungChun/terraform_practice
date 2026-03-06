# infra/modules/06-bastion/outputs.tf

output "instance_id" { value = aws_instance.this.id }
output "public_ip"   { value = aws_instance.this.public_ip }
