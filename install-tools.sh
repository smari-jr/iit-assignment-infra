#!/bin/bash

# ==============================================================================
# AWS EKS Development Tools Installation Script for Amazon Linux 2/2023
# ==============================================================================
# This script installs:
# - AWS CLI v2
# - eksctl (EKS management tool)
# - kubectl (Kubernetes CLI)
# - Docker
# - Kustomize (Kubernetes configuration management)
# - PostgreSQL Client (psql)
# - Additional useful tools
# ==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons."
        log_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Detect Amazon Linux version
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
        log_info "Detected OS: $OS $VERSION"
    else
        log_error "Cannot detect OS version"
        exit 1
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    
    if command -v dnf &> /dev/null; then
        # Amazon Linux 2023
        sudo dnf update -y
        sudo dnf install -y curl wget unzip tar gzip git which
    elif command -v yum &> /dev/null; then
        # Amazon Linux 2
        sudo yum update -y
        sudo yum install -y curl wget unzip tar gzip git which
    else
        log_error "Neither dnf nor yum package manager found"
        exit 1
    fi
    
    log_success "System packages updated"
}

# Install AWS CLI v2
install_aws_cli() {
    log_info "Installing AWS CLI v2..."
    
    # Check if AWS CLI is already installed
    if command -v aws &> /dev/null; then
        current_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        log_warning "AWS CLI is already installed (version: $current_version)"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping AWS CLI installation"
            return
        fi
    fi
    
    # Download and install AWS CLI v2
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    
    # Verify installation
    if command -v aws &> /dev/null; then
        aws_version=$(aws --version 2>&1)
        log_success "AWS CLI installed: $aws_version"
    else
        log_error "AWS CLI installation failed"
        exit 1
    fi
    
    # Cleanup
    rm -rf /tmp/aws /tmp/awscliv2.zip
}

# Install kubectl
install_kubectl() {
    log_info "Installing kubectl..."
    
    # Check if kubectl is already installed
    if command -v kubectl &> /dev/null; then
        current_version=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo "unknown")
        log_warning "kubectl is already installed (version: $current_version)"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping kubectl installation"
            return
        fi
    fi
    
    # Get latest stable version
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    log_info "Installing kubectl version: $KUBECTL_VERSION"
    
    # Download kubectl
    cd /tmp
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/$KUBECTL_VERSION/bin/linux/amd64/kubectl.sha256"
    
    # Verify checksum
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    if [[ $? -ne 0 ]]; then
        log_error "kubectl checksum verification failed"
        exit 1
    fi
    
    # Install kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    # Verify installation
    if command -v kubectl &> /dev/null; then
        kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null)
        log_success "kubectl installed: $kubectl_version"
    else
        log_error "kubectl installation failed"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/kubectl.sha256
}

# Install eksctl
install_eksctl() {
    log_info "Installing eksctl..."
    
    # Check if eksctl is already installed
    if command -v eksctl &> /dev/null; then
        current_version=$(eksctl version)
        log_warning "eksctl is already installed (version: $current_version)"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping eksctl installation"
            return
        fi
    fi
    
    # Download and install eksctl
    cd /tmp
    PLATFORM=$(uname -s)_$(uname -m)
    curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
    curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
    
    if [[ $? -ne 0 ]]; then
        log_error "eksctl checksum verification failed"
        exit 1
    fi
    
    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    
    # Verify installation
    if command -v eksctl &> /dev/null; then
        eksctl_version=$(eksctl version)
        log_success "eksctl installed: $eksctl_version"
    else
        log_error "eksctl installation failed"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/eksctl_$PLATFORM.tar.gz
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        current_version=$(docker --version 2>/dev/null || echo "unknown")
        log_warning "Docker is already installed: $current_version"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Docker installation"
            return
        fi
    fi
    
    # Install Docker based on Amazon Linux version
    if command -v dnf &> /dev/null; then
        # Amazon Linux 2023
        sudo dnf install -y docker
    elif command -v yum &> /dev/null; then
        # Amazon Linux 2
        sudo yum install -y docker
    fi
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -a -G docker $USER
    log_warning "You need to log out and log back in for docker group membership to take effect"
    
    # Verify installation
    if command -v docker &> /dev/null; then
        docker_version=$(sudo docker --version)
        log_success "Docker installed: $docker_version"
        log_info "Docker service status: $(sudo systemctl is-active docker)"
    else
        log_error "Docker installation failed"
        exit 1
    fi
}

