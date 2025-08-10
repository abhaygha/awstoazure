# Infrastructure as Code (IaC) with GitHub Actions

This document explains how to use the integrated Infrastructure as Code capabilities to manage your Kubernetes cluster directly from the CI/CD pipeline.

## 🎯 Overview

The CI/CD pipeline now includes infrastructure management capabilities:

- **🏗️ Automatic cluster setup** when needed
- **🔍 Cluster existence detection** to avoid duplicate creation
- **🗑️ Cluster teardown** for cost management
- **⚙️ Manual workflow dispatch** for on-demand operations

## 🚀 How to Use

### Option 1: Automatic Cluster Setup

**Trigger cluster setup with commit message:**
```bash
git commit -m "Initial setup [setup-cluster]"
git push origin develop
```

The `[setup-cluster]` tag in your commit message will trigger the infrastructure setup job.

### Option 2: Manual Workflow Dispatch

1. **Go to GitHub Actions** tab in your repository
2. **Select "CI" workflow**
3. **Click "Run workflow"**
4. **Configure options:**
   - ✅ Setup Kubernetes cluster
   - ❌ Teardown Kubernetes cluster (use carefully!)
   - Choose environment: dev/staging/prod
5. **Click "Run workflow"**

### Option 3: Existing Cluster Detection

If a cluster already exists, the pipeline will:
- ✅ Skip cluster creation
- ✅ Configure kubectl for existing cluster
- ✅ Update ECR secrets
- ✅ Proceed to build and deploy

## 📋 Pipeline Jobs Overview

### 1. setup-infrastructure
**Runs when:**
- Manual dispatch with "Setup cluster" enabled
- Commit message contains `[setup-cluster]`

**What it does:**
```
1. Check if cluster exists
2. Install required tools (eksctl, kubectl, helm)
3. Create EKS cluster (if needed)
4. Setup essential add-ons
5. Create namespaces
6. Configure ECR secrets
7. Verify cluster health
```

### 2. teardown-infrastructure
**Runs when:**
- Manual dispatch with "Teardown cluster" enabled

**⚠️ WARNING:** This permanently deletes the entire cluster!

### 3. build → docker → deploy
**Runs after infrastructure setup** (or if cluster already exists)

## 🔧 Configuration

### Environment Variables

The setup script uses these configurations:

| Variable | Value | Description |
|----------|-------|-------------|
| `CLUSTER_NAME` | `awstoazure-cluster` | EKS cluster name |
| `REGION` | `us-east-1` | AWS region |
| `NODE_TYPE` | `t3.medium` | EC2 instance type |
| `MIN_NODES` | `1` | Minimum worker nodes |
| `MAX_NODES` | `4` | Maximum worker nodes |
| `DESIRED_NODES` | `2` | Initial worker nodes |

### CI/CD Environment Variables

For non-interactive execution:

| Variable | Purpose |
|----------|---------|
| `SKIP_CONFIRMATION=true` | Skip user prompts |
| `SKIP_MONITORING=true` | Skip monitoring setup |

## 🏗️ Infrastructure Components

### What Gets Created

**EKS Cluster:**
- ✅ Managed Kubernetes control plane
- ✅ Worker node group (auto-scaling)
- ✅ VPC and networking
- ✅ Security groups and IAM roles

**Add-ons:**
- ✅ NGINX Ingress Controller
- ✅ cert-manager (for TLS certificates)
- ✅ Metrics Server (for HPA)
- ✅ CoreDNS, VPC CNI, kube-proxy

**Application Resources:**
- ✅ Namespaces: `awstoazure-dev`, `awstoazure-staging`, `awstoazure-prod`
- ✅ ECR registry secrets in each namespace
- ✅ Service accounts with proper permissions

## 💰 Cost Management

### Automatic Cost Optimization

**Cluster Auto-Scaling:**
- Minimum 1 node when idle
- Maximum 4 nodes under load
- Automatic scale-down when demand decreases

**Resource Requests/Limits:**
- Pods have defined resource requests
- Efficient node utilization
- HPA prevents over-provisioning

### Manual Cost Control

**Cluster Teardown:**
```bash
# Via GitHub Actions UI
Run Workflow → Enable "Teardown cluster" → Run

# Cost savings: ~$75-150/month depending on usage
```

