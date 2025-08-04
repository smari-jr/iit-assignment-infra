# Option 1: Use AWS Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  count       = var.use_secrets_manager ? 1 : 0
  name        = "${var.db_identifier}-credentials"
  description = "Database credentials for ${var.db_identifier}"

  tags = {
    Name        = "${var.db_identifier}-credentials"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# Option 2: Generate random password and store in Secrets Manager
resource "random_password" "db_password" {
  count   = var.use_random_password ? 1 : 0
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_auto_credentials" {
  count       = var.use_random_password ? 1 : 0
  name        = "${var.db_identifier}-auto-credentials"
  description = "Auto-generated database credentials for ${var.db_identifier}"

  tags = {
    Name        = "${var.db_identifier}-auto-credentials"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_auto_credentials" {
  count     = var.use_random_password ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_auto_credentials[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password[0].result
  })
}

# Update RDS instance to use appropriate credentials
locals {
  db_password = var.use_random_password ? random_password.db_password[0].result : var.db_password
}
