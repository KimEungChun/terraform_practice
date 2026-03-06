# infra/modules/05-eks/outputs.tf

output "cluster_name"     { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca"       { value = aws_eks_cluster.this.certificate_authority[0].data }
output "oidc_issuer"      { value = aws_eks_cluster.this.identity[0].oidc[0].issuer }
output "oidc_provider_arn" { value = try(aws_iam_openid_connect_provider.oidc[0].arn, null) }
