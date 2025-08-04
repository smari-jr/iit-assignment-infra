# GitHub CI/CD Pipeline Setup for EKS Cluster

## Overview
Your EKS cluster is now configured with **public API server access** to allow GitHub Actions CI/CD pipeline to connect and deploy applications.

## Current Configuration

### EKS Cluster Access
- **Endpoint Private Access**: Enabled (for internal resources)
- **Endpoint Public Access**: Enabled (for CI/CD)
- **Public Access CIDRs**: `0.0.0.0/0` (can be restricted for better security)

### Cluster Details
- **Cluster Name**: `iit-test-dev-eks`
- **Cluster Endpoint**: `https://E3A90306CD0E52DBB29B5FA7DC21846D.gr7.ap-southeast-1.eks.amazonaws.com`
- **Region**: `ap-southeast-1`
- **Version**: `1.33`

## GitHub Actions Configuration

### 1. Required Secrets in GitHub Repository

Set these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

```yaml
AWS_ACCESS_KEY_ID: <your-access-key>
AWS_SECRET_ACCESS_KEY: <your-secret-key>
AWS_REGION: ap-southeast-1
EKS_CLUSTER_NAME: iit-test-dev-eks
```

### 2. IAM User/Role for GitHub Actions

Create an IAM user or role with the following policies:
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- Custom policy for EKS cluster access:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. Sample GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to EKS

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  AWS_REGION: ap-southeast-1
  EKS_CLUSTER_NAME: iit-test-dev-eks
  ECR_REPOSITORY: your-app-repo

jobs:
  deploy:
    name: Deploy to EKS
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2
    
    - name: Build, tag, and push image to Amazon ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: ${{ env.ECR_REPOSITORY }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Build a docker container and push it to ECR
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT
    
    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
    
    - name: Deploy to EKS
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: ${{ env.ECR_REPOSITORY }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Update deployment image
        kubectl set image deployment/your-app-deployment your-app-container=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        
        # Wait for deployment to complete
        kubectl rollout status deployment/your-app-deployment
        
        # Get deployment status
        kubectl get services -o wide
```

## Security Recommendations

### 1. Restrict Public Access CIDRs

Instead of allowing all IPs (`0.0.0.0/0`), restrict to GitHub Actions IP ranges:

Update `terraform.tfvars.dev`:
```hcl
# GitHub Actions IP ranges (update periodically)
eks_public_access_cidrs = [
  "192.30.252.0/22",
  "185.199.108.0/22",
  "140.82.112.0/20",
  "143.55.64.0/20",
  "20.201.28.151/32",
  "20.205.243.166/32",
  "20.87.225.212/32",
  "20.248.137.48/32",
  "20.207.73.82/32",
  "20.27.177.113/32",
  "20.200.245.247/32",
  "20.233.54.53/32"
]
```

### 2. Use OIDC Provider (Recommended)

For enhanced security, use GitHub OIDC instead of static keys:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT-ID:role/GitHubActionsRole
    role-session-name: GitHubActions
    aws-region: ${{ env.AWS_REGION }}
```

### 3. Network-Level Security Options

#### Option A: VPN Connection (Most Secure)
- Set up AWS Client VPN
- Configure GitHub Actions to connect via VPN
- Keep EKS API private-only

#### Option B: NAT Gateway with Bastion (Hybrid)
- Use your existing bastion host as a jump server
- Configure GitHub Actions to tunnel through bastion
- Keep EKS API private-only

#### Option C: AWS CodeBuild (Alternative)
- Use AWS CodeBuild triggered by GitHub webhooks
- CodeBuild runs in your VPC with private access
- Most secure but requires additional setup

## Database Connection from Applications

Your RDS PostgreSQL database is accessible from:
- **Endpoint**: `iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com:5432`
- **Database**: `app_database`
- **Username**: `dbadmin`

Use Kubernetes secrets to store database credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  DB_HOST: "iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com"
  DB_PORT: "5432"
  DB_NAME: "app_database"
  DB_USERNAME: "dbadmin"
  DB_PASSWORD: "your-secure-password"
```

## Testing the Setup

1. **Test kubectl access from GitHub Actions**:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

2. **Verify cluster connectivity**:
```bash
aws eks describe-cluster --name iit-test-dev-eks --region ap-southeast-1
```

3. **Check service endpoints**:
```bash
kubectl get svc --all-namespaces
```

## Monitoring and Troubleshooting

### Common Issues:
1. **Authentication errors**: Check IAM permissions and AWS credentials
2. **Network timeouts**: Verify security groups and public access CIDRs
3. **kubectl errors**: Ensure kubeconfig is properly updated

### Debugging Commands:
```bash
# Check cluster status
aws eks describe-cluster --name iit-test-dev-eks

# Verify authentication
aws sts get-caller-identity

# Test cluster connectivity
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide
```

## Cost Optimization Notes

- Public API server access doesn't incur additional costs
- Consider using t3.medium instances for worker nodes in development
- Monitor data transfer costs if restricting to specific IP ranges
- Use spot instances for non-production workloads

---

This setup provides a balance between security and accessibility for your CI/CD pipeline. For production environments, consider implementing additional security measures like OIDC authentication and IP restrictions.