# Install Kustomize
install_kustomize() {
    log_info "Installing Kustomize..."
    
    # Check if Kustomize is already installed
    if command -v kustomize &> /dev/null; then
        current_version=$(kustomize version --short 2>/dev/null || echo "unknown")
        log_warning "Kustomize is already installed (version: $current_version)"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Kustomize installation"
            return
        fi
    fi
    
    # Download and install Kustomize using official script
    cd /tmp
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    
    # Move to system PATH
    sudo mv kustomize /usr/local/bin/
    
    # Verify installation
    if command -v kustomize &> /dev/null; then
        kustomize_version=$(kustomize version --short 2>/dev/null || kustomize version 2>/dev/null)
        log_success "Kustomize installed: $kustomize_version"
    else
        log_error "Kustomize installation failed"
        exit 1
    fi
}

# Install PostgreSQL Client
install_postgresql_client() {
    log_info "Installing PostgreSQL Client (psql)..."
    
    # Check if psql is already installed
    if command -v psql &> /dev/null; then
        current_version=$(psql --version 2>/dev/null || echo "unknown")
        log_warning "PostgreSQL client is already installed: $current_version"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping PostgreSQL client installation"
            return
        fi
    fi
    
    # Install PostgreSQL client based on Amazon Linux version
    if command -v dnf &> /dev/null; then
        # Amazon Linux 2023
        log_info "Installing PostgreSQL 15 client for Amazon Linux 2023..."
        sudo dnf install -y postgresql15
    elif command -v yum &> /dev/null; then
        # Amazon Linux 2 - check if amazon-linux-extras is available
        if command -v amazon-linux-extras &> /dev/null; then
            log_info "Installing PostgreSQL 14 client for Amazon Linux 2..."
            sudo amazon-linux-extras install postgresql14 -y
        else
            log_info "Installing PostgreSQL client using yum..."
            sudo yum install -y postgresql
        fi
    else
        log_error "Cannot determine package manager for PostgreSQL installation"
        exit 1
    fi
    
    # Verify installation
    if command -v psql &> /dev/null; then
        psql_version=$(psql --version)
        log_success "PostgreSQL client installed: $psql_version"
    else
        log_error "PostgreSQL client installation failed"
        exit 1
    fi
}

# Install additional useful tools
install_additional_tools() {
    log_info "Installing additional useful tools..."
    
    # Install helm (Kubernetes package manager)
    if ! command -v helm &> /dev/null; then
        log_info "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        log_success "Helm installed: $(helm version --short)"
    fi
    
    # Install jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        log_info "Installing jq..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        else
            sudo yum install -y jq
        fi
        log_success "jq installed: $(jq --version)"
    fi
    
    # Install yq (YAML processor)
    if ! command -v yq &> /dev/null; then
        log_info "Installing yq..."
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
        log_success "yq installed: $(yq --version)"
    fi
    
    # Install k9s (Kubernetes CLI UI)
    if ! command -v k9s &> /dev/null; then
        log_info "Installing k9s (Kubernetes CLI UI)..."
        cd /tmp
        K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -sL https://github.com/derailed/k9s/releases/download/$K9S_VERSION/k9s_Linux_amd64.tar.gz | tar xz
        sudo mv k9s /usr/local/bin/
        log_success "k9s installed: $(k9s version --short)"
    fi
}

# Setup bash completion
setup_bash_completion() {
    log_info "Setting up bash completion..."
    
    # Install bash-completion if not present
    if command -v dnf &> /dev/null; then
        sudo dnf install -y bash-completion
    else
        sudo yum install -y bash-completion
    fi
    
    # Add completions to .bashrc
    if [[ -f ~/.bashrc ]]; then
        # kubectl completion
        if ! grep -q "kubectl completion bash" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# kubectl completion" >> ~/.bashrc
            echo "source <(kubectl completion bash)" >> ~/.bashrc
            echo "alias k=kubectl" >> ~/.bashrc
            echo "complete -F __start_kubectl k" >> ~/.bashrc
        fi
        
        # eksctl completion
        if ! grep -q "eksctl completion bash" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# eksctl completion" >> ~/.bashrc
            echo "source <(eksctl completion bash)" >> ~/.bashrc
        fi
        
        # aws completion
        if ! grep -q "aws_completer" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# aws completion" >> ~/.bashrc
            echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
        fi
        
        # kustomize completion
        if ! grep -q "kustomize completion bash" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# kustomize completion" >> ~/.bashrc
            echo "source <(kustomize completion bash)" >> ~/.bashrc
        fi
        
        log_success "Bash completion configured"
        log_info "Run 'source ~/.bashrc' or start a new shell session to enable completions"
    fi
}

