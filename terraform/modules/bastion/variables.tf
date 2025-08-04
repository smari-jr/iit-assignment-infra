variable "bastion_name" {
  description = "Name of the bastion host"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where to create bastion host"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for bastion host"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "List of CIDR blocks from app subnets for security group rules"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "List of CIDR blocks from database subnets for security group rules"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access bastion host via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for bastion host"
  type        = bool
  default     = true
}

variable "enable_session_manager" {
  description = "Enable AWS Systems Manager Session Manager access"
  type        = bool
  default     = true
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for bastion host"
  type        = bool
  default     = true
}
