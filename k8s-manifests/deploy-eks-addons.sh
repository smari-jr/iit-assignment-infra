#!/bin/bash

# Script to deploy additional EKS add-ons and controllers
# Run this script from the bastion host after connecting to EKS cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    print_error "Run: ./scripts/connect-eks.sh <cluster-name> first"
    exit 1
fi

# Get cluster information
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.vpcId' --output text)

print_status "Deploying additional EKS controllers for cluster: $CLUSTER_NAME"
print_status "Region: $REGION"
print_status "Account ID: $ACCOUNT_ID"
print_status "VPC ID: $VPC_ID"

# 1. Install cert-manager (required for AWS Load Balancer Controller)
print_status "Installing cert-manager..."
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Wait for cert-manager to be ready
print_status "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager-webhook -n cert-manager

# 2. Create customized AWS Load Balancer Controller manifest
print_status "Creating AWS Load Balancer Controller manifest..."
cat > /tmp/aws-load-balancer-controller.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$ACCOUNT_ID:role/$CLUSTER_NAME-aws-load-balancer-controller-role

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
    app.kubernetes.io/version: v2.7.2
  name: aws-load-balancer-controller
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/component: controller
      app.kubernetes.io/name: aws-load-balancer-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/name: aws-load-balancer-controller
    spec:
      containers:
      - args:
        - --cluster-name=$CLUSTER_NAME
        - --ingress-class=alb
        - --aws-vpc-id=$VPC_ID
        - --aws-region=$REGION
        image: public.ecr.aws/eks/aws-load-balancer-controller:v2.7.2
        name: controller
        ports:
        - containerPort: 9443
          name: webhook-server
          protocol: TCP
        - containerPort: 8080
          name: metrics-server
          protocol: TCP
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
        volumeMounts:
        - mountPath: /tmp/k8s-webhook-server/serving-certs
          name: cert
          readOnly: true
      hostNetwork: false
      priorityClassName: system-cluster-critical
      securityContext:
        fsGroup: 65534
      serviceAccountName: aws-load-balancer-controller
      terminationGracePeriodSeconds: 10
      volumes:
      - name: cert
        secret:
          defaultMode: 420
          secretName: aws-load-balancer-webhook-tls
EOF

# Download and apply AWS Load Balancer Controller CRDs
print_status "Installing AWS Load Balancer Controller CRDs..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# Apply the AWS Load Balancer Controller
print_status "Installing AWS Load Balancer Controller..."
kubectl apply -f /tmp/aws-load-balancer-controller.yaml

# 3. Create Cluster Autoscaler manifest
print_status "Creating Cluster Autoscaler manifest..."
cat > /tmp/cluster-autoscaler.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$ACCOUNT_ID:role/$CLUSTER_NAME-cluster-autoscaler-role

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["events", "endpoints"]
    verbs: ["create", "patch"]
  - apiGroups: [""]
    resources: ["pods/eviction"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["pods/status"]
    verbs: ["update"]
  - apiGroups: [""]
    resources: ["endpoints"]
    resourceNames: ["cluster-autoscaler"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["watch", "list", "get", "update"]
  - apiGroups: [""]
    resources:
      - "namespaces"
      - "pods"
      - "services"
      - "replicationcontrollers"
      - "persistentvolumeclaims"
      - "persistentvolumes"
    verbs: ["watch", "list", "get"]
  - apiGroups: ["extensions"]
    resources: ["replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["watch", "list"]
  - apiGroups: ["apps"]
    resources: ["statefulsets", "replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["batch", "extensions"]
    resources: ["jobs"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["create"]
  - apiGroups: ["coordination.k8s.io"]
    resourceNames: ["cluster-autoscaler"]
    resources: ["leases"]
    verbs: ["get", "update"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create","list","watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs: ["delete", "get", "update", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      priorityClassName: system-cluster-critical
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
        seccompProfile:
          type: RuntimeDefault
      serviceAccountName: cluster-autoscaler
      containers:
        - image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.28.2
          name: cluster-autoscaler
          resources:
            limits:
              cpu: 100m
              memory: 600Mi
            requests:
              cpu: 100m
              memory: 600Mi
          command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/$CLUSTER_NAME
            - --balance-similar-node-groups
            - --skip-nodes-with-system-pods=false
          volumeMounts:
            - name: ssl-certs
              mountPath: /etc/ssl/certs/ca-certificates.crt
              readOnly: true
          imagePullPolicy: "Always"
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: true
      volumes:
        - name: ssl-certs
          hostPath:
            path: "/etc/ssl/certs/ca-bundle.crt"
EOF

# Apply Cluster Autoscaler
print_status "Installing Cluster Autoscaler..."
kubectl apply -f /tmp/cluster-autoscaler.yaml

# 4. Create storage classes
print_status "Creating storage classes..."
cat > /tmp/storage-classes.yaml << EOF
# Storage Class for EBS GP3 (default)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"

---
# Storage Class for EBS GP2 (legacy support)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp2
  fsType: ext4
  encrypted: "true"

---
# Storage Class for EBS io2 (high performance)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: io2
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: io2
  iops: "1000"
  fsType: ext4
  encrypted: "true"
EOF

# Apply storage classes
kubectl apply -f /tmp/storage-classes.yaml

# Remove the old gp2 default storage class if it exists
if kubectl get storageclass gp2 -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null | grep -q true; then
    print_status "Removing default annotation from existing gp2 storage class..."
    kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
fi

# 5. Wait for deployments to be ready
print_status "Waiting for AWS Load Balancer Controller to be ready..."
kubectl wait --for=condition=Available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

print_status "Waiting for Cluster Autoscaler to be ready..."
kubectl wait --for=condition=Available --timeout=300s deployment/cluster-autoscaler -n kube-system

# 6. Verify installations
print_status "Verifying installations..."

echo ""
print_status "=== EKS Add-ons ==="
kubectl get deployment -n kube-system | grep -E "(aws-load-balancer-controller|cluster-autoscaler|cert-manager)"

echo ""
print_status "=== Storage Classes ==="
kubectl get storageclass

echo ""
print_status "=== Service Accounts with IRSA ==="
kubectl get serviceaccount -n kube-system -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.eks\.amazonaws\.com/role-arn}{"\n"}{end}' | grep -v '<no value>'

echo ""
print_status "=== EKS Managed Add-ons ==="
aws eks list-addons --cluster-name $CLUSTER_NAME --region $REGION --output table

echo ""
print_status "✅ All additional EKS controllers have been installed successfully!"
print_status "You can now:"
print_status "  • Create Application Load Balancers using Ingress with annotation: kubernetes.io/ingress.class: alb"
print_status "  • Use automatic cluster scaling based on pod resource requests"
print_status "  • Use encrypted EBS volumes with GP3 storage class (default)"
print_status "  • Access cluster with k9s for visual cluster management"

# Clean up temporary files
rm -f /tmp/aws-load-balancer-controller.yaml /tmp/cluster-autoscaler.yaml /tmp/storage-classes.yaml
