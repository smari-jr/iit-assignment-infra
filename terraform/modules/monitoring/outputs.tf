output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.eks_cluster.dashboard_name
}

output "dashboard_url" {
  description = "URL to access the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.eks_cluster.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.enable_sns_notifications ? aws_sns_topic.alerts[0].arn : null
}

output "alarm_arns" {
  description = "ARNs of created CloudWatch alarms"
  value = {
    high_cpu_utilization = aws_cloudwatch_metric_alarm.high_cpu_utilization.arn
    eks_api_server_errors = aws_cloudwatch_metric_alarm.eks_api_server_errors.arn
    rds_high_cpu          = aws_cloudwatch_metric_alarm.rds_high_cpu.arn
    rds_low_free_memory   = aws_cloudwatch_metric_alarm.rds_low_free_memory.arn
  }
}

output "container_insights_log_group" {
  description = "Name of the Container Insights log group"
  value       = var.enable_container_insights ? aws_cloudwatch_log_group.container_insights[0].name : null
}
