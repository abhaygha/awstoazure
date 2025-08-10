# AWS to Azure Migration App - Helm Chart

This Helm chart deploys the AWS to Azure Migration Spring Boot application to Kubernetes.

## Prerequisites

- Kubernetes cluster (EKS, AKS, or any other K8s cluster)
- Helm 3.x installed
- kubectl configured to access your cluster
- Docker image available in ECR: `891377120087.dkr.ecr.us-east-1.amazonaws.com/aws2azurepo`

## Chart Structure

```
helm/awstoazure/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── values-dev.yaml           # Development environment values
├── values-prod.yaml          # Production environment values
├── templates/
│   ├── deployment.yaml       # Kubernetes Deployment
│   ├── service.yaml          # Kubernetes Service
│   ├── ingress.yaml          # Ingress configuration
│   ├── serviceaccount.yaml   # Service Account
│   ├── configmap.yaml        # Configuration Map
│   ├── secrets.yaml          # Secrets
│   ├── hpa.yaml              # Horizontal Pod Autoscaler
│   ├── pdb.yaml              # Pod Disruption Budget
│   ├── servicemonitor.yaml   # Prometheus ServiceMonitor
│   ├── _helpers.tpl          # Template helpers
│   └── NOTES.txt             # Post-installation notes
└── README.md                 # This file
```

## Quick Start

### 1. Install to Development Environment

```bash
# Using the deployment script
./deploy.sh --environment dev --namespace awstoazure-dev

# Or directly with Helm
helm install awstoazure-dev ./awstoazure \
  --namespace awstoazure-dev \
  --create-namespace \
  --values ./awstoazure/values-dev.yaml
```

### 2. Install to Production Environment

```bash
# Using the deployment script
./deploy.sh --environment prod --namespace awstoazure-prod --tag v1.0.0

# Or directly with Helm
helm install awstoazure-prod ./awstoazure \
  --namespace awstoazure-prod \
  --create-namespace \
  --values ./awstoazure/values-prod.yaml \
  --set image.tag=v1.0.0
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Docker image repository | `891377120087.dkr.ecr.us-east-1.amazonaws.com/aws2azurepo` |
| `image.tag` | Docker image tag | `latest` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `true` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `512Mi` |

### Environment-Specific Values

#### Development (`values-dev.yaml`)
- Single replica
- Lower resource limits
- Basic ingress without TLS
- No autoscaling
- Monitoring disabled

#### Production (`values-prod.yaml`)
- Multiple replicas (3+)
- Higher resource limits
- Ingress with TLS
- Autoscaling enabled
- Monitoring enabled
- Pod disruption budget

### Custom Configuration

Create your own values file:

```yaml
# values-custom.yaml
replicaCount: 2

image:
  tag: "v1.2.3"

ingress:
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: 1000m
    memory: 1Gi
```

Then deploy with:
```bash
helm install myrelease ./awstoazure -f values-custom.yaml
```

## Commands

### Installation
```bash
# Install
helm install <release-name> ./awstoazure

# Install with custom values
helm install <release-name> ./awstoazure -f values-custom.yaml

# Install with specific image tag
helm install <release-name> ./awstoazure --set image.tag=v1.0.0
```

### Upgrades
```bash
# Upgrade
helm upgrade <release-name> ./awstoazure

# Upgrade with new image
helm upgrade <release-name> ./awstoazure --set image.tag=v1.1.0
```

### Management
```bash
# List releases
helm list

# Get release status
helm status <release-name>

# Get release values
helm get values <release-name>

# Rollback
helm rollback <release-name> <revision>

# Uninstall
helm uninstall <release-name>
```

### Debugging
```bash
# Dry run
helm install <release-name> ./awstoazure --dry-run

# Template rendering
helm template <release-name> ./awstoazure

# Lint chart
helm lint ./awstoazure
```

## Monitoring

The chart includes monitoring capabilities:

- **Health Checks**: Liveness and readiness probes
- **Metrics**: Prometheus metrics via `/actuator/prometheus`
- **ServiceMonitor**: Automatic Prometheus scraping (when enabled)

### Health Endpoints

- Liveness: `/actuator/health/liveness`
- Readiness: `/actuator/health/readiness`
- Health: `/actuator/health`

## Security

### Security Features

- Non-root user execution
- Security contexts configured
- Network policies (optional)
- Secret management
- Service account with minimal permissions

### Image Pull Secrets

For private registries, configure image pull secrets:

```yaml
imagePullSecrets:
  - name: ecr-registry-secret
```

Create the secret:
```bash
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=891377120087.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)
```

## Scaling

### Manual Scaling
```bash
kubectl scale deployment <deployment-name> --replicas=5
```

### Auto Scaling (HPA)
Enabled by default in production. Scales based on:
- CPU utilization (70%)
- Memory utilization (80%)

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check image pull secrets
   kubectl get secrets
   kubectl describe pod <pod-name>
   ```

2. **Health Check Failures**
   ```bash
   # Check pod logs
   kubectl logs <pod-name>
   
   # Check health endpoints
   kubectl port-forward <pod-name> 8080:8080
   curl http://localhost:8080/actuator/health
   ```

3. **Ingress Issues**
   ```bash
   # Check ingress controller
   kubectl get ingress
   kubectl describe ingress <ingress-name>
   ```

### Debug Commands
```bash
# Get all resources
kubectl get all -l app.kubernetes.io/name=awstoazure

# Describe deployment
kubectl describe deployment <deployment-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Pod logs
kubectl logs -f deployment/<deployment-name>
```

## CI/CD Integration

The chart is integrated with GitHub Actions:

- **Development**: Auto-deploy on push to `develop` branch
- **Production**: Auto-deploy on push to `main` branch
- **Image Tagging**: Uses commit SHA for image versioning

### Manual Deployment Commands

```bash
# Development deployment
helm upgrade --install awstoazure-dev ./helm/awstoazure \
  --namespace awstoazure-dev \
  --create-namespace \
  --values ./helm/awstoazure/values-dev.yaml \
  --set image.tag=<commit-sha>

# Production deployment
helm upgrade --install awstoazure-prod ./helm/awstoazure \
  --namespace awstoazure-prod \
  --create-namespace \
  --values ./helm/awstoazure/values-prod.yaml \
  --set image.tag=<version-tag>
```

## Support

For issues and questions:
1. Check this documentation
2. Review Kubernetes events and logs
3. Validate Helm chart with `helm lint`
4. Use `helm template` to debug rendering issues
