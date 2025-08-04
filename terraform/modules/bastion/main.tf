# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name_prefix = "${var.bastion_name}-sg"
  vpc_id      = var.vpc_id

  # SSH access from allowed CIDR blocks
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.bastion_name}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for Bastion Host
resource "aws_iam_role" "bastion" {
  name = "${var.bastion_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.bastion_name}-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Policy for EKS access
resource "aws_iam_policy" "bastion_eks_access" {
  name        = "${var.bastion_name}-eks-access"
  description = "Policy for bastion host to access EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.bastion_name}-eks-access"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Policy for RDS access (optional database administration)
resource "aws_iam_policy" "bastion_rds_access" {
  name        = "${var.bastion_name}-rds-access"
  description = "Policy for bastion host to access RDS for administration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBSubnetGroups"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.bastion_name}-rds-access"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach policies to IAM role
resource "aws_iam_role_policy_attachment" "bastion_eks_access" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_eks_access.arn
}

resource "aws_iam_role_policy_attachment" "bastion_rds_access" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_rds_access.arn
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = var.enable_session_manager ? 1 : 0
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  count      = var.enable_cloudwatch_logs ? 1 : 0
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.bastion_name}-profile"
  role = aws_iam_role.bastion.name

  tags = {
    Name        = "${var.bastion_name}-profile"
    Project     = var.project_name
    Environment = var.environment
  }
}

# User Data Script for Bastion Host
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    bastion_name = var.bastion_name
  }))
}

# Launch Template for Bastion Host
resource "aws_launch_template" "bastion" {
  name_prefix   = "${var.bastion_name}-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.bastion.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = var.bastion_name
      Project     = var.project_name
      Environment = var.environment
      Type        = "Bastion"
    }
  }

  tags = {
    Name        = "${var.bastion_name}-lt"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Auto Scaling Group for Bastion Host (for high availability)
resource "aws_autoscaling_group" "bastion" {
  name                      = "${var.bastion_name}-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.bastion_name}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Type"
    value               = "Bastion"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }
}

# CloudWatch Log Group for bastion logs
resource "aws_cloudwatch_log_group" "bastion" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/ec2/bastion/${var.bastion_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.bastion_name}-logs"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Security Group Rules to allow bastion access to app and db subnets
resource "aws_security_group" "bastion_access" {
  name_prefix = "${var.bastion_name}-access-sg"
  vpc_id      = var.vpc_id

  # Allow bastion host to access EKS nodes on all ports
  egress {
    description = "Access to app subnets from bastion"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.app_subnet_cidrs
  }

  # Allow bastion host to access database subnets (PostgreSQL)
  egress {
    description = "PostgreSQL access from bastion"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.db_subnet_cidrs
  }

  # Allow HTTPS for EKS API access
  egress {
    description = "HTTPS for EKS API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.bastion_name}-access-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}
