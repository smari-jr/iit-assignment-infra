variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# Public subnet CIDRs (for load balancers and NAT gateways)
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

# App subnet CIDRs (for EKS worker nodes)
variable "app_subnet_cidrs" {
  description = "CIDR blocks for app subnets"
  type        = list(string)
  default     = ["10.0.32.0/20", "10.0.48.0/20"]
}

# Database subnet CIDRs (for RDS)
variable "db_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.64.0/20", "10.0.80.0/20"]
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

# RDS Configuration
variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "db_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Specifies the value for Storage Autoscaling"
  type        = number
  default     = 100
}

variable "db_engine" {
  description = "The database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "15.4"
}

variable "db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = true
}

# Bastion Host Configuration
variable "enable_bastion" {
  description = "Enable bastion host for secure access"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "Name of the AWS key pair for SSH access to bastion host"
  type        = string
}

variable "bastion_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access bastion host via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Monitoring Configuration
variable "enable_monitoring_alerts" {
  description = "Enable CloudWatch alarms and SNS notifications for monitoring"
  type        = bool
  default     = false
}

variable "monitoring_alert_email" {
  description = "Email address to receive monitoring alerts"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable Container Insights for EKS cluster monitoring"
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
