variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
}

variable "app_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster"
  type        = list(string)
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "node_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_irsa" {
  description = "Whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "enable_bastion_access" {
  description = "Enable access from bastion host to EKS cluster"
  type        = bool
  default     = false
}

variable "bastion_security_group_id" {
  description = "Security group ID of bastion host for access to EKS"
  type        = string
  default     = ""
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Add-on version variables
variable "vpc_cni_addon_version" {
  description = "Version of the vpc-cni EKS add-on"
  type        = string
  default     = null
}

variable "coredns_addon_version" {
  description = "Version of the coredns EKS add-on"
  type        = string
  default     = null
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy EKS add-on"
  type        = string
  default     = null
}

variable "ebs_csi_addon_version" {
  description = "Version of the aws-ebs-csi-driver EKS add-on"
  type        = string
  default     = null
}

variable "efs_csi_addon_version" {
  description = "Version of the aws-efs-csi-driver EKS add-on"
  type        = string
  default     = null
}

variable "pod_identity_addon_version" {
  description = "Version of the eks-pod-identity-agent EKS add-on"
  type        = string
  default     = null
}

# Feature enablement variables
variable "enable_efs_csi" {
  description = "Enable EFS CSI driver add-on"
  type        = bool
  default     = true
}

variable "enable_pod_identity" {
  description = "Enable EKS Pod Identity Agent add-on"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable IAM role for cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_load_balancer_controller" {
  description = "Enable IAM role for AWS Load Balancer Controller"
  type        = bool
  default     = true
}
