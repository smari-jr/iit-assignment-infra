output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_autoscaling_group.bastion.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.bastion.id
}

output "bastion_iam_role_arn" {
  description = "ARN of the bastion host IAM role"
  value       = aws_iam_role.bastion.arn
}

output "bastion_iam_role_name" {
  description = "Name of the bastion host IAM role"
  value       = aws_iam_role.bastion.name
}

output "bastion_launch_template_id" {
  description = "ID of the bastion host launch template"
  value       = aws_launch_template.bastion.id
}

output "bastion_autoscaling_group_name" {
  description = "Name of the bastion host auto scaling group"
  value       = aws_autoscaling_group.bastion.name
}

output "bastion_cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for bastion host"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.bastion[0].name : null
}

output "ssh_connection_command" {
  description = "SSH command to connect to bastion host (requires public IP)"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@<bastion-public-ip>"
}

output "session_manager_connection" {
  description = "AWS Session Manager connection command"
  value       = var.enable_session_manager ? "aws ssm start-session --target <instance-id>" : "Session Manager not enabled"
}

output "bastion_user_data_scripts" {
  description = "Available scripts on the bastion host"
  value = [
    "~/scripts/connect-eks.sh <cluster-name>",
    "~/scripts/connect-rds.sh <endpoint> <username> <database>",
    "~/scripts/check-resources.sh"
  ]
}
