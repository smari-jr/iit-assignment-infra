output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group for EKS cluster logs"
  value       = "/aws/eks/${var.cluster_name}/cluster"
}

output "node_groups" {
  description = "EKS node groups"
  value       = aws_eks_node_group.main
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = aws_security_group.node_group.id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = aws_eks_cluster.main.version
}

# IRSA IAM Role ARNs for service accounts
output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = var.enable_irsa ? aws_iam_role.ebs_csi_driver[0].arn : null
}

output "efs_csi_driver_role_arn" {
  description = "ARN of the EFS CSI driver IAM role"
  value       = var.enable_irsa ? aws_iam_role.efs_csi_driver[0].arn : null
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_irsa ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IAM role"
  value       = var.enable_irsa ? aws_iam_role.cluster_autoscaler[0].arn : null
}

# OIDC Provider URL for manual service account annotations
output "oidc_provider_url" {
  description = "The URL of the OIDC Provider"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].url : null
}

# Cluster OIDC issuer URL without https:// prefix
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
