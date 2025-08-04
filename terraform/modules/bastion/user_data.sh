#!/bin/bash

# Update system
yum update -y

# Install essential packages
yum install -y curl wget unzip git htop vim telnet nc mysql jq postgresql15

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --update
rm -rf aws awscliv2.zip

# Install kubectl (latest stable version)
KUBECTL_VERSION=$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl (AWS EKS management tool)
EKSCTL_VERSION=$$(curl --silent "https://api.github.com/repos/weaveworks/eksctl/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/$$EKSCTL_VERSION/eksctl_$$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install helm (Kubernetes package manager)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k9s (Interactive Kubernetes UI)
curl -sS https://webinstall.dev/k9s | bash
mv ~/.local/bin/k9s /usr/local/bin/

# Install kubectx and kubens (Kubernetes context and namespace switcher)
curl -L https://github.com/ahmetb/kubectx/releases/latest/download/kubectx -o /usr/local/bin/kubectx
curl -L https://github.com/ahmetb/kubectx/releases/latest/download/kubens -o /usr/local/bin/kubens
chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

# Install kustomize (Kubernetes native configuration management)
KUSTOMIZE_VERSION=$$(curl --silent "https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest" | grep '"tag_name":' | sed -E 's/.*"kustomize\/v([^"]+)".*/\1/')
curl -L "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$$KUSTOMIZE_VERSION/kustomize_v$${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/kustomize /usr/local/bin/

# Install stern (Multi-pod log viewer)
STERN_VERSION=$$(curl --silent "https://api.github.com/repos/stern/stern/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -L "https://github.com/stern/stern/releases/download/v$$STERN_VERSION/stern_$${STERN_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/stern /usr/local/bin/

# Install kubectl-tree (Show hierarchy of Kubernetes objects)
KUBECTL_TREE_VERSION=$$(curl --silent "https://api.github.com/repos/ahmetb/kubectl-tree/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -L "https://github.com/ahmetb/kubectl-tree/releases/download/v$$KUBECTL_TREE_VERSION/kubectl-tree_v$${KUBECTL_TREE_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/kubectl-tree /usr/local/bin/

# Create aliases
cat << 'EOF' >> /home/ec2-user/.bashrc
# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kgns='kubectl get namespaces'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias klo='kubectl logs'
alias kex='kubectl exec -it'

# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dlog='docker logs'

# AWS aliases
alias awsid='aws sts get-caller-identity'

# Kubernetes tools aliases
alias kctx='kubectx'
alias kns='kubens'
alias ktree='kubectl tree'

# Enhanced prompt
export PS1='\[\033[01;32m\]\u@bastion-dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$$ '

# Kubectl completion
source <(kubectl completion bash)
complete -F __start_kubectl k

# Enable kubectl and helm autocompletion
source <(helm completion bash)
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

# RDS connection script (PostgreSQL)
cat << 'EOF' > /home/ec2-user/scripts/connect-rds.sh
#!/bin/bash
if [ -z "$$3" ]; then
    echo "Usage: $$0 <rds-endpoint:port> <username> <database-name>"
    echo "Example: $$0 mydb.cluster-xyz.ap-southeast-1.rds.amazonaws.com:5432 admin app_database"
    exit 1
fi
# Extract host and port from endpoint
ENDPOINT=$$1
HOST=$${ENDPOINT%:*}
PORT=$${ENDPOINT##*:}
if [ "$$HOST" = "$$PORT" ]; then
    PORT=5432  # Default PostgreSQL port
fi
echo "Connecting to PostgreSQL at $$HOST:$$PORT..."
psql -h $$HOST -p $$PORT -U $$2 -d $$3
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

# Docker helper script
cat << 'EOF' > /home/ec2-user/scripts/docker-info.sh
#!/bin/bash
echo "=== Docker Version ==="
docker --version
echo -e "\n=== Docker Status ==="
systemctl status docker --no-pager
echo -e "\n=== Docker Images ==="
docker images
echo -e "\n=== Running Containers ==="
docker ps
echo -e "\n=== All Containers ==="
docker ps -a
EOF

# Kubernetes helper script
cat << 'EOF' > /home/ec2-user/scripts/k8s-tools.sh
#!/bin/bash
echo "=== Kubernetes Tools Versions ==="
echo "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'Not connected to cluster')"
echo "eksctl: $(eksctl version)"
echo "helm: $(helm version --short)"
echo "k9s: $(k9s version --short 2>/dev/null || echo 'k9s installed')"
echo "kubectx: $(kubectx --version 2>/dev/null || echo 'kubectx installed')"
echo "kubens: $(kubens --version 2>/dev/null || echo 'kubens installed')"
echo "kustomize: $(kustomize version --short 2>/dev/null || echo 'kustomize installed')"
echo "stern: $(stern --version 2>/dev/null || echo 'stern installed')"
echo "kubectl-tree: $(kubectl-tree --version 2>/dev/null || echo 'kubectl-tree installed')"

if kubectl cluster-info &> /dev/null; then
    echo -e "\n=== Current Kubernetes Context ==="
    kubectl config current-context
    echo -e "\n=== Available Contexts ==="
    kubectl config get-contexts
    echo -e "\n=== Current Namespace ==="
    kubectl config view --minify --output 'jsonpath={..namespace}' | xargs echo
    echo -e "\n=== Cluster Nodes ==="
    kubectl get nodes -o wide
    echo -e "\n=== All Namespaces ==="
    kubectl get namespaces
else
    echo -e "\n=== Not connected to any Kubernetes cluster ==="
    echo "Use: ./connect-eks.sh <cluster-name> to connect"
fi
EOF

chmod +x /home/ec2-user/scripts/*.sh
chown -R ec2-user:ec2-user /home/ec2-user/scripts
chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Install session manager plugin
yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

echo "Bastion host setup completed successfully!"
echo "Installed tools: AWS CLI v2, kubectl, eksctl, helm, k9s, Docker, PostgreSQL client"
echo "Kubernetes tools: kubectx, kubens, kustomize, stern, kubectl-tree"
echo "Available scripts in ~/scripts/:"
echo "  - connect-eks.sh"
echo "  - connect-rds.sh" 
echo "  - check-resources.sh"
echo "  - docker-info.sh"
echo "  - k8s-tools.sh"
echo ""
echo "Useful aliases:"
echo "  k (kubectl), kgp (get pods), kgs (get services), kgn (get nodes)"
echo "  kctx (kubectx), kns (kubens), ktree (kubectl tree)"
echo "  d (docker), dps (docker ps), awsid (aws identity)"
echo ""
echo "Run 'k8s-tools.sh' to see all Kubernetes tool versions and cluster info"
