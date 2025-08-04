terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0" # Specific stable version
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4" # Specific stable version
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3" # Specific stable version
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}