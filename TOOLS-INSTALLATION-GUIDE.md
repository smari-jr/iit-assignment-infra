# 🛠️ AWS EKS Tools Installer for Amazon Linux

This script automatically installs essential tools for working with AWS EKS clusters on Amazon Linux 2 or Amazon Linux 2023.

## 📦 What Gets Installed

### Core Tools
- **AWS CLI v2** - Latest version with enhanced features
- **kubectl** - Kubernetes command-line tool (latest stable)
- **eksctl** - EKS cluster management tool
- **Docker** - Container runtime

### Additional Tools (Optional)
- **Helm** - Kubernetes package manager
- **jq** - JSON processor for parsing AWS API responses
- **yq** - YAML processor for Kubernetes manifests
- **k9s** - Interactive Kubernetes CLI dashboard

### Bash Completion
- Tab completion for AWS CLI, kubectl, and eksctl
- Useful aliases (e.g., `k` for `kubectl`)

## 🚀 Quick Start

### Download and Run
```bash
# Download the script
curl -O https://raw.githubusercontent.com/your-repo/install-tools.sh

# Make it executable
chmod +x install-tools.sh

# Run the installer
./install-tools.sh
```

### Or Run Directly
```bash
curl -s https://raw.githubusercontent.com/your-repo/install-tools.sh | bash
```

## 📋 Installation Options

When you run the script, you'll see these options:

1. **All tools (recommended)** - Installs everything including additional tools
2. **AWS CLI only** - Just the AWS command-line interface
3. **kubectl only** - Just the Kubernetes CLI
4. **eksctl only** - Just the EKS management tool
5. **Docker only** - Just the container runtime
6. **Custom selection** - Choose exactly what you want

## 🔧 Manual Installation Commands

If you prefer to install tools individually:

### AWS CLI v2
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### eksctl
```bash
PLATFORM=$(uname -s)_$(uname -m)
curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
```

### Docker
```bash
# Amazon Linux 2023
sudo dnf install -y docker

# Amazon Linux 2
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker $USER
```

## ⚙️ Post-Installation Setup

### 1. Configure AWS Credentials
```bash
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., ap-southeast-1)
# - Default output format (json)
```

### 2. Test AWS Connection
```bash
aws sts get-caller-identity
aws eks list-clusters --region ap-southeast-1
```

### 3. Connect to Your EKS Cluster
```bash
# Update kubeconfig for your cluster
aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks

# Test connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### 4. Enable Docker (if installed)
```bash
# Log out and log back in, then test
docker --version
docker run hello-world
```

## 🎯 Quick Commands for Your EKS Cluster

### Cluster Management
```bash
# List clusters
eksctl get cluster --region ap-southeast-1

# Get cluster info
kubectl cluster-info

# View nodes
kubectl get nodes -o wide

# View all resources
kubectl get all --all-namespaces
```

### Monitoring and Debugging
```bash
# Use k9s for interactive dashboard
k9s

# Check cluster health
kubectl get componentstatuses

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Working with Your Applications
```bash
# Deploy an application
kubectl apply -f your-app.yaml

# Check deployment status
kubectl get deployments
kubectl describe deployment your-app

# View logs
kubectl logs -f deployment/your-app

# Port forward for testing
kubectl port-forward service/your-service 8080:80
```

## 🛡️ Security Best Practices

### AWS CLI Configuration
```bash
# Use IAM roles instead of access keys when possible
aws configure set region ap-southeast-1
aws configure set output json

# Verify current identity
aws sts get-caller-identity
```

### kubectl Security
```bash
# Check current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch contexts safely
kubectl config use-context your-cluster-context
```

## 🔍 Troubleshooting

### Common Issues

#### AWS CLI Not Found
```bash
# Check if it's in PATH
which aws
echo $PATH

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
```

#### kubectl Connection Issues
```bash
# Check kubeconfig
kubectl config view

# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks

# Test with verbose output
kubectl get nodes -v=6
```

#### Docker Permission Issues
```bash
# Check if user is in docker group
groups $USER

# Add user to docker group
sudo usermod -a -G docker $USER

# Log out and log back in, then test
docker run hello-world
```

#### eksctl Command Fails
```bash
# Check eksctl version
eksctl version

# Verify AWS credentials
aws sts get-caller-identity

# Check region configuration
aws configure get region
```

## 📊 Verification Script

Create a quick test script to verify everything works:

```bash
#!/bin/bash
echo "=== Tool Verification ==="
echo "AWS CLI: $(aws --version 2>&1)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null)"
echo "eksctl: $(eksctl version)"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not available')"
echo "Helm: $(helm version --short 2>/dev/null || echo 'Not installed')"
echo ""
echo "=== AWS Configuration ==="
aws sts get-caller-identity 2>/dev/null || echo "AWS not configured"
echo ""
echo "=== EKS Clusters ==="
aws eks list-clusters --region ap-southeast-1 2>/dev/null || echo "No access or no clusters"
```

## 📚 Additional Resources

- [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/)
- [kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [eksctl Documentation](https://eksctl.io/)
- [Docker Documentation](https://docs.docker.com/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs** - The script provides detailed output
2. **Verify prerequisites** - Ensure you have sudo access
3. **Check network connectivity** - Some downloads require internet access
4. **Review AWS permissions** - Ensure your AWS user/role has EKS access
5. **Consult documentation** - Links provided above

---

## 🎉 You're Ready!

After running this installation script, you'll have everything needed to:
- Manage AWS resources with AWS CLI
- Deploy and manage Kubernetes applications with kubectl
- Create and manage EKS clusters with eksctl  
- Build and run containers with Docker
- Monitor your cluster with k9s and other tools

Happy clustering! 🚀
