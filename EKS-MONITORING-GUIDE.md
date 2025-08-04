# EKS Cluster Monitoring Setup Guide

## Overview
Your EKS cluster now has comprehensive CloudWatch monitoring with dashboards, alarms, and log analytics. This guide shows you how to access and use the monitoring features.

## 🎯 What Was Created

### ✅ CloudWatch Dashboard
- **Name**: `iit-test-dev-eks-dashboard`
- **URL**: https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=iit-test-dev-eks-dashboard

### ✅ CloudWatch Alarms
- **High CPU Utilization**: Triggers when worker nodes exceed 80% CPU
- **EKS API Server Errors**: Triggers when API errors exceed 10 per 5-minute period
- **RDS High CPU**: Triggers when database CPU exceeds 80%
- **RDS Low Memory**: Triggers when database free memory drops below 100MB

### ✅ SNS Topic for Alerts
- **Topic ARN**: `arn:aws:sns:ap-southeast-1:036160411895:iit-test-dev-eks-alerts`
- **Purpose**: Sends notifications when alarms trigger

### ✅ Container Insights Log Group
- **Log Group**: `/aws/containerinsights/iit-test-dev-eks/performance`
- **Retention**: 7 days
- **Purpose**: Stores detailed container and pod metrics

### ✅ Custom Log Metrics
- **Error Count**: Tracks ERROR patterns in EKS logs
- **Warning Count**: Tracks WARN patterns in EKS logs

## 📊 Dashboard Widgets

### 1. EKS API Server Requests
Monitors cluster API server health and request patterns:
- Failed request count
- Total request count
- 5-minute intervals

### 2. Worker Node Metrics
Tracks EC2 instances running your EKS worker nodes:
- CPU utilization
- Network In/Out
- Instance-level performance

### 3. Application Load Balancer Metrics
Application-level traffic monitoring:
- Response times
- Request counts
- HTTP status codes (2XX, 4XX, 5XX)

### 4. RDS Database Metrics
PostgreSQL database performance:
- CPU utilization
- Active database connections
- Available memory
- Read/Write latency

### 5. Pod Health Metrics
Container-level monitoring (requires Container Insights):
- Pod restart counts
- CPU utilization over limits
- Memory utilization over limits

### 6. EKS Cluster Error Logs
Real-time error log analysis:
- Recent ERROR messages
- Timestamp-sorted view
- Last 100 error entries

### 7. Cluster Node and Pod Counts
Infrastructure overview:
- Total node count
- Running node count
- Running pod count

### 8. Network Traffic Metrics
VPC and NAT Gateway monitoring:
- VPC packet drops
- NAT Gateway data transfer
- Network throughput patterns

## 🚀 Accessing Your Monitoring

### 1. CloudWatch Dashboard
```bash
# Get the dashboard URL from Terraform output
terraform output cloudwatch_dashboard_url
```

Direct link: https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=iit-test-dev-eks-dashboard

### 2. CloudWatch Console Navigation
1. Go to AWS Console → CloudWatch
2. Select "Dashboards" from left menu
3. Click on "iit-test-dev-eks-dashboard"

### 3. Container Insights (Enhanced Monitoring)
1. Go to CloudWatch → Container Insights
2. Select "EKS Clusters"
3. Choose "iit-test-dev-eks"
4. View detailed pod and node metrics

## 📈 Setting Up Container Insights

To get the most detailed metrics, enable Container Insights on your EKS cluster:

### Option 1: Using eksctl (Recommended)
```bash
# Connect to your EKS cluster
aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks

# Enable Container Insights
eksctl utils install-addon --name aws-cloudwatch-insights --cluster iit-test-dev-eks --region ap-southeast-1
```

### Option 2: Manual Installation
```bash
# Install CloudWatch agent and Fluent Bit
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml

kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluentd/fluentd-daemonset-cloudwatch.yaml
```

### Verify Container Insights Installation
```bash
# Check if pods are running
kubectl get pods -n amazon-cloudwatch

# Expected output should show:
# - cloudwatch-agent-xxx (DaemonSet)
# - fluentd-cloudwatch-xxx (DaemonSet)
```

