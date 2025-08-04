# Three-Tier Architecture on AWS EKS with OIDC and Add-ons

This repository contains Terraform configurations to deploy a production-ready three-tier architecture on Amazon EKS with comprehensive OIDC provider and add-ons configuration in Singapore region (ap-southeast-1).

## 🏗️ Architecture Overview

### Network Architecture
- **VPC**: 10.0.0.0/16 CIDR block
- **Availability Zones**: ap-southeast-1a and ap-southeast-1b
- **Subnets** (All /20 subnets):
  - **Public Subnets**: 10.0.0.0/20, 10.0.16.0/20 (for Load Balancers)
  - **App Subnets**: 10.0.32.0/20, 10.0.48.0/20 (for EKS worker nodes - PRIVATE)
  - **DB Subnets**: 10.0.64.0/20, 10.0.80.0/20 (for RDS instances - PRIVATE)

### 🔒 Security Features
- **Private EKS Cluster**: Control plane endpoints in private subnets
- **Bastion Host Access**: Secure jump server for cluster management
- **OIDC Provider**: IAM Roles for Service Accounts (IRSA) enabled
- **Pod Identity Agent**: Modern AWS authentication method
- **Network Isolation**: Proper security group configurations

### 🚀 Production Capabilities
- **OIDC Integration**: Zero-credential AWS service integration
- **Auto Scaling**: Cluster Autoscaler for node management
- **Load Balancing**: AWS Load Balancer Controller for ingress
- **Storage Options**: EBS and EFS CSI drivers with multiple storage classes
- **Monitoring**: CloudWatch logging and VPC Flow Logs

## 📦 Components

### Infrastructure Tiers
1. **Presentation Tier**: AWS Load Balancer (automatic provisioning via controller)
2. **Application Tier**: EKS cluster with worker nodes in private subnets
3. **Data Tier**: RDS PostgreSQL database in private database subnets
4. **Management Tier**: Bastion host for secure access

### EKS Add-ons (All Active)
- ✅ `aws-ebs-csi-driver` - Persistent volume storage with IRSA
- ✅ `aws-efs-csi-driver` - Shared file system storage with IRSA
- ✅ `coredns` - DNS resolution within cluster
- ✅ `eks-pod-identity-agent` - Modern AWS authentication
- ✅ `kube-proxy` - Network proxy for services
- ✅ `vpc-cni` - Container networking interface

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- kubectl installed (for EKS cluster management)
- **AWS EC2 Key Pair** created in Singapore region (for bastion host SSH access)

## Required AWS Permissions

Ensure your AWS credentials have the following permissions:
- EC2 (VPC, Subnets, Security Groups, NAT Gateways, Key Pairs, etc.)
- EKS (Cluster and Node Group management)
- RDS (Database instance management)
- IAM (Role and Policy management)
- CloudWatch (Logging)
- Systems Manager (for Session Manager access to bastion host)

## Directory Structure

```
terraform/
├── modules/
│   ├── network/          # VPC, subnets, routing configuration
│   ├── eks/             # EKS cluster and node group configuration
│   ├── rds/             # RDS database configuration
│   └── bastion/         # Bastion host for secure access
├── main.tf              # Main configuration file
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── providers.tf         # Provider configurations
├── terraform.tfvars.dev     # Development environment variables
├── terraform.tfvars.staging # Staging environment variables
└── terraform.tfvars.prod    # Production environment variables
```

## Deployment Instructions

### 1. Clone and Navigate to the Directory
```bash
cd /path/to/your/terraform/directory
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Choose Your Environment

#### For Development Environment:
```bash
# Plan the deployment
terraform plan -var-file="terraform.tfvars.dev"

# Apply the configuration
terraform apply -var-file="terraform.tfvars.dev"
```

#### For Staging Environment:
```bash
# Plan the deployment
terraform plan -var-file="terraform.tfvars.staging"

# Apply the configuration
terraform apply -var-file="terraform.tfvars.staging"
```

#### For Production Environment:
```bash
# Plan the deployment
terraform plan -var-file="terraform.tfvars.prod"

# Apply the configuration
terraform apply -var-file="terraform.tfvars.prod"
```

### 4. Configure kubectl for EKS
After successful deployment, configure kubectl to connect to your EKS cluster:

```bash
# The command will be output by Terraform, but generally it's:
aws eks --region ap-southeast-1 update-kubeconfig --name three-tier-app-<environment>-eks
```

### 5. Verify the Deployment
```bash
# Check EKS cluster
kubectl get nodes

