# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.network.vpc_cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "IDs of the app subnets"
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.network.db_subnet_ids
}

# EKS Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = module.eks.oidc_provider_arn
}

# IRSA IAM Role ARNs for service accounts
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.eks.aws_load_balancer_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IAM role"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = module.eks.ebs_csi_driver_role_arn
}

output "efs_csi_driver_role_arn" {
  description = "ARN of the EFS CSI driver IAM role"
  value       = module.eks.efs_csi_driver_role_arn
}

# RDS Outputs
output "db_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_port" {
  description = "The RDS instance port"
  value       = module.rds.db_instance_port
}

output "db_instance_name" {
  description = "The database name"
  value       = module.rds.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.rds.db_instance_username
  sensitive   = true
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.rds.db_instance_engine
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

# Connection Information
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${local.cluster_name}"
}

output "database_connection_string" {
  description = "Database connection information"
  value       = "postgresql://${var.db_username}:[PASSWORD]@${module.rds.db_instance_endpoint}:${module.rds.db_instance_port}/${var.db_name}"
  sensitive   = true
}

# Bastion Host Outputs
output "bastion_enabled" {
  description = "Whether bastion host is enabled"
  value       = var.enable_bastion
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_security_group_id : null
}

output "bastion_iam_role_arn" {
  description = "IAM role ARN of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_iam_role_arn : null
}

output "bastion_connection_info" {
  description = "Information on how to connect to the bastion host"
  value = var.enable_bastion ? {
    ssh_command     = "ssh -i ~/.ssh/${var.bastion_key_name}.pem ec2-user@<bastion-public-ip>"
    session_manager = "aws ssm start-session --target <instance-id>"
    available_scripts = [
      "~/scripts/connect-eks.sh ${local.cluster_name}",
      "~/scripts/connect-rds.sh ${module.rds.db_instance_endpoint} ${var.db_username} ${var.db_name}",
      "~/scripts/check-resources.sh"
    ]
  } : null
}

output "bastion_instance_commands" {
  description = "Useful commands to run on bastion host"
  value = var.enable_bastion ? [
    "# Connect to EKS cluster:",
    "./scripts/connect-eks.sh ${local.cluster_name}",
    "",
    "# Connect to RDS database:",
    "./scripts/connect-rds.sh ${module.rds.db_instance_endpoint} ${var.db_username} ${var.db_name}",
    "",
    "# Check all resources:",
    "./scripts/check-resources.sh",
    "",
    "# Use k9s for Kubernetes UI:",
    "k9s",
    "",
    "# Direct kubectl commands:",
    "kubectl get nodes",
    "kubectl get pods --all-namespaces"
  ] : null
}

# Monitoring Outputs
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to access the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

output "monitoring_sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = module.monitoring.sns_topic_arn
}

output "monitoring_alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value       = module.monitoring.alarm_arns
}
