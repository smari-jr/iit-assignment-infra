# 🏗️ AWS EKS Three-Tier Infrastructure with Monitoring

A production-ready three-tier architecture on Amazon EKS with comprehensive monitoring, OIDC integration, and enterprise security features deployed in Singapore region (ap-southeast-1).

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.33-326CE5?logo=kubernetes)](https://kubernetes.io)

## 🎯 Quick Start

### **One-Command Deploy**
```bash
# Deploy development environment
cd terraform && terraform init
terraform apply -var-file="terraform.tfvars.dev" -auto-approve
```

### **Access Your Infrastructure**
```bash
# Connect to EKS cluster
aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks

# View monitoring dashboard
echo "Dashboard: https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=iit-test-dev-eks-dashboard"

# Connect to bastion host
aws ssm start-session --target $(terraform output -raw bastion_instance_id)
```

---

## 🏗️ Architecture Overview

### **Three-Tier Design**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Presentation   │    │   Application   │    │      Data       │
│     Tier        │    │      Tier       │    │      Tier       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • ALB/NLB       │───▶│ • EKS Cluster   │───▶│ • RDS PostgreSQL│
│ • CloudFront    │    │ • Auto Scaling  │    │ • Multi-AZ      │
│ • Route 53      │    │ • OIDC/IRSA     │    │ • Encrypted     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Network Architecture**
- **VPC**: `10.0.0.0/16` across 2 Availability Zones
- **Public Subnets**: `10.0.0.0/20`, `10.0.16.0/20` (Load Balancers)
- **App Subnets**: `10.0.32.0/20`, `10.0.48.0/20` (EKS Workers - Private)
- **DB Subnets**: `10.0.64.0/20`, `10.0.80.0/20` (RDS - Private)

---

## � Production Features

### **📊 Monitoring & Observability**
- **CloudWatch Dashboard**: 8-widget cluster health overview
- **Container Insights**: Pod and node level metrics
- **CloudWatch Alarms**: Proactive alerting on critical metrics
- **SNS Notifications**: Real-time alert delivery
- **Log Analytics**: Centralized application and infrastructure logs

### **🔒 Security & Compliance**
- **Private EKS Cluster**: API server in private subnets
- **OIDC Provider**: Zero-credential AWS service integration
- **Pod Identity Agent**: Modern AWS authentication
- **Network Segmentation**: Security groups and NACLs
- **Encryption**: EBS, RDS, and data in transit encryption

### **⚡ High Availability & Scaling**
- **Multi-AZ Deployment**: Across 2 availability zones
- **Cluster Autoscaler**: Automatic node scaling
- **RDS Multi-AZ**: Database failover capability
- **Load Balancer Controller**: Intelligent traffic distribution

### **🛠️ Developer Experience**
- **Bastion Host**: Pre-configured with kubectl, eksctl, k9s
- **Ready-to-use Scripts**: EKS and RDS connection helpers
- **Multiple Environments**: Dev, staging, production configs

---

## 📚 Complete Setup Guide

### **Prerequisites**
```bash
# Required tools (auto-install script available)
- AWS CLI v2
- Terraform >= 1.0  
- kubectl
- Docker (for local development)

# AWS Requirements
- Valid AWS credentials with EKS permissions
- EC2 Key Pair in ap-southeast-1 region
```

### **⚡ One-Command Tool Installation**
```bash
# Install all required tools on Amazon Linux
curl -O https://raw.githubusercontent.com/smari-jr/iit-assignment-infra/main/scripts/install-tools.sh
chmod +x install-tools.sh && ./install-tools.sh
```

### **🚀 Deploy Infrastructure**

1. **Clone & Initialize**
```bash
git clone https://github.com/smari-jr/iit-assignment-infra.git
cd iit-assignment-infra/terraform
terraform init
```

2. **Choose Environment & Deploy**
```bash
# Development (cost-optimized)
terraform apply -var-file="terraform.tfvars.dev" -auto-approve

# Staging (production-like)  
terraform apply -var-file="terraform.tfvars.staging" -auto-approve

# Production (high-availability)
terraform apply -var-file="terraform.tfvars.prod" -auto-approve
```

3. **Configure Access**
```bash
# Connect to EKS cluster
aws eks update-kubeconfig --region ap-southeast-1 --name $(terraform output -raw cluster_name)

# Verify connection
kubectl get nodes && kubectl get pods -A
```

---

## 🖥️ Access Your Infrastructure

### **📊 Monitoring Dashboard**
```bash
# Access CloudWatch Dashboard
echo "https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=$(terraform output -raw dashboard_name)"

# Available Metrics:
# • API Server Health & Response Time
# • Worker Node Capacity & Status  
# • Pod Health & Resource Usage
# • Load Balancer Performance
# • Database Connections & Performance
# • Container Insights with detailed metrics
```

### **🔐 Bastion Host Access**
```bash
# Session Manager (recommended - no SSH keys needed)
aws ssm start-session --target $(terraform output -raw bastion_instance_id)

# SSH (requires key pair)
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# Pre-installed tools: kubectl, eksctl, aws-cli, k9s, docker, psql
# Ready scripts: ./connect-eks.sh, ./connect-rds.sh, ./check-resources.sh
```

### **💾 Database Access**
```bash
# Get connection details
terraform output rds_endpoint

# Connect from bastion host
psql -h $(terraform output -raw rds_endpoint) -U admin -d app_database

# Connection string format
postgresql://admin:[PASSWORD]@$(terraform output -raw rds_endpoint):5432/app_database
```

---

## ⚙️ Environment Configurations

| Environment | EKS Nodes | RDS Instance | High Availability | Use Case |
|-------------|-----------|--------------|-------------------|----------|
| **Development** | 2x t3.medium (1-4 scale) | db.t3.micro, Single-AZ | ❌ | Cost-optimized development |
| **Staging** | 2x t3.medium (1-6 scale) | db.t3.small, Multi-AZ | ⚡ | Production-like testing |
| **Production** | 3x t3.large (2-10 scale) | db.r5.large, Multi-AZ | ✅ | High-performance production |

### **🔧 Advanced Features**

#### **Storage Classes (Auto-Configured)**
```yaml
gp3-encrypted:    # Default - General purpose SSD with encryption
gp3-fast:         # High IOPS for performance workloads  
io2-ultra:        # Ultra-high performance for critical apps
efs-storage:      # Shared filesystem for multi-pod access
```

#### **Security & Compliance**
- **Zero-credential AWS access** via OIDC/IRSA
- **Network isolation** with private subnets
- **Encryption at rest** for EBS and RDS
- **Pod-level security** isolation
- **VPC Flow Logs** for network monitoring

#### **Monitoring & Alerting**
- **Real-time dashboards** with 8 key widgets
- **Proactive alarms** for critical thresholds
- **SNS notifications** for instant alerts
- **Container Insights** for deep observability

---

## 🛠️ Development Workflow

### **Local Development**
```bash
# Port forward to services
kubectl port-forward svc/your-service 8080:80

# Access logs
kubectl logs -f deployment/your-app

# Scale applications
kubectl scale deployment your-app --replicas=3
```

### **CI/CD Integration**
```bash
# GitHub Actions can connect to public EKS API
# No VPN required for CI/CD pipelines
# Use OIDC for secure credential-less deployment
```

### **Troubleshooting**
```bash
# Check cluster health
kubectl get nodes
kubectl top nodes

# Monitor resources
k9s  # Interactive cluster management

# View detailed logs
kubectl describe pod <pod-name>
```

---

## 🧹 Cleanup

```bash
# Destroy environment (choose one)
terraform destroy -var-file="terraform.tfvars.dev"
terraform destroy -var-file="terraform.tfvars.staging"  
terraform destroy -var-file="terraform.tfvars.prod"

# Clean local kubectl config
kubectl config delete-context $(kubectl config current-context)
```

---

## 📖 Additional Resources

### **Documentation**
- [EKS Monitoring Guide](./docs/EKS-MONITORING-GUIDE.md)
- [Tools Installation Guide](./docs/TOOLS-INSTALLATION-GUIDE.md) 
- [Database Operations Guide](./docs/DATABASE-GUIDE.md)

### **Support**
- **CloudWatch Logs**: Centralized application logs
- **AWS Support**: Enterprise support for production issues
- **Community**: GitHub issues for feature requests

### **Security Notes**
1. **Change default passwords** in tfvars files before production
2. **Enable deletion protection** for production RDS instances
3. **Use AWS Secrets Manager** for credential management
4. **Review security groups** based on application requirements
5. **Enable GuardDuty** for additional threat detection

---

*✨ **Ready to deploy?** Run `terraform apply -var-file="terraform.tfvars.dev"` to get started!*