# Check cluster info
kubectl cluster-info
```

## Environment-Specific Configurations

### Development Environment (`terraform.tfvars.dev`)
- **EKS**: 2 t3.medium nodes (1-4 scaling)
- **RDS**: db.t3.micro, Single-AZ, 3-day backup retention
- **Cost-optimized** for development use

### Staging Environment (`terraform.tfvars.staging`)
- **EKS**: 2 t3.medium nodes (1-6 scaling)  
- **RDS**: db.t3.small, Multi-AZ, 7-day backup retention
- **Production-like** configuration for testing

### Production Environment (`terraform.tfvars.prod`)
- **EKS**: 3 t3.large nodes (2-10 scaling)
- **RDS**: db.r5.large, Multi-AZ, 30-day backup retention
- **High availability** and performance optimized

## Security Features

- **Network Isolation**: Separate subnets for each tier
- **Private Subnets**: Application and database tiers in private subnets
- **Security Groups**: Restrictive rules for each component
- **RDS Encryption**: Storage encryption enabled
- **EKS Security**: RBAC enabled, private endpoint available
- **VPC Flow Logs**: Network traffic monitoring

## Monitoring and Logging

- **EKS Control Plane Logs**: API, audit, authenticator, controller manager, scheduler
- **VPC Flow Logs**: Network traffic analysis
- **RDS Enhanced Monitoring**: Database performance metrics
- **CloudWatch Integration**: Centralized logging and monitoring

## Bastion Host Access

The infrastructure includes a bastion host (jump server) for secure access to private resources:

### Features
- **Secure Access**: SSH and AWS Session Manager access
- **Pre-installed Tools**: kubectl, eksctl, helm, k9s, AWS CLI v2
- **Automated Scripts**: Ready-to-use scripts for EKS and RDS connections
- **High Availability**: Auto Scaling Group ensures bastion is always available
- **Monitoring**: CloudWatch logs and metrics collection

### Connecting to Bastion Host

#### Option 1: SSH Access (requires key pair)
```bash
# Get bastion public IP
aws ec2 describe-instances --region ap-southeast-1 \
  --filters 'Name=tag:Name,Values=*bastion*' \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]' \
  --output table

# Connect via SSH
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>
```

#### Option 2: AWS Session Manager (no key pair needed)
```bash
# Get instance ID
aws ec2 describe-instances --region ap-southeast-1 \
  --filters 'Name=tag:Name,Values=*bastion*' \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text

# Connect via Session Manager
aws ssm start-session --target <instance-id>
```

### Using Bastion Host

Once connected to the bastion host, you can use these pre-installed scripts:

```bash
# Connect to EKS cluster
./scripts/connect-eks.sh three-tier-app-dev-eks

# Connect to RDS database  
./scripts/connect-rds.sh <db-endpoint> admin app_database

# Check all AWS resources
./scripts/check-resources.sh

# Use Kubernetes UI
k9s

# Standard kubectl commands
kubectl get nodes
kubectl get pods --all-namespaces
```

## Database Connection

After deployment, you can connect to the RDS instance from within the EKS cluster:

```bash
# Connection string format (password will be in terraform output or tfvars file):
postgresql://admin:[PASSWORD]@<db-endpoint>:5432/app_database
```

## Cleanup

To destroy the infrastructure:

```bash
# For development
terraform destroy -var-file="terraform.tfvars.dev"

# For staging  
terraform destroy -var-file="terraform.tfvars.staging"

# For production
terraform destroy -var-file="terraform.tfvars.prod"
```

## Important Notes

1. **Database Passwords**: Change the database passwords in the tfvars files before deployment. Consider using AWS Secrets Manager for production.

2. **Deletion Protection**: Production environment has deletion protection enabled for RDS. You may need to disable it before destroying.

3. **State Management**: Consider using remote state backend (S3 + DynamoDB) for team collaboration.

4. **Cost Optimization**: The configuration includes auto-scaling for EKS nodes and storage auto-scaling for RDS.

5. **Security**: Review and adjust security group rules based on your application requirements.

## Troubleshooting

### Common Issues:

1. **EKS Node Group Creation Fails**: Ensure proper IAM permissions and subnet tags
2. **RDS Subnet Group Issues**: Verify subnet availability zones match
3. **kubectl Connection Issues**: Check security group rules and endpoint configuration

### Useful Commands:

```bash
# Check Terraform state
terraform state list

# Show specific resource
terraform state show module.eks.aws_eks_cluster.main

# Import existing resources (if needed)
terraform import module.network.aws_vpc.main vpc-xxxxxxxxx
```

## Support

For issues or questions:
1. Check AWS CloudWatch logs
2. Review Terraform state and outputs
3. Verify AWS resource limits and quotas
4. Check IAM permissions

## License

This Terraform configuration is provided as-is for educational and deployment purposes.