## 🔔 Setting Up Email Alerts

To receive email notifications when alarms trigger:

### 1. Update Terraform Configuration
Edit `terraform.tfvars.dev`:
```hcl
# Enable email notifications
enable_monitoring_alerts = true
monitoring_alert_email   = "your-email@example.com"
```

### 2. Apply Changes
```bash
terraform apply -var-file="terraform.tfvars.dev" -auto-approve
```

### 3. Confirm Subscription
- Check your email for AWS SNS subscription confirmation
- Click the confirmation link

## 📋 Common Monitoring Tasks

### Check Cluster Health
```bash
# From your bastion host or local machine
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods --all-namespaces
```

### View Recent Logs
```bash
# EKS cluster logs
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/iit-test-dev-eks"

# Container insights logs
aws logs describe-log-groups --log-group-name-prefix "/aws/containerinsights/iit-test-dev-eks"
```

### Check Alarm Status
```bash
# List all alarms
aws cloudwatch describe-alarms --region ap-southeast-1

# Check specific alarm
aws cloudwatch describe-alarms --alarm-names "iit-test-dev-eks-high-cpu-utilization"
```

## 🎛️ Customizing Your Dashboard

### Adding New Widgets
1. Go to your dashboard in CloudWatch
2. Click "Edit" → "Add widget"
3. Choose widget type (Line, Number, Log table, etc.)
4. Configure metrics and parameters
5. Save changes

### Useful Additional Metrics
```json
{
  "metrics": [
    ["AWS/EKS", "cluster_node_count", "ClusterName", "iit-test-dev-eks"],
    ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", "*"],
    ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "iit-test-dev-db"]
  ]
}
```

## 🔧 Troubleshooting

### Dashboard Shows No Data
1. **Container Insights not enabled**: Follow setup steps above
2. **Permissions issues**: Check IAM roles have CloudWatch permissions
3. **Metrics not available yet**: Wait 5-10 minutes for initial data

### Alarms Not Triggering
1. **Check alarm configuration**: Verify thresholds are appropriate
2. **SNS topic permissions**: Ensure topic can deliver messages
3. **Email subscription**: Confirm subscription is active

### Missing Pod Metrics
1. **Container Insights required**: Install CloudWatch agent
2. **Namespace permissions**: Check service account permissions
3. **Resource limits**: Ensure pods have resource requests/limits set

## 💰 Cost Optimization

### Current Setup Costs (Estimated)
- **Basic CloudWatch**: ~$3-5/month
- **Container Insights**: ~$10-15/month
- **Log retention (7 days)**: ~$1-2/month
- **Custom metrics**: ~$0.30 per metric/month

### Cost Reduction Tips
1. **Reduce log retention**: Change from 7 to 3 days
2. **Filter unnecessary logs**: Use log filters to reduce ingestion
3. **Selective metrics**: Disable unused Container Insights features
4. **Dashboard optimization**: Remove widgets you don't actively use

### Update Log Retention
```bash
# Reduce to 3 days to save costs
aws logs put-retention-policy --log-group-name "/aws/containerinsights/iit-test-dev-eks/performance" --retention-in-days 3
```

## 📚 Additional Resources

### AWS Documentation
- [Container Insights for EKS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-logs.html)
- [CloudWatch Dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)

### Monitoring Best Practices
- Set up alerts for critical metrics only
- Use composite alarms for complex conditions
- Regular review and adjustment of thresholds
- Monitor trends, not just current values
- Include business metrics alongside infrastructure metrics

---

## ✅ Quick Start Checklist

- [ ] Access dashboard URL: https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=iit-test-dev-eks-dashboard
- [ ] Enable Container Insights for detailed pod metrics
- [ ] Set up email notifications for critical alarms
- [ ] Test alarm notifications
- [ ] Customize dashboard with additional widgets
- [ ] Set up log retention policies
- [ ] Review and optimize costs monthly

Your EKS cluster monitoring is now fully operational! 🎉