**Development Best Practices:**
- Use `teardown` after development sessions
- Recreate cluster when needed with `setup`
- Production clusters should remain persistent

## 🔍 Monitoring and Verification

### Pipeline Monitoring

**GitHub Actions provides:**
- ✅ Real-time setup progress
- ✅ Detailed logs for each step
- ✅ Success/failure notifications
- ✅ Resource verification outputs

### Cluster Health Checks

**Automatic verification:**
```bash
kubectl get nodes              # Worker node status
kubectl get namespaces         # Application namespaces
kubectl get pods --all-namespaces  # System pods health
```

### Manual Verification

**After setup, verify with:**
```bash
# Cluster access
kubectl cluster-info

# Application readiness
kubectl get all -n awstoazure-dev

# Ingress controller
kubectl get pods -n ingress-nginx

# Storage and certificates
kubectl get pv,pvc,certificates --all-namespaces
```

## 🛠️ Troubleshooting

### Common Issues

**1. Cluster Creation Timeout**
```
Symptom: EKS cluster creation takes >20 minutes
Solution: Check AWS service health, retry workflow
```

**2. Node Group Not Ready**
```
Symptom: Worker nodes stuck in "Not Ready" state
Solution: Check VPC/subnet configuration, security groups
```

**3. Add-on Installation Failures**
```
Symptom: NGINX or cert-manager pods failing
Solution: Check cluster resources, retry individual components
```

### Debug Commands

**Check cluster state:**
```bash
# Cluster status
aws eks describe-cluster --name awstoazure-cluster --region us-east-1

# Node group status  
aws eks describe-nodegroup --cluster-name awstoazure-cluster --nodegroup-name awstoazure-nodes --region us-east-1

# Kubectl configuration
kubectl config current-context
kubectl config get-contexts
```

**Manual cluster recovery:**
```bash
# Reconfigure kubectl
aws eks update-kubeconfig --region us-east-1 --name awstoazure-cluster

# Reinstall add-ons
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

## 🔐 Security Considerations

### IAM Permissions

**Required AWS permissions:**
- EKS cluster management
- EC2 instance management  
- VPC and networking
- IAM role creation
- ECR access

### Secrets Management

**GitHub Secrets required:**
```
AWS_ACCESS_KEY_ID     # AWS access key
AWS_SECRET_ACCESS_KEY # AWS secret key
```

**Auto-created secrets:**
```
ecr-registry-secret   # ECR authentication in each namespace
```

## 📈 Scaling Considerations

### Horizontal Scaling

**Application level:**
- HPA configured for 2-10 replicas
- CPU/Memory based auto-scaling
- Custom metrics support available

**Infrastructure level:**
- Node auto-scaling: 1-4 instances
- Multiple availability zones
- Load balancer integration

### Vertical Scaling

**Node types can be upgraded:**
- t3.medium → t3.large → t3.xlarge
- Modify `NODE_TYPE` in setup script
- Requires cluster recreation or node group update

## 🎛️ Advanced Configurations

### Custom Cluster Configuration

**Modify setup script variables:**
```bash
# In kubernetes/setup-cluster.sh
CLUSTER_NAME="my-custom-cluster"
NODE_TYPE="t3.large"
DESIRED_NODES=3
```

### Multi-Environment Clusters

**Option 1: Single cluster, multiple namespaces** (current)
- Cost-effective
- Shared resources
- Namespace isolation

**Option 2: Multiple clusters** (advanced)
- Complete isolation
- Higher costs
- Environment-specific configurations

### Production Hardening

**Additional security:**
- Network policies
- Pod security policies
- RBAC fine-tuning
- Cluster logging and monitoring
- Backup strategies

## 📞 Support

**For infrastructure issues:**
1. Check GitHub Actions logs
2. Verify AWS console for EKS status
3. Use `kubectl` debug commands
4. Check AWS CloudTrail for permission issues
5. Review EKS troubleshooting documentation

**Emergency cluster recovery:**
```bash
# If pipeline fails, manually recreate
./kubernetes/setup-cluster.sh

# Or delete and recreate via AWS console
```
