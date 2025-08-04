# CloudWatch Dashboard for EKS Cluster Monitoring
resource "aws_cloudwatch_dashboard" "eks_cluster" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_request_count", "ClusterName", var.cluster_name],
            [".", "cluster_request_total", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EKS API Server Requests"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.cluster_name}-nodes-*", { "stat" = "Average" }],
            [".", "NetworkIn", ".", ".", { "stat" = "Sum" }],
            [".", "NetworkOut", ".", ".", { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Worker Node Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "*", { "stat" = "Average" }],
            [".", "RequestCount", ".", ".", { "stat" = "Sum" }],
            [".", "HTTPCode_Target_2XX_Count", ".", ".", { "stat" = "Sum" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "stat" = "Sum" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Application Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_identifier, { "stat" = "Average" }],
            [".", "DatabaseConnections", ".", ".", { "stat" = "Average" }],
            [".", "FreeableMemory", ".", ".", { "stat" = "Average" }],
            [".", "ReadLatency", ".", ".", { "stat" = "Average" }],
            [".", "WriteLatency", ".", ".", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Database Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/EKS", "pod_number_of_container_restarts", "ClusterName", var.cluster_name, { "stat" = "Sum" }],
            ["CWAgent", "pod_cpu_utilization_over_pod_limit", "ClusterName", var.cluster_name, { "stat" = "Average" }],
            [".", "pod_memory_utilization_over_pod_limit", ".", ".", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Pod Health Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/eks/${var.cluster_name}/cluster' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "EKS Cluster Error Logs"
          view    = "table"
        }
      },
      # Custom metrics widget for Container Insights
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["ContainerInsights", "cluster_node_count", "ClusterName", var.cluster_name],
            [".", "cluster_node_running_count", ".", "."],
            [".", "service_number_of_running_pods", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Cluster Node and Pod Counts"
          period  = 300
          stat    = "Average"
        }
      },
      # Network metrics
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/VPC", "PacketsDropped", "VPC", var.vpc_id],
            ["AWS/NATGateway", "BytesInFromDestination", "NatGatewayId", "*"],
            [".", "BytesOutToDestination", ".", "."],
            [".", "BytesInFromSource", ".", "."],
            [".", "BytesOutToSource", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Network Traffic Metrics"
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}

# CloudWatch Alarms for Critical Metrics
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "${var.cluster_name}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.enable_sns_notifications ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    AutoScalingGroupName = "${var.cluster_name}-nodes-*"
  }

  tags = {
    Name        = "${var.cluster_name}-high-cpu-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_api_server_errors" {
  alarm_name          = "${var.cluster_name}-api-server-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "cluster_failed_request_count"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors EKS API server failed requests"
  alarm_actions       = var.enable_sns_notifications ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name        = "${var.cluster_name}-api-errors-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.db_instance_identifier}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.enable_sns_notifications ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  tags = {
    Name        = "${var.db_instance_identifier}-high-cpu-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_free_memory" {
  alarm_name          = "${var.db_instance_identifier}-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"  # 100MB in bytes
  alarm_description   = "This metric monitors RDS free memory"
  alarm_actions       = var.enable_sns_notifications ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  tags = {
    Name        = "${var.db_instance_identifier}-low-memory-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SNS Topic for Alerts (Optional)
resource "aws_sns_topic" "alerts" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "${var.cluster_name}-alerts"

  tags = {
    Name        = "${var.cluster_name}-alerts"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.enable_sns_notifications && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Group for Container Insights
resource "aws_cloudwatch_log_group" "container_insights" {
  count             = var.enable_container_insights ? 1 : 0
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.cluster_name}-container-insights"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for CloudWatch Container Insights
resource "aws_iam_role" "cloudwatch_agent" {
  count = var.enable_container_insights ? 1 : 0
  name  = "${var.cluster_name}-cloudwatch-agent-role"

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
    Name        = "${var.cluster_name}-cloudwatch-agent-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  count      = var.enable_container_insights ? 1 : 0
  role       = aws_iam_role.cloudwatch_agent[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom Metrics Filter for Application Logs
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  count          = var.enable_custom_metrics ? 1 : 0
  name           = "${var.cluster_name}-error-count"
  log_group_name = "/aws/eks/${var.cluster_name}/cluster"
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "EKS/CustomMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  count          = var.enable_custom_metrics ? 1 : 0
  name           = "${var.cluster_name}-warning-count"
  log_group_name = "/aws/eks/${var.cluster_name}/cluster"
  pattern        = "WARN"

  metric_transformation {
    name      = "WarningCount"
    namespace = "EKS/CustomMetrics"
    value     = "1"
  }
}
