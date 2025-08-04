# CloudWatch Container Insights Setup for EKS

## Overview
This document explains how to set up CloudWatch Container Insights for your EKS cluster to collect detailed metrics and logs.

## Automatic Setup via Terraform

The monitoring module includes Container Insights configuration, but you need to deploy the CloudWatch agent to your EKS cluster.

## Manual Setup Instructions

### 1. Install CloudWatch Container Insights

Run this command to install Container Insights on your EKS cluster:

```bash
# Connect to your EKS cluster first
aws eks update-kubeconfig --region ap-southeast-1 --name iit-test-dev-eks

# Install CloudWatch Container Insights
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml

kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluentd/fluentd-daemonset-cloudwatch.yaml
```

### 2. Verify Installation

```bash
# Check if the pods are running
kubectl get pods -n amazon-cloudwatch

# Check logs
kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent
kubectl logs -n amazon-cloudwatch -l name=fluentd-cloudwatch
```

### 3. Alternative: Use eksctl (Recommended)

```bash
# Enable Container Insights using eksctl
eksctl utils update-cluster-logging --enable-types=all --region=ap-southeast-1 --cluster=iit-test-dev-eks
```

## Custom Kubernetes Manifests

### CloudWatch Agent ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cwagentconfig
  namespace: amazon-cloudwatch
data:
  cwagentconfig.json: |
    {
      "logs": {
        "metrics_collected": {
          "kubernetes": {
            "cluster_name": "iit-test-dev-eks",
            "metrics_collection_interval": 60
          }
        },
        "force_flush_interval": 5
      },
      "metrics": {
        "namespace": "ContainerInsights",
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": ["used_percent"],
            "metrics_collection_interval": 60,
            "resources": ["*"]
          },
          "diskio": {
            "measurement": ["io_time"],
            "metrics_collection_interval": 60,
            "resources": ["*"]
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          },
          "netstat": {
            "measurement": ["tcp_established", "tcp_time_wait"],
            "metrics_collection_interval": 60
          },
          "swap": {
            "measurement": ["swap_used_percent"],
            "metrics_collection_interval": 60
          }
        }
      }
    }
```

### CloudWatch Agent DaemonSet

Save as `cloudwatch-agent.yaml`:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cloudwatch-agent
  namespace: amazon-cloudwatch
spec:
  selector:
    matchLabels:
      name: cloudwatch-agent
  template:
    metadata:
      labels:
        name: cloudwatch-agent
    spec:
      containers:
      - name: cloudwatch-agent
        image: amazon/cloudwatch-agent:1.247348.0b251302
        ports:
        - containerPort: 8125
          hostPort: 8125
          protocol: UDP
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 200m
            memory: 200Mi
        env:
        - name: HOST_IP
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: HOST_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: K8S_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: cwagentconfig
          mountPath: /etc/cwagentconfig
        - name: rootfs
          mountPath: /rootfs
          readOnly: true
        - name: dockersock
          mountPath: /var/run/docker.sock
          readOnly: true
        - name: varlibdocker
          mountPath: /var/lib/docker
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: devdisk
          mountPath: /dev/disk
          readOnly: true
      volumes:
      - name: cwagentconfig
        configMap:
          name: cwagentconfig
      - name: rootfs
        hostPath:
          path: /
      - name: dockersock
        hostPath:
          path: /var/run/docker.sock
      - name: varlibdocker
        hostPath:
          path: /var/lib/docker
      - name: sys
        hostPath:
          path: /sys
      - name: devdisk
        hostPath:
          path: /dev/disk/
      terminationGracePeriodSeconds: 60
      serviceAccount: cloudwatch-agent
```

## Metrics Available in Dashboard

After Container Insights is enabled, your dashboard will show:

### Node-level Metrics:
- CPU Utilization
- Memory Utilization
- Network I/O
- Disk I/O
- Number of running pods per node

### Pod-level Metrics:
- Pod CPU utilization
- Pod memory utilization
- Pod network I/O
- Pod restart count

### Cluster-level Metrics:
- Number of nodes
- Number of pods
- Resource requests vs limits
- Namespace-level resource usage

## Accessing Metrics

### Via CloudWatch Console:
1. Go to CloudWatch Console
2. Navigate to "Container Insights"
3. Select your cluster: `iit-test-dev-eks`
4. View metrics by Resource, Performance, or Map view

### Via Custom Dashboard:
Access your custom dashboard at the URL provided in Terraform outputs:
```bash
terraform output cloudwatch_dashboard_url
```

## Troubleshooting

### Check if Container Insights is enabled:
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/containerinsights/iit-test-dev-eks"
```

### Verify CloudWatch agent is sending metrics:
```bash
kubectl describe pod -n amazon-cloudwatch -l name=cloudwatch-agent
```

### Check for any permission issues:
```bash
kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent --tail=50
```

## Cost Considerations

Container Insights charges are based on:
- Ingested log data
- Custom metrics
- Dashboard views

For development environments, consider:
- Reducing log retention period (set to 7 days in config)
- Filtering unnecessary logs
- Using log sampling for high-volume applications

Estimated monthly cost for small development cluster: $10-30 USD
