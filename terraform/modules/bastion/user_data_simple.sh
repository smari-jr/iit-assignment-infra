#!/bin/bash

# Update system
yum update -y

# Install essential packages
yum install -y curl wget unzip git htop vim telnet nc mysql jq postgresql15

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --update
rm -rf aws awscliv2.zip

# Install kubectl
KUBECTL_VERSION=$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
EKSCTL_VERSION=$$(curl --silent "https://api.github.com/repos/weaveworks/eksctl/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/$$EKSCTL_VERSION/eksctl_$$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k9s
curl -sS https://webinstall.dev/k9s | bash
mv ~/.local/bin/k9s /usr/local/bin/

# Create aliases
cat << 'EOF' >> /home/ec2-user/.bashrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias awsid='aws sts get-caller-identity'
export PS1='\[\033[01;32m\]\u@bastion-dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$$ '
EOF

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Create helper scripts
mkdir -p /home/ec2-user/scripts

# EKS connection script
cat << 'EOF' > /home/ec2-user/scripts/connect-eks.sh
#!/bin/bash
if [ -z "$$1" ]; then
    echo "Usage: $$0 <cluster-name> [region]"
    exit 1
fi
CLUSTER_NAME=$$1
REGION=$${2:-ap-southeast-1}
aws eks --region $$REGION update-kubeconfig --name $$CLUSTER_NAME
kubectl cluster-info
kubectl get nodes
EOF

# RDS connection script
cat << 'EOF' > /home/ec2-user/scripts/connect-rds.sh
#!/bin/bash
if [ -z "$$3" ]; then
    echo "Usage: $$0 <rds-endpoint> <username> <database-name>"
    exit 1
fi
mysql -h $$1 -u $$2 -p $$3
EOF

# Resource check script
cat << 'EOF' > /home/ec2-user/scripts/check-resources.sh
#!/bin/bash
echo "=== AWS Identity ==="
aws sts get-caller-identity
echo -e "\n=== EKS Clusters ==="
aws eks list-clusters --region ap-southeast-1
echo -e "\n=== RDS Instances ==="
aws rds describe-db-instances --region ap-southeast-1 --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' --output table
if kubectl cluster-info &> /dev/null; then
    echo -e "\n=== Kubernetes Nodes ==="
    kubectl get nodes -o wide
fi
EOF

chmod +x /home/ec2-user/scripts/*.sh
chown -R ec2-user:ec2-user /home/ec2-user/scripts
chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Install session manager plugin
yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

echo "Bastion host setup completed successfully!"
