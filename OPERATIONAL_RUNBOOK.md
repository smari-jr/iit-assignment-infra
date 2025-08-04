# 📖 Operational Runbook - Three-Tier EKS Infrastructure

**Project**: IIT Assignment Infrastructure  
**Environment**: Multi-environment (dev/staging/prod)  
**Region**: ap-southeast-1 (Singapore)  
**Last Updated**: August 2025

---

## 📋 **Table of Contents**

1. [Infrastructure Overview](#infrastructure-overview)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Deployment Procedures](#deployment-procedures)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Operational Procedures](#operational-procedures)
6. [Monitoring & Alerting](#monitoring--alerting)
7. [Troubleshooting Guide](#troubleshooting-guide)
8. [Maintenance Procedures](#maintenance-procedures)
9. [Disaster Recovery](#disaster-recovery)
10. [Security Operations](#security-operations)

---

## 🏗️ **Infrastructure Overview**

### **Architecture Components**
```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                       │
├─────────────────────────────────────────────────────────────────┤
│ Public Subnets (10.0.0.0/20, 10.0.16.0/20)                   │
│ ├── Internet Gateway                                           │
│ ├── NAT Gateways (AZ-1a, AZ-1b)                              │
│ ├── Application Load Balancer                                 │
│ └── Bastion Host (optional)                                   │
├─────────────────────────────────────────────────────────────────┤
│ Application Subnets (10.0.32.0/20, 10.0.48.0/20)            │
│ ├── EKS Cluster (v1.33)                                      │
│ ├── Worker Nodes (t3.medium/large)                           │
│ ├── EKS Add-ons (EBS CSI, EFS CSI, CoreDNS)                 │
│ └── OIDC Provider for IRSA                                   │
├─────────────────────────────────────────────────────────────────┤
│ Database Subnets (10.0.64.0/20, 10.0.80.0/20)               │
│ └── RDS PostgreSQL (Multi-AZ)                                │
└─────────────────────────────────────────────────────────────────┘
```

### **Key Resources**
- **VPC**: Single VPC with multi-tier subnet architecture
- **EKS Cluster**: Kubernetes 1.33 with managed node groups
- **RDS**: PostgreSQL with Multi-AZ for HA
- **Monitoring**: CloudWatch Dashboard + Container Insights
- **Security**: OIDC provider, Security Groups, NACLs

---

## ✅ **Pre-Deployment Checklist**

### **1. Prerequisites Verification**
```bash
# Verify AWS CLI configuration
aws sts get-caller-identity
aws configure list

# Check required tools
terraform version    # Should be >= 1.0
kubectl version --client
eksctl version

# Verify AWS permissions
aws iam get-user
aws eks list-clusters --region ap-southeast-1
```

### **2. Environment Preparation**
```bash
# Clone repository
git clone https://github.com/smari-jr/iit-assignment-infra.git
cd iit-assignment-infra/terraform

# Verify file structure
ls -la
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend.tf
├── terraform.tfvars.dev
└── modules/
```

### **3. Configuration Review**
```bash
# Review terraform.tfvars.dev
cat terraform.tfvars.dev

# Validate Terraform configuration
terraform fmt -check
terraform validate
```

### **4. AWS Resource Limits Check**
```bash
# Check VPC limits
aws ec2 describe-vpcs --region ap-southeast-1
aws ec2 describe-vpcs --region ap-southeast-1 | jq '.Vpcs | length'

# Check EKS limits
aws eks list-clusters --region ap-southeast-1

# Check RDS limits
aws rds describe-db-instances --region ap-southeast-1
```

---

## 🚀 **Deployment Procedures**

### **Phase 1: Infrastructure Initialization**

#### **Step 1: Terraform Backend Setup**
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform with remote backend
terraform init

# Expected output:
# Terraform has been successfully initialized!
# Backend configuration loaded from backend.tf
```

#### **Step 2: Plan Review**
```bash
# Generate and review execution plan
terraform plan -var-file="terraform.tfvars.dev" -out=deployment.plan

# Review plan output for:
# - Resource counts (should show ~40-50 resources)
# - No unexpected destroys
# - Proper resource dependencies
```

### **Phase 2: Network Infrastructure Deployment**

#### **Step 3: Deploy Network Foundation**
```bash
# Deploy network module first (optional - full deployment handles dependencies)
terraform apply -target=module.network -var-file="terraform.tfvars.dev"

# Verify network resources
aws ec2 describe-vpcs --region ap-southeast-1 --filters "Name=tag:Project,Values=iit-test"
aws ec2 describe-subnets --region ap-southeast-1 --filters "Name=tag:Project,Values=iit-test"
```

### **Phase 3: Application Infrastructure Deployment**

#### **Step 4: Full Infrastructure Deployment**
```bash
# Deploy complete infrastructure
terraform apply -var-file="terraform.tfvars.dev" -auto-approve

# Monitor deployment progress (typically 15-20 minutes)
# Watch for any errors or timeouts
```

#### **Step 5: EKS Cluster Configuration**
```bash
# Configure kubectl access
aws eks update-kubeconfig --region ap-southeast-1 --name $(terraform output -raw cluster_name)

# Verify cluster connectivity
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

---

## ✅ **Post-Deployment Verification**

### **1. Infrastructure Health Checks**

#### **Network Verification**
```bash
# Verify VPC and subnets
terraform output vpc_id
terraform output public_subnet_ids
terraform output app_subnet_ids
terraform output db_subnet_ids

# Test internet connectivity from public subnets
aws ec2 describe-route-tables --region ap-southeast-1 --filters "Name=tag:Project,Values=iit-test"
```

#### **EKS Cluster Verification**
```bash
# Check cluster status
kubectl get nodes -o wide
kubectl get namespaces
kubectl get services -A

# Verify EKS add-ons
kubectl get pods -n kube-system
kubectl describe addon coredns --cluster $(terraform output -raw cluster_name)

# Test pod creation
kubectl run test-pod --image=nginx --rm -it --restart=Never -- echo "Hello EKS"
```

#### **RDS Database Verification**
```bash
# Get RDS endpoint
terraform output rds_endpoint

# Test database connectivity from bastion (if enabled)
aws ssm start-session --target $(terraform output -raw bastion_instance_id)
# Inside bastion:
psql -h $(terraform output -raw rds_endpoint) -U admin -d app_database -c "SELECT version();"
```

### **2. Security Verification**

#### **OIDC Provider Check**
```bash
# Verify OIDC provider
aws iam list-open-id-connect-providers
kubectl get sa -A | grep -E "aws|oidc"

# Test IRSA functionality
kubectl create serviceaccount test-sa
kubectl annotate serviceaccount test-sa eks.amazonaws.com/role-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/test-role
```

#### **Security Group Validation**
```bash
# Check security groups
aws ec2 describe-security-groups --region ap-southeast-1 --filters "Name=tag:Project,Values=iit-test"

# Verify network isolation
kubectl exec -it test-pod -- nslookup google.com  # Should work
kubectl exec -it test-pod -- telnet $(terraform output -raw rds_endpoint) 5432  # Should work from app pods
```

### **3. Monitoring Setup Verification**

#### **CloudWatch Dashboard**
```bash
# Get dashboard URL
terraform output dashboard_url

# Verify dashboard widgets
aws cloudwatch list-dashboards --region ap-southeast-1
aws cloudwatch get-dashboard --dashboard-name $(terraform output -raw dashboard_name) --region ap-southeast-1
```

#### **Container Insights**
```bash
# Check Container Insights
kubectl get daemonset cloudwatch-agent -n amazon-cloudwatch
kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent

# Verify log groups
aws logs describe-log-groups --region ap-southeast-1 --log-group-name-prefix "/aws/eks"
```

---

## 🔧 **Operational Procedures**

### **1. Daily Operations**

#### **Morning Health Check**
```bash
#!/bin/bash
# daily-health-check.sh

echo "=== Daily Infrastructure Health Check ==="
echo "Date: $(date)"

# Check EKS cluster
echo "1. EKS Cluster Status:"
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running | grep -v Completed

# Check RDS
echo "2. RDS Status:"
aws rds describe-db-instances --region ap-southeast-1 --db-instance-identifier $(terraform output -raw db_instance_identifier) --query 'DBInstances[0].DBInstanceStatus'

# Check CloudWatch alarms
echo "3. Active Alarms:"
aws cloudwatch describe-alarms --region ap-southeast-1 --state-value ALARM --query 'MetricAlarms[*].[AlarmName,StateReason]' --output table

# Check resource utilization
echo "4. Resource Usage:"
kubectl top nodes
kubectl top pods -A | head -10

echo "=== Health Check Complete ==="
```

#### **Application Deployment**
```bash
# Deploy application using kubectl
kubectl apply -f k8s-manifests/

# Rolling update example
kubectl set image deployment/my-app my-app=my-app:v2.0
kubectl rollout status deployment/my-app

# Verify deployment
kubectl get deployments
kubectl get services
```

### **2. Scaling Operations**

#### **EKS Node Scaling**
```bash
# Manual node scaling
aws eks update-nodegroup-config \
  --cluster-name $(terraform output -raw cluster_name) \
  --nodegroup-name $(terraform output -raw node_group_name) \
  --scaling-config minSize=2,maxSize=8,desiredSize=4 \
  --region ap-southeast-1

# Verify scaling
kubectl get nodes
aws eks describe-nodegroup --cluster-name $(terraform output -raw cluster_name) --nodegroup-name $(terraform output -raw node_group_name) --region ap-southeast-1
```

#### **Application Scaling**
```bash
# Horizontal Pod Autoscaler
kubectl autoscale deployment my-app --cpu-percent=70 --min=2 --max=10

# Manual scaling
kubectl scale deployment my-app --replicas=5

# Verify scaling
kubectl get hpa
kubectl get pods -l app=my-app
```

### **3. Database Operations**

#### **RDS Maintenance**
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw db_instance_identifier) \
  --db-snapshot-identifier "manual-snapshot-$(date +%Y%m%d-%H%M%S)" \
  --region ap-southeast-1

# List snapshots
aws rds describe-db-snapshots --db-instance-identifier $(terraform output -raw db_instance_identifier) --region ap-southeast-1

# Monitor performance
aws rds describe-db-instances --db-instance-identifier $(terraform output -raw db_instance_identifier) --region ap-southeast-1 --query 'DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass,Storage:AllocatedStorage}'
```

---

## 📊 **Monitoring & Alerting**

### **1. CloudWatch Metrics**

#### **Key Metrics to Monitor**
```bash
# EKS Cluster Metrics
- cluster/api_server_request_total
- cluster/api_server_request_duration
- node_cpu_utilization_total
- node_memory_utilization_total
- pod_cpu_utilization
- pod_memory_utilization

# RDS Metrics
- DatabaseConnections
- CPUUtilization
- FreeableMemory
- ReadLatency
- WriteLatency
```

#### **Dashboard Access**
```bash
# Access monitoring dashboard
open "$(terraform output dashboard_url)"

# CLI monitoring
aws cloudwatch get-metric-statistics \
  --namespace AWS/EKS \
  --metric-name cluster_failed_request_total \
  --dimensions Name=ClusterName,Value=$(terraform output -raw cluster_name) \
  --statistics Sum \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --region ap-southeast-1
```

### **2. Log Management**

#### **Application Logs**
```bash
# View pod logs
kubectl logs -f deployment/my-app
kubectl logs -f -l app=my-app --all-containers=true

# View logs in CloudWatch
aws logs tail /aws/eks/$(terraform output -raw cluster_name)/cluster --follow --region ap-southeast-1
```

#### **Infrastructure Logs**
```bash
# EKS control plane logs
aws logs tail /aws/eks/$(terraform output -raw cluster_name)/cluster --follow --region ap-southeast-1

# VPC Flow Logs
aws logs tail /aws/vpc/flowlogs --follow --region ap-southeast-1
```

### **3. Alert Management**

#### **Configure SNS Notifications**
```bash
# Subscribe to alerts
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region ap-southeast-1
```

---

## 🚨 **Troubleshooting Guide**

### **1. EKS Cluster Issues**

#### **Nodes Not Ready**
```bash
# Diagnose node issues
kubectl describe nodes
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node logs
kubectl logs -n kube-system -l app=aws-node
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Common fixes
kubectl delete pod -n kube-system -l app=aws-node  # Restart CNI
kubectl cordon <node-name>  # Drain problematic node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

#### **Pod Connectivity Issues**
```bash
# Check DNS resolution
kubectl exec -it test-pod -- nslookup kubernetes.default.svc.cluster.local

# Check network policies
kubectl get networkpolicies -A

# Test pod-to-pod communication
kubectl exec -it pod1 -- ping <pod2-ip>
```

### **2. RDS Database Issues**

#### **Connection Problems**
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids $(terraform output -raw rds_security_group_id) --region ap-southeast-1

# Test connectivity from bastion
aws ssm start-session --target $(terraform output -raw bastion_instance_id)
# Inside bastion:
telnet $(terraform output -raw rds_endpoint) 5432
psql -h $(terraform output -raw rds_endpoint) -U admin -d app_database

# Check RDS logs
aws rds download-db-log-file-portion \
  --db-instance-identifier $(terraform output -raw db_instance_identifier) \
  --log-file-name error/postgresql.log \
  --region ap-southeast-1
```

#### **Performance Issues**
```bash
# Check RDS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=$(terraform output -raw db_instance_identifier) \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --region ap-southeast-1
```

### **3. Network Issues**

#### **Load Balancer Problems**
```bash
# Check ALB status
kubectl get ingress -A
kubectl describe ingress <ingress-name>

# Check ALB target groups
aws elbv2 describe-target-groups --region ap-southeast-1
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region ap-southeast-1
```

#### **NAT Gateway Issues**
```bash
# Check NAT gateway status
aws ec2 describe-nat-gateways --region ap-southeast-1 --filter "Name=tag:Project,Values=iit-test"

# Check route tables
aws ec2 describe-route-tables --region ap-southeast-1 --filter "Name=tag:Project,Values=iit-test"
```

---

## 🔧 **Maintenance Procedures**

### **1. Planned Maintenance**

#### **EKS Cluster Upgrade**
```bash
# Check current version
kubectl version --short

# Plan upgrade
aws eks describe-cluster --name $(terraform output -raw cluster_name) --region ap-southeast-1

# Update terraform.tfvars.dev with new version
# cluster_version = "1.34"

# Apply upgrade
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"

# Verify upgrade
kubectl get nodes -o wide
```

#### **RDS Maintenance**
```bash
# Schedule maintenance window
aws rds modify-db-instance \
  --db-instance-identifier $(terraform output -raw db_instance_identifier) \
  --preferred-maintenance-window "sun:03:00-sun:04:00" \
  --region ap-southeast-1

# Apply pending modifications
aws rds apply-pending-maintenance-action \
  --resource-identifier $(terraform output -raw db_instance_identifier) \
  --apply-action system-update \
  --opt-in-type immediate \
  --region ap-southeast-1
```

### **2. Backup Procedures**

#### **EKS Configuration Backup**
```bash
# Backup kubectl configuration
kubectl config view --raw > eks-config-backup-$(date +%Y%m%d).yaml

# Backup all Kubernetes manifests
kubectl get all -A -o yaml > k8s-resources-backup-$(date +%Y%m%d).yaml

# Backup Terraform state
terraform show > terraform-state-backup-$(date +%Y%m%d).txt
```

#### **Database Backup**
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw db_instance_identifier) \
  --db-snapshot-identifier "backup-$(date +%Y%m%d-%H%M%S)" \
  --region ap-southeast-1

# Export database
kubectl run postgres-client --rm -it --restart=Never --image=postgres:13 -- \
pg_dump -h $(terraform output -raw rds_endpoint) -U admin -d app_database > backup-$(date +%Y%m%d).sql
```

---

## 🚑 **Disaster Recovery**

### **1. Recovery Planning**

#### **RTO/RPO Targets**
- **RTO (Recovery Time Objective)**: 4 hours
- **RPO (Recovery Point Objective)**: 1 hour
- **Backup Frequency**: Daily automated + manual snapshots

#### **Recovery Scenarios**
1. **Single AZ Failure**: Automatic failover (Multi-AZ RDS)
2. **Complete Region Failure**: Manual restore in alternate region
3. **Application Failure**: Rolling back deployments
4. **Data Corruption**: Point-in-time recovery

### **2. Recovery Procedures**

#### **EKS Cluster Recovery**
```bash
# Recreate cluster from Terraform
cd terraform
terraform destroy -target=module.eks -var-file="terraform.tfvars.dev"
terraform apply -target=module.eks -var-file="terraform.tfvars.dev"

# Restore applications
kubectl apply -f k8s-manifests/
kubectl apply -f k8s-resources-backup-$(date +%Y%m%d).yaml
```

#### **Database Recovery**
```bash
# Point-in-time recovery
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier $(terraform output -raw db_instance_identifier) \
  --target-db-instance-identifier "$(terraform output -raw db_instance_identifier)-restored" \
  --restore-time $(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --region ap-southeast-1

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "$(terraform output -raw db_instance_identifier)-restored" \
  --db-snapshot-identifier "backup-$(date +%Y%m%d-%H%M%S)" \
  --region ap-southeast-1
```

---

## 🔒 **Security Operations**

### **1. Security Monitoring**

#### **Access Auditing**
```bash
# Check CloudTrail logs
aws logs filter-log-events \
  --log-group-name CloudTrail/EKSEvents \
  --start-time $(date -d '1 day ago' +%s)000 \
  --filter-pattern "{ $.eventName = CreateCluster || $.eventName = DeleteCluster }" \
  --region ap-southeast-1

# Audit kubectl access
kubectl auth can-i --list --as=system:serviceaccount:default:my-sa
```

#### **Vulnerability Scanning**
```bash
# Scan container images
aws ecr describe-image-scan-findings \
  --repository-name my-app \
  --image-id imageTag=latest \
  --region ap-southeast-1

# Check for security updates
kubectl get nodes -o yaml | grep -i version
```

### **2. Security Incident Response**

#### **Compromise Detection**
```bash
# Check for unusual activity
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateUser \
  --start-time $(date -d '1 day ago' +%Y-%m-%d) \
  --region ap-southeast-1

# Analyze network traffic
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs \
  --filter-pattern "[srcaddr=*] action=REJECT" \
  --region ap-southeast-1
```

#### **Incident Containment**
```bash
# Isolate compromised pods
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets

# Rotate credentials
aws iam create-access-key --user-name terraform-user
aws iam delete-access-key --access-key-id <old-key> --user-name terraform-user

# Update security groups (emergency)
aws ec2 revoke-security-group-ingress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region ap-southeast-1
```

---

## 📞 **Emergency Contacts & Escalation**

### **Contact Information**
- **DevOps Team**: devops@company.com
- **Security Team**: security@company.com  
- **AWS Support**: [AWS Support Center](https://console.aws.amazon.com/support/)

### **Escalation Matrix**
1. **Level 1**: Application issues → DevOps Team
2. **Level 2**: Infrastructure issues → Cloud Architect
3. **Level 3**: Security incidents → Security Team + Management
4. **Level 4**: Critical outage → All stakeholders + AWS Support

---

## 📚 **References & Documentation**

- **Main Documentation**: [README.md](./README.md)
- **EKS Monitoring Guide**: [EKS-MONITORING-GUIDE.md](./EKS-MONITORING-GUIDE.md)
- **Tools Installation**: [TOOLS-INSTALLATION-GUIDE.md](./TOOLS-INSTALLATION-GUIDE.md)
- **AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/

---

*📝 **Document Maintenance**: This runbook should be reviewed and updated monthly or after any significant infrastructure changes.*
