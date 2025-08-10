# Kubernetes Cluster Setup

This document provides instructions for setting up Kubernetes clusters for the AWS to Azure Migration application.

## Option 1: Amazon EKS (Recommended for AWS)

### Prerequisites
- AWS CLI configured
- eksctl installed
- kubectl installed

### 1. Create EKS Cluster

```bash
# Create EKS cluster with eksctl
eksctl create cluster \
  --name awstoazure-cluster \
  --region us-east-1 \
  --version 1.28 \
  --nodegroup-name awstoazure-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name awstoazure-cluster

# Verify connection
kubectl get nodes
```

### 2. EKS Cluster Configuration File

```yaml
# eks-cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: awstoazure-cluster
  region: us-east-1
  version: "1.28"

nodeGroups:
  - name: awstoazure-nodes
    instanceType: t3.medium
    minSize: 1
    maxSize: 4
    desiredCapacity: 2
    volumeSize: 20
    ssh:
      allow: false
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        externalDNS: true
        certManager: true
        awsLoadBalancerController: true

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver

cloudWatch:
  clusterLogging:
    enable: ["all"]
```

Deploy with:
```bash
eksctl create cluster -f eks-cluster.yaml
```

## Option 2: Azure AKS

### Prerequisites
- Azure CLI installed
- kubectl installed

### 1. Create Resource Group and AKS Cluster

```bash
# Create resource group
az group create --name awstoazure-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group awstoazure-rg \
  --name awstoazure-cluster \
  --node-count 2 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --node-vm-size Standard_DS2_v2

# Get credentials
az aks get-credentials --resource-group awstoazure-rg --name awstoazure-cluster

# Verify connection
kubectl get nodes
```

## Option 3: Local Development (minikube/kind)

### Using minikube

```bash
# Start minikube
minikube start --memory=4096 --cpus=2

# Enable ingress
minikube addons enable ingress

# Get cluster info
kubectl cluster-info
```

### Using kind

```bash
# Create cluster
kind create cluster --name awstoazure

# Load Docker image (for local development)
kind load docker-image 891377120087.dkr.ecr.us-east-1.amazonaws.com/aws2azurepo:latest --name awstoazure
```

## Essential Add-ons Setup

### 1. NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Verify installation
kubectl get pods -n ingress-nginx
```

### 2. Cert-Manager (for TLS certificates)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Verify installation
kubectl get pods -n cert-manager
```

### 3. Metrics Server (for HPA)

```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
kubectl get deployment metrics-server -n kube-system
```

## Monitoring Setup (Optional)

### Prometheus and Grafana

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Get Grafana password
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Security Configuration

### 1. Create Namespaces

```bash
# Create application namespaces
kubectl create namespace awstoazure-dev
kubectl create namespace awstoazure-staging
kubectl create namespace awstoazure-prod
```

### 2. ECR Image Pull Secret

```bash
# Create ECR registry secret for each namespace
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=891377120087.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace awstoazure-dev

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=891377120087.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace awstoazure-prod
```

### 3. Service Account with IAM Role (for EKS)

```bash
# Create IAM role for service account
eksctl create iamserviceaccount \
  --name awstoazure-sa \
  --namespace awstoazure-prod \
  --cluster awstoazure-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --approve
```

## Verification Commands

### Check Cluster Health
```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# All namespaces overview
kubectl get all --all-namespaces
```

### Test Application Deployment
```bash
# Test with a simple deployment
kubectl create deployment nginx --image=nginx --port=80
kubectl expose deployment nginx --port=80 --target-port=80
kubectl get all
```

## Troubleshooting

### Common Issues

1. **Node Not Ready**
   ```bash
   kubectl describe node <node-name>
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

2. **Pod Pending**
   ```bash
   kubectl describe pod <pod-name>
   kubectl get events --field-selector involvedObject.name=<pod-name>
   ```

3. **Image Pull Errors**
   ```bash
   kubectl get secrets
   kubectl describe secret ecr-registry-secret
   ```

4. **Ingress Issues**
   ```bash
   kubectl get ingress
   kubectl describe ingress <ingress-name>
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

## Next Steps

1. Choose your cluster option (EKS recommended)
2. Set up the cluster using the instructions above
3. Install essential add-ons
4. Configure the GitHub Actions pipeline with cluster credentials
5. Deploy the application using Helm charts
