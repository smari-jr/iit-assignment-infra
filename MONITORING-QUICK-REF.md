# 🎯 EKS Monitoring Quick Reference

## 📊 Your Dashboard
**URL**: https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=iit-test-dev-eks-dashboard

## 🔔 Alert Settings
```bash
# Get current alarm status
terraform output monitoring_alarm_arns

# SNS Topic for alerts
terraform output monitoring_sns_topic_arn
```

## ⚡ Quick Commands

### Check Current Monitoring Status
```bash
# View all monitoring resources
terraform state list | grep aws_cloudwatch

# Get dashboard URL
terraform output cloudwatch_dashboard_url

# Check alarm states
aws cloudwatch describe-alarms --region ap-southeast-1 --query 'MetricAlarms[?starts_with(AlarmName, `iit-test-dev-eks`)].{Name:AlarmName,State:StateValue,Reason:StateReason}'
```

### Enable Container Insights (Detailed Metrics)
```bash
# Connect to cluster
aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks

# Enable Container Insights
eksctl utils install-addon --name aws-cloudwatch-insights --cluster iit-test-dev-eks --region ap-southeast-1

# Verify installation
kubectl get pods -n amazon-cloudwatch
```

### Setup Email Alerts
1. Edit `terraform.tfvars.dev`:
   ```hcl
   monitoring_alert_email = "your-email@company.com"
   ```
2. Apply: `terraform apply -var-file="terraform.tfvars.dev" -auto-approve`
3. Confirm email subscription

## 📈 Key Metrics Being Monitored

| Metric | Threshold | Action |
|--------|-----------|--------|
| Worker Node CPU | > 80% for 10 min | Scale nodes or optimize workloads |
| EKS API Errors | > 10 errors/5min | Check cluster connectivity |
| RDS CPU | > 80% for 5 min | Optimize queries or scale DB |
| RDS Memory | < 100MB free | Increase instance size |

## 🚨 When Alarms Fire

### High CPU (Nodes)
```bash
# Check node status
kubectl top nodes
kubectl describe nodes

# Check pod resource usage
kubectl top pods --all-namespaces --sort-by=cpu
```

### API Server Errors
```bash
# Check cluster status
kubectl cluster-info
kubectl get componentstatuses

# Check recent events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Database Issues
```bash
# Check RDS metrics
aws rds describe-db-instances --db-instance-identifier iit-test-dev-db

# Check connections
aws rds describe-db-log-files --db-instance-identifier iit-test-dev-db
```

## 💡 Pro Tips

1. **Check dashboard daily** - Quick health overview
2. **Enable Container Insights** - Get pod-level metrics
3. **Set up email alerts** - Don't miss critical issues
4. **Monitor trends** - Not just current values
5. **Regular threshold reviews** - Adjust based on usage patterns

## 🔗 Quick Links
- [Full Monitoring Guide](EKS-MONITORING-GUIDE.md)
- [AWS CloudWatch Console](https://ap-southeast-1.console.aws.amazon.com/cloudwatch/)
- [Container Insights](https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#container-insights:)
