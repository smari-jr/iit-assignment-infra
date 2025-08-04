variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for network monitoring"
  type        = string
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for alarms"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable Container Insights for EKS"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "enable_custom_metrics" {
  description = "Enable custom metrics from log patterns"
  type        = bool
  default     = true
}

# Alarm thresholds
variable "cpu_threshold" {
  description = "CPU utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "rds_memory_threshold" {
  description = "RDS free memory threshold in bytes"
  type        = number
  default     = 100000000  # 100MB
}

variable "api_error_threshold" {
  description = "EKS API server error count threshold"
  type        = number
  default     = 10
}
