# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.db_identifier}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "${var.db_identifier}-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.db_identifier}-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from app subnets"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.app_subnet_cidrs
  }

  # Allow access from bastion host if provided
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      description     = "PostgreSQL from bastion host"
      from_port       = var.db_port
      to_port         = var.db_port
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.db_identifier}-rds-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.db_identifier}-param-group"

  # For PostgreSQL, we'll use minimal custom parameters to avoid conflicts
  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [
      {
        name  = "log_statement"
        value = "none"
      }
    ] : []
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name        = "${var.db_identifier}-param-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Option Group (PostgreSQL doesn't use option groups like MySQL, so we'll comment this out)
# PostgreSQL uses extensions instead of option groups
# resource "aws_db_option_group" "main" {
#   name                     = "${var.db_identifier}-option-group"
#   option_group_description = "Option group for ${var.db_identifier}"
#   engine_name              = var.engine
#   major_engine_version     = "15"
# 
#   tags = {
#     Name        = "${var.db_identifier}-option-group"
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }

# Enhanced Monitoring Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.db_identifier}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.db_identifier}-rds-monitoring-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = var.db_identifier

  # Engine options
  engine         = var.engine
  engine_version = var.engine_version

  # Instance configuration
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.use_random_password ? random_password.db_password[0].result : var.db_password
  port     = var.db_port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = var.copy_tags_to_snapshot

  # High Availability
  multi_az = var.multi_az

  # Parameter group (PostgreSQL doesn't use option groups)
  parameter_group_name = aws_db_parameter_group.main.name

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

    # Performance Insights - disabled for t3.micro
  performance_insights_enabled          = false
  performance_insights_retention_period = 0

  # Maintenance and upgrades
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = var.db_identifier
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds,
    random_password.db_password,
  ]
}