# Verify all installations
verify_installations() {
    log_info "Verifying all installations..."
    
    declare -A tools=(
        ["aws"]="AWS CLI"
        ["kubectl"]="kubectl"
        ["eksctl"]="eksctl"
        ["docker"]="Docker"
        ["kustomize"]="Kustomize"
        ["psql"]="PostgreSQL Client"
        ["helm"]="Helm"
        ["jq"]="jq"
        ["yq"]="yq"
        ["k9s"]="k9s"
    )
    
    for tool in "${!tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "${tools[$tool]} ✓"
        else
            log_error "${tools[$tool]} ✗"
        fi
    done
}

# Main function
main() {
    log_info "Starting AWS EKS Development Tools Installation"
    log_info "================================================"
    
    check_root
    detect_os
    
    # Ask user what to install
    echo
    log_info "What would you like to install?"
    echo "1) All tools (recommended)"
    echo "2) AWS CLI only"
    echo "3) kubectl only"
    echo "4) eksctl only"
    echo "5) Docker only"
    echo "6) Kustomize only"
    echo "7) PostgreSQL Client only"
    echo "8) Custom selection"
    read -p "Choose an option (1-8): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            update_system
            install_aws_cli
            install_kubectl
            install_eksctl
            install_docker
            install_kustomize
            install_postgresql_client
            install_additional_tools
            setup_bash_completion
            ;;
        2)
            update_system
            install_aws_cli
            ;;
        3)
            update_system
            install_kubectl
            ;;
        4)
            update_system
            install_eksctl
            ;;
        5)
            update_system
            install_docker
            ;;
        6)
            update_system
            install_kustomize
            ;;
        7)
            update_system
            install_postgresql_client
            ;;
        8)
            update_system
            echo "Select tools to install:"
            read -p "Install AWS CLI? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_aws_cli
            read -p "Install kubectl? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_kubectl
            read -p "Install eksctl? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_eksctl
            read -p "Install Docker? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_docker
            read -p "Install Kustomize? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_kustomize
            read -p "Install PostgreSQL Client? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_postgresql_client
            read -p "Install additional tools (helm, jq, yq, k9s)? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && install_additional_tools
            read -p "Setup bash completion? (y/n): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] && setup_bash_completion
            ;;
        *)
            log_error "Invalid option"
            exit 1
            ;;
    esac
    
    echo
    log_info "Installation Summary"
    log_info "==================="
    verify_installations
    
    echo
    log_success "Installation completed successfully!"
    log_info "Next steps:"
    echo "  1. Configure AWS credentials: aws configure"
    echo "  2. Test EKS connection: aws eks list-clusters --region <your-region>"
    echo "  3. Connect to your cluster: aws eks update-kubeconfig --region <region> --name <cluster-name>"
    echo "  4. Test PostgreSQL connection: psql -h <host> -p 5432 -U <username> -d <database>"
    echo "  5. Test Kustomize: kustomize version"
    echo "  6. If Docker was installed, log out and log back in to use Docker without sudo"
    echo "  7. Run 'source ~/.bashrc' to enable bash completions"
    
    echo
    log_info "Useful aliases and completions added to ~/.bashrc:"
    echo "  - k (shortcut for kubectl)"
    echo "  - Tab completion for aws, kubectl, eksctl, and kustomize commands"
    
    echo
    log_info "For your EKS cluster (iit-test-dev-eks):"
    echo "  - Connect: aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks"
    echo "  - PostgreSQL: psql -h iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com -p 5432 -U dbadmin -d app_database"
}

# Run main function
main "$@"
