# Local values for common naming and tagging
locals {
  cluster_name  = "${var.project_name}-${var.environment}-eks"
  db_identifier = "${var.project_name}-${var.environment}-db"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Network Module
module "network" {
  source = "./modules/network"

  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  project_name        = var.project_name
  environment         = var.environment
  region              = var.aws_region
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name              = local.cluster_name
  cluster_version           = var.cluster_version
  vpc_id                    = module.network.vpc_id
  app_subnet_ids            = module.network.app_subnet_ids
  node_group_name           = "${local.cluster_name}-nodes"
  node_instance_types       = var.node_instance_types
  node_desired_size         = var.node_desired_size
  node_max_size             = var.node_max_size
  node_min_size             = var.node_min_size
  node_disk_size            = var.node_disk_size
  project_name              = var.project_name
  environment               = var.environment
  enable_bastion_access     = var.enable_bastion
  bastion_security_group_id = var.enable_bastion ? module.bastion[0].bastion_security_group_id : null
  public_access_cidrs       = var.eks_public_access_cidrs

  depends_on = [module.network, module.bastion]
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  db_identifier           = local.db_identifier
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  vpc_id                  = module.network.vpc_id
  db_subnet_ids           = module.network.db_subnet_ids
  app_subnet_cidrs        = var.app_subnet_cidrs
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.enable_deletion_protection
  project_name            = var.project_name
  environment             = var.environment
  bastion_security_group_id = var.enable_bastion ? module.bastion[0].bastion_security_group_id : null

  depends_on = [module.network, module.bastion]
}

# Bastion Host Module
module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "./modules/bastion"

  bastion_name        = "${var.project_name}-${var.environment}-bastion"
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  instance_type       = var.bastion_instance_type
  key_name            = var.bastion_key_name
  allowed_cidr_blocks = var.bastion_allowed_cidr_blocks
  project_name        = var.project_name
  environment         = var.environment

  depends_on = [module.network]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name            = local.cluster_name
  aws_region              = var.aws_region
  project_name            = var.project_name
  environment             = var.environment
  db_instance_identifier  = local.db_identifier
  vpc_id                  = module.network.vpc_id
  enable_sns_notifications = var.enable_monitoring_alerts
  alert_email             = var.monitoring_alert_email
  enable_container_insights = var.enable_container_insights
  log_retention_days      = var.log_retention_days
  enable_custom_metrics   = var.enable_custom_metrics

  depends_on = [module.eks, module.rds]
}
