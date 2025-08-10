# ArgoCD GitOps Configuration

This directory contains ArgoCD application configurations for automated GitOps deployment.

## Overview

ArgoCD monitors your Git repository and automatically deploys changes to your Kubernetes cluster when you push code.

## Applications

### Development Environment
- **File**: `application-dev.yaml`
- **Namespace**: `awstoazure-dev`
- **Branch**: `develop`
- **Auto-sync**: Enabled with auto-prune and self-heal

### Production Environment
- **File**: `application-prod.yaml`
- **Namespace**: `awstoazure-prod`
- **Branch**: `main`
- **Auto-sync**: Conservative (no auto-prune)

## ArgoCD Access

### Get ArgoCD URL
```bash
# Get LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Or use port-forward for local access
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Login Credentials
- **Username**: `admin`
- **Password**: Get from secret
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## GitOps Workflow

### Development Flow
1. Push changes to `develop` branch
2. ArgoCD detects changes automatically
3. Deploys to `awstoazure-dev` namespace
4. Auto-syncs with prune and self-heal

### Production Flow
1. Merge `develop` → `main` branch
2. ArgoCD detects changes in `main`
3. Deploys to `awstoazure-prod` namespace
4. More conservative sync (manual prune required)

## Application Configuration

### Auto-Sync Policies
- **Development**: Aggressive auto-sync with prune
- **Production**: Conservative auto-sync without auto-prune

### Retry Logic
- **Development**: Up to 5 retries with exponential backoff
- **Production**: Up to 3 retries with longer backoff

### Sync Options
- `CreateNamespace=true` - Auto-create target namespaces
- `ApplyOutOfSyncOnly=true` - Only apply changed resources

## Monitoring

### ArgoCD Dashboard
Access the ArgoCD UI to monitor deployments:
- Application status and health
- Sync history and logs
- Resource tree view
- Manual sync/rollback options

### CLI Access
Install ArgoCD CLI for command-line management:
```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login
argocd login <ARGOCD_SERVER>

# List applications
argocd app list

# Get application details
argocd app get awstoazure-dev
```

## Troubleshooting

### Common Issues

1. **Sync Failures**
   - Check application logs in ArgoCD UI
   - Verify Helm chart syntax
   - Check resource conflicts

2. **Image Pull Errors**
   - Verify ECR credentials are configured
   - Check image tag exists in registry
   - Validate imagePullSecrets

3. **Resource Conflicts**
   - Use `kubectl` to check existing resources
   - Manual cleanup may be required
   - Check for resource ownership

### Manual Operations
```bash
# Force sync an application
argocd app sync awstoazure-dev --force

# Rollback to previous version
argocd app rollback awstoazure-dev <HISTORY_ID>

# Delete and recreate application
argocd app delete awstoazure-dev
kubectl apply -f argocd/application-dev.yaml
```

## Integration with CI/CD

ArgoCD complements your GitHub Actions pipeline:

1. **CI Pipeline**: Build, test, and push images
2. **ArgoCD**: Automatically deploy when Helm charts change
3. **GitOps**: All deployments tracked in Git history

This creates a complete GitOps workflow where your Git repository is the single source of truth for your deployments.
