#!/bin/bash

# Kubernetes Cluster Setup Script
set -e

# Configuration
CLUSTER_NAME="awstoazure-cluster"
REGION="us-east-1"
NODE_TYPE="t3.medium"
MIN_NODES=1
MAX_NODES=4
DESIRED_NODES=2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! command -v eksctl &> /dev/null; then
        print_error "eksctl is not installed. Please install eksctl first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    print_success "All prerequisites are installed!"
}

# Create EKS cluster
create_eks_cluster() {
    print_status "Creating EKS cluster: $CLUSTER_NAME"
    
    eksctl create cluster \
        --name $CLUSTER_NAME \
        --region $REGION \
        --version 1.28 \
        --nodegroup-name ${CLUSTER_NAME}-nodes \
        --node-type $NODE_TYPE \
        --nodes $DESIRED_NODES \
        --nodes-min $MIN_NODES \
        --nodes-max $MAX_NODES \
        --managed \
        --with-oidc \
        --ssh-access=false \
        --full-ecr-access
    
    print_success "EKS cluster created successfully!"
}

# Configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl..."
    
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    print_status "Verifying cluster connection..."
    kubectl cluster-info
    kubectl get nodes
    
    print_success "kubectl configured successfully!"
}

# Install essential add-ons
install_addons() {
    print_status "Installing essential add-ons..."
    
    # Install NGINX Ingress Controller
    print_status "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    # Wait for ingress controller to be ready
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    # Install cert-manager
    print_status "Installing cert-manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --namespace cert-manager \
        --for=condition=ready pod \
        --selector=app=cert-manager \
        --timeout=300s
    
    # Install metrics server (if not already installed)
    print_status "Installing metrics server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    print_success "Add-ons installed successfully!"
}

# Create namespaces
create_namespaces() {
    print_status "Creating application namespaces..."
    
    kubectl apply -f ../manifests/namespace.yaml
    
    print_success "Namespaces created successfully!"
}

# Setup ECR secrets
setup_ecr_secrets() {
    print_status "Setting up ECR registry secrets..."
    
    # Get ECR login token
    ECR_PASSWORD=$(aws ecr get-login-password --region $REGION)
    ECR_REGISTRY="891377120087.dkr.ecr.us-east-1.amazonaws.com"
    
    # Create secrets for each namespace
    for namespace in awstoazure-dev awstoazure-staging awstoazure-prod; do
        print_status "Creating ECR secret for namespace: $namespace"
        kubectl create secret docker-registry ecr-registry-secret \
            --docker-server=$ECR_REGISTRY \
            --docker-username=AWS \
            --docker-password=$ECR_PASSWORD \
            --namespace=$namespace \
            --dry-run=client -o yaml | kubectl apply -f -
    done
    
    print_success "ECR secrets created successfully!"
}

# Setup monitoring (optional)
setup_monitoring() {
    print_status "Setting up monitoring (Prometheus & Grafana)..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install Prometheus stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set grafana.adminPassword=admin123 \
        --wait
    
    print_success "Monitoring setup completed!"
    print_status "Grafana admin password: admin123"
}

# Main execution
main() {
    print_status "Starting Kubernetes cluster setup..."
    
    check_prerequisites
    
    # Skip confirmation if running in CI/CD
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        # Ask for confirmation
        echo ""
        echo "This script will create an EKS cluster with the following configuration:"
        echo "  Cluster Name: $CLUSTER_NAME"
        echo "  Region: $REGION"
        echo "  Node Type: $NODE_TYPE"
        echo "  Min Nodes: $MIN_NODES"
        echo "  Max Nodes: $MAX_NODES"
        echo "  Desired Nodes: $DESIRED_NODES"
        echo ""
        read -p "Do you want to proceed? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Setup cancelled by user."
            exit 0
        fi
    else
        print_status "Running in CI/CD mode - skipping confirmation"
    fi
    
    create_eks_cluster
    configure_kubectl
    install_addons
    create_namespaces
    setup_ecr_secrets
    
    # Ask if user wants monitoring (skip in CI/CD)
    if [[ "$SKIP_MONITORING" != "true" ]]; then
        echo ""
        read -p "Do you want to install monitoring (Prometheus & Grafana)? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_monitoring
        fi
    else
        print_status "Skipping monitoring setup in CI/CD mode"
    fi
    
    print_success "Kubernetes cluster setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Update your domain names in helm values files"
    echo "2. Deploy your application with: ./helm/deploy.sh --environment dev --namespace awstoazure-dev"
    echo "3. Access your cluster with: kubectl get all --all-namespaces"
}

# Run main function
main "$@"
