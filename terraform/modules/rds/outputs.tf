output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_port" {
  description = "The RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = aws_db_instance.main.engine_version
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.main.status
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.main.availability_zone
}

output "db_instance_multi_az" {
  description = "If the RDS instance is multi AZ enabled"
  value       = aws_db_instance.main.multi_az
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = aws_db_parameter_group.main.arn
}

# PostgreSQL doesn't use option groups, so these outputs are commented out
# output "db_option_group_id" {
#   description = "The db option group id"
#   value       = aws_db_option_group.main.id
# }

# output "db_option_group_arn" {
#   description = "The ARN of the db option group"
#   value       = aws_db_option_group.main.arn
# }

output "db_security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.rds.id
}

# Secrets Manager outputs
output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret (if enabled)"
  value       = var.use_secrets_manager || var.use_random_password ? (var.use_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].arn : aws_secretsmanager_secret.db_auto_credentials[0].arn) : null
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret (if enabled)"
  value       = var.use_secrets_manager || var.use_random_password ? (var.use_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].name : aws_secretsmanager_secret.db_auto_credentials[0].name) : null
}

output "generated_password" {
  description = "Generated database password (if random password is used)"
  value       = var.use_random_password ? random_password.db_password[0].result : null
  sensitive   = true
}
