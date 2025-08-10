# Kubernetes Configuration for AWS to Azure Migration App

This directory contains all Kubernetes configurations and setup scripts for deploying the AWS to Azure Migration application.

## 📁 Directory Structure

```
kubernetes/
├── cluster-setup.md          # Detailed cluster setup instructions
├── setup-cluster.sh         # Automated cluster setup script
├── README.md                # This file
└── manifests/               # Plain Kubernetes manifests
    ├── namespace.yaml       # Application namespaces
    ├── deployment.yaml      # Application deployment
    ├── service.yaml         # Kubernetes service
    ├── configmap.yaml       # Configuration data
    ├── ingress.yaml         # Ingress for external access
    └── hpa.yaml            # Horizontal Pod Autoscaler
```

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Run the automated setup script
./kubernetes/setup-cluster.sh
```

This script will:
- ✅ Check prerequisites (AWS CLI, eksctl, kubectl, helm)
- ✅ Create EKS cluster with worker nodes
- ✅ Configure kubectl
- ✅ Install essential add-ons (Ingress, cert-manager, metrics-server)
- ✅ Create application namespaces
- ✅ Setup ECR registry secrets
- ✅ Optionally install monitoring (Prometheus & Grafana)

### Option 2: Manual Setup

Follow the detailed instructions in [`cluster-setup.md`](cluster-setup.md)

## 🏗️ Kubernetes Cluster Information

### Current Configuration

| Component | Value |
|-----------|-------|
| **Cluster Name** | `awstoazure-cluster` |
| **Region** | `us-east-1` |
| **Kubernetes Version** | `1.28` |
| **Node Type** | `t3.medium` |
| **Node Count** | 2-4 (auto-scaling) |
| **Namespaces** | `awstoazure-dev`, `awstoazure-staging`, `awstoazure-prod` |

### Installed Add-ons

- **NGINX Ingress Controller** - External traffic routing
- **cert-manager** - TLS certificate management
- **Metrics Server** - Resource metrics for HPA
- **AWS Load Balancer Controller** - AWS ELB integration
- **Prometheus & Grafana** (optional) - Monitoring and observability

## 🔧 Required Configurations

### 1. AWS Credentials

Ensure your AWS credentials are configured:
```bash
aws configure
# or
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Domain Names

Update domain names in the following files:
- `helm/awstoazure/values-dev.yaml`
- `helm/awstoazure/values-prod.yaml`
- `kubernetes/manifests/ingress.yaml`

### 3. ECR Registry Access

The cluster is configured to pull images from:
```
891377120087.dkr.ecr.us-east-1.amazonaws.com/aws2azurepo
```

ECR secrets are automatically created by the setup script.

## 🎯 Deployment Options

### Option 1: Helm Deployment (Recommended)

```bash
# Development environment
./helm/deploy.sh --environment dev --namespace awstoazure-dev

# Production environment
./helm/deploy.sh --environment prod --namespace awstoazure-prod
```

### Option 2: Plain Kubernetes Manifests

```bash
# Apply all manifests
kubectl apply -f kubernetes/manifests/

# Or apply individually
kubectl apply -f kubernetes/manifests/namespace.yaml
kubectl apply -f kubernetes/manifests/configmap.yaml
kubectl apply -f kubernetes/manifests/deployment.yaml
kubectl apply -f kubernetes/manifests/service.yaml
kubectl apply -f kubernetes/manifests/ingress.yaml
kubectl apply -f kubernetes/manifests/hpa.yaml
```

## 📊 Monitoring and Management

### View Cluster Status

```bash
# Cluster overview
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# All resources
kubectl get all --all-namespaces

# Application status
kubectl get all -n awstoazure-prod
```

### View Application Logs

```bash
# All pods in namespace
kubectl logs -l app=awstoazure -n awstoazure-prod

# Specific pod
kubectl logs <pod-name> -n awstoazure-prod

# Follow logs
kubectl logs -f deployment/awstoazure-app -n awstoazure-prod
```

### Health Checks

```bash
# Pod health
kubectl get pods -n awstoazure-prod

# Deployment status
kubectl rollout status deployment/awstoazure-app -n awstoazure-prod

# HPA status
kubectl get hpa -n awstoazure-prod
```

## 🛠️ Troubleshooting

### Common Issues

1. **Pods Stuck in Pending**
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl get events --sort-by=.metadata.creationTimestamp -n <namespace>
   ```

2. **Image Pull Errors**
   ```bash
   # Check ECR secret
   kubectl get secrets -n <namespace>
   kubectl describe secret ecr-registry-secret -n <namespace>
   
   # Recreate ECR secret
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 891377120087.dkr.ecr.us-east-1.amazonaws.com
   ```

3. **Ingress Not Working**
   ```bash
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
   
   # Check ingress resource
   kubectl describe ingress awstoazure-ingress -n awstoazure-prod
   ```

4. **HPA Not Scaling**
   ```bash
   # Check metrics server
   kubectl get deployment metrics-server -n kube-system
   kubectl logs deployment/metrics-server -n kube-system
   
   # Check pod metrics
   kubectl top pods -n awstoazure-prod
   ```

### Debug Commands

```bash
# Port forward to application
kubectl port-forward deployment/awstoazure-app 8080:8080 -n awstoazure-prod

# Execute into pod
kubectl exec -it <pod-name> -n awstoazure-prod -- /bin/bash

# Check resource usage
kubectl top nodes
kubectl top pods -n awstoazure-prod
```

## 🔐 Security Considerations

### Network Policies (Optional)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: awstoazure-netpol
  namespace: awstoazure-prod
spec:
  podSelector:
    matchLabels:
      app: awstoazure
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
```

### RBAC (Role-Based Access Control)

The setup includes proper service accounts with minimal required permissions.

## 💰 Cost Optimization

### Cluster Autoscaler

```bash
# Install cluster autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Configure for your cluster
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
```

### Resource Monitoring

Monitor costs with:
- AWS Cost Explorer
- kubectl resource usage: `kubectl top nodes`
- Prometheus metrics (if installed)

## 🔄 Updates and Maintenance

### Cluster Updates

```bash
# Update EKS cluster
eksctl update cluster --name awstoazure-cluster --region us-east-1

# Update node groups
eksctl update nodegroup --cluster awstoazure-cluster --name awstoazure-nodes --region us-east-1
```

### Application Updates

```bash
# Rolling update via Helm
helm upgrade awstoazure-prod ./helm/awstoazure --set image.tag=v1.1.0

# Rolling update via kubectl
kubectl set image deployment/awstoazure-app awstoazure=891377120087.dkr.ecr.us-east-1.amazonaws.com/aws2azurepo:v1.1.0 -n awstoazure-prod
```

## 📞 Support

For cluster-related issues:
1. Check AWS EKS documentation
2. Review Kubernetes events: `kubectl get events --sort-by=.metadata.creationTimestamp`
3. Check logs: `kubectl logs -f deployment/<deployment-name> -n <namespace>`
4. Verify configuration: `kubectl describe <resource-type> <resource-name> -n <namespace>`
