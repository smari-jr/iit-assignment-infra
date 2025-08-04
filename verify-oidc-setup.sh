#!/bin/bash

# EKS OIDC and Add-ons Verification Script
# This script verifies the complete OIDC provider and add-ons setup

set -e

echo "🔍 EKS OIDC Provider and Add-ons Verification"
echo "=============================================="

# Cluster Info
CLUSTER_NAME="iit-test-dev-eks"
REGION="ap-southeast-1"

echo ""
echo "📋 Cluster Information:"
echo "- Name: $CLUSTER_NAME"
echo "- Region: $REGION"

# Check cluster status
echo ""
echo "🏥 Cluster Status:"
aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status' --output text

# Check OIDC Provider
echo ""
echo "🔐 OIDC Provider:"
OIDC_ARN=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.identity.oidc.issuer' --output text)
echo "- OIDC Issuer URL: $OIDC_ARN"

# Check Add-ons
echo ""
echo "📦 EKS Add-ons Status:"
aws eks list-addons --cluster-name $CLUSTER_NAME --region $REGION --query 'addons[]' --output table

echo ""
echo "🔧 Add-on Details:"

# EBS CSI Driver
echo "- EBS CSI Driver:"
aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver --region $REGION --query 'addon.{Status:status,ServiceAccountRole:serviceAccountRoleArn}' --output table

# EFS CSI Driver
echo "- EFS CSI Driver:"
aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name aws-efs-csi-driver --region $REGION --query 'addon.{Status:status,ServiceAccountRole:serviceAccountRoleArn}' --output table

# Pod Identity Agent
echo "- Pod Identity Agent:"
aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name eks-pod-identity-agent --region $REGION --query 'addon.status' --output text

# Check IRSA Roles
echo ""
echo "🏷️  IRSA IAM Roles:"
aws iam list-roles --query 'Roles[?starts_with(RoleName, `iit-test-dev-eks`)].{RoleName:RoleName,Arn:Arn}' --output table

echo ""
echo "✅ Verification Complete!"
echo ""
echo "🚀 Ready to deploy controllers:"
echo "1. cd k8s-manifests"
echo "2. kubectl apply -f aws-load-balancer-controller.yaml"
echo "3. kubectl apply -f cluster-autoscaler.yaml"
echo "4. kubectl apply -f storage-classes.yaml"
echo ""
echo "Or use the automated script:"
echo "./deploy-eks-addons.sh"
