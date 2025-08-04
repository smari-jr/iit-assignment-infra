#!/bin/bash

# Three-Tier Application Deployment Script
# This script helps deploy the three-tier architecture on AWS EKS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if aws CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are satisfied."
}

# Function to deploy infrastructure
deploy_infrastructure() {
    local environment=$1
    
    print_status "Deploying infrastructure for $environment environment..."
    
    # Navigate to terraform directory
    cd terraform
    
    # Initialize terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan the deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var-file="terraform.tfvars.$environment" -out="tfplan-$environment"
    
    # Ask for confirmation
    echo
    read -p "Do you want to apply this plan? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled."
        exit 0
    fi
    
    # Apply the plan
    print_status "Applying Terraform configuration..."
    terraform apply "tfplan-$environment"
    
    # Get outputs
    print_status "Getting deployment outputs..."
    DB_ENDPOINT=$(terraform output -raw db_instance_endpoint)
    CLUSTER_NAME=$(terraform output -raw cluster_id)
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "ap-southeast-1")
    BASTION_ENABLED=$(terraform output -raw bastion_enabled 2>/dev/null || echo "false")
    
    print_success "Infrastructure deployed successfully!"
    
    # Configure kubectl
    print_status "Configuring kubectl..."
    aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
    
    print_success "kubectl configured successfully!"
    
    # Store outputs for future Kubernetes deployment
    echo "DB_ENDPOINT=$DB_ENDPOINT" > .env
    echo "CLUSTER_NAME=$CLUSTER_NAME" >> .env
    echo "AWS_REGION=$AWS_REGION" >> .env
    echo "BASTION_ENABLED=$BASTION_ENABLED" >> .env
    
    # Show bastion connection info if enabled
    if [ "$BASTION_ENABLED" = "true" ]; then
        print_success "Bastion host deployed! Connection information:"
        echo "1. Get bastion instance ID:"
        echo "   aws ec2 describe-instances --region $AWS_REGION --filters 'Name=tag:Name,Values=*bastion*' --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]' --output table"
        echo
        echo "2. Connect via SSH (requires key pair):"
        echo "   ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>"
        echo
        echo "3. Connect via Session Manager:"
        echo "   aws ssm start-session --target <instance-id>"
        echo
        echo "4. Available scripts on bastion:"
        echo "   ~/scripts/connect-eks.sh $CLUSTER_NAME"
        echo "   ~/scripts/connect-rds.sh $DB_ENDPOINT admin app_database"
        echo "   ~/scripts/check-resources.sh"
        echo
    fi
    
    cd ..
}

# Function to deploy Kubernetes resources (placeholder for future use)
deploy_kubernetes() {
    local environment=$1
    
    print_status "Kubernetes deployment not implemented yet..."
    print_warning "First provision the infrastructure, then we'll add Kubernetes manifests"
    
    # Source environment variables
    if [ -f .env ]; then
        source .env
        print_status "Environment variables loaded:"
        echo "  - DB_ENDPOINT: $DB_ENDPOINT"
        echo "  - CLUSTER_NAME: $CLUSTER_NAME"
        echo "  - AWS_REGION: $AWS_REGION"
        echo "  - BASTION_ENABLED: $BASTION_ENABLED"
    else
        print_error "Environment file not found. Please run infrastructure deployment first."
        return 1
    fi
    
    print_status "To deploy applications later:"
    echo "1. Create Kubernetes manifests"
    echo "2. Connect to bastion host" 
    echo "3. Use kubectl to deploy applications"
}

# Function to check deployment status
check_status() {
    print_status "Checking infrastructure deployment status..."
    
    echo
    echo "=== AWS Identity ==="
    aws sts get-caller-identity
    
    echo -e "\n=== EKS Clusters ==="
    aws eks list-clusters --region ap-southeast-1
    
    echo -e "\n=== RDS Instances ==="
    aws rds describe-db-instances --region ap-southeast-1 --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' --output table
    
    echo -e "\n=== EC2 Instances (Bastion) ==="
    aws ec2 describe-instances --region ap-southeast-1 --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table
    
    echo -e "\n=== VPC Information ==="
    aws ec2 describe-vpcs --region ap-southeast-1 --query 'Vpcs[*].[VpcId,CidrBlock,State,Tags[?Key==`Name`].Value|[0]]' --output table
    
    if command -v kubectl &> /dev/null; then
        if kubectl cluster-info &> /dev/null; then
            echo -e "\n=== EKS Cluster Connection ==="
            kubectl cluster-info
            
            echo -e "\n=== EKS Nodes ==="
            kubectl get nodes -o wide
            
            print_success "EKS cluster is accessible!"
            print_status "Ready for application deployment"
        else
            echo -e "\n=== EKS Cluster ==="
            print_warning "kubectl not configured or cluster not accessible"
            echo "Run the following to connect:"
            if [ -f .env ]; then
                source .env
                echo "aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME"
            else
                echo "aws eks --region ap-southeast-1 update-kubeconfig --name <cluster-name>"
            fi
        fi
    else
        echo -e "\n=== kubectl ==="
        print_warning "kubectl not installed"
        echo "Install kubectl to manage the EKS cluster"
    fi
}

# Function to cleanup resources
cleanup() {
    local environment=$1
    
    print_warning "This will destroy all infrastructure resources for $environment environment."
    read -p "Are you sure? Type 'delete' to confirm: " -r
    if [[ $REPLY != "delete" ]]; then
        print_warning "Cleanup cancelled."
        exit 0
    fi
    
    # Delete infrastructure
    print_status "Destroying infrastructure..."
    cd terraform
    terraform destroy -var-file="terraform.tfvars.$environment" -auto-approve
    cd ..
    
    print_success "Cleanup completed!"
}

# Main function
main() {
    echo "=========================================="
    echo "  Three-Tier Application Deployment"
    echo "=========================================="
    echo
    
    # Check if environment is provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <command> [environment]"
        echo
        echo "Commands:"
        echo "  deploy <env>   : Deploy infrastructure (EKS, RDS, VPC, Bastion)"
        echo "  infra <env>    : Deploy only infrastructure"
        echo "  status         : Check deployment status"
        echo "  cleanup <env>  : Cleanup all resources"
        echo
        echo "Environments: dev"
        echo
        echo "Examples:"
        echo "  $0 deploy dev"
        echo "  $0 infra dev"
        echo "  $0 status"
        echo "  $0 cleanup dev"
        exit 1
    fi
    
    local command=$1
    local environment=$2
    
    # Check prerequisites for deploy and infra commands
    if [[ "$command" == "deploy" || "$command" == "infra" ]]; then
        check_prerequisites
    fi
    
    case $command in
        "deploy")
            if [ -z "$environment" ]; then
                print_error "Environment is required for deploy command"
                exit 1
            fi
            deploy_infrastructure $environment
            print_status "Infrastructure deployment complete!"
            print_warning "Kubernetes applications can be deployed later once you're ready"
            check_status
            ;;
        "infra")
            if [ -z "$environment" ]; then
                print_error "Environment is required for infra command"
                exit 1
            fi
            deploy_infrastructure $environment
            ;;
        "status")
            check_status
            ;;
        "cleanup")
            if [ -z "$environment" ]; then
                print_error "Environment is required for cleanup command"
                exit 1
            fi
            cleanup $environment
            ;;
        *)
            print_error "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
