#!/bin/bash

# Helm Deployment Script for AWS to Azure Migration App
set -e

# Configuration
CHART_PATH="./awstoazure"
NAMESPACE=""
ENVIRONMENT=""
VALUES_FILE=""
IMAGE_TAG="latest"
RELEASE_NAME=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment    Environment (dev|staging|prod)"
    echo "  -n, --namespace      Kubernetes namespace"
    echo "  -t, --tag           Docker image tag (default: latest)"
    echo "  -r, --release       Helm release name"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment dev --namespace awstoazure-dev"
    echo "  $0 -e prod -n awstoazure-prod -t v1.2.3"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ENVIRONMENT" ]]; then
    print_error "Environment is required. Use -e or --environment"
    usage
fi

if [[ -z "$NAMESPACE" ]]; then
    print_error "Namespace is required. Use -n or --namespace"
    usage
fi

# Set default release name if not provided
if [[ -z "$RELEASE_NAME" ]]; then
    RELEASE_NAME="awstoazure-${ENVIRONMENT}"
fi

# Set values file based on environment
case $ENVIRONMENT in
    dev|development)
        VALUES_FILE="values-dev.yaml"
        ;;
    staging)
        VALUES_FILE="values-staging.yaml"
        ;;
    prod|production)
        VALUES_FILE="values-prod.yaml"
        ;;
    *)
        print_error "Invalid environment: $ENVIRONMENT. Supported: dev, staging, prod"
        exit 1
        ;;
esac

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible."
    exit 1
fi

# Check if values file exists
if [[ ! -f "$CHART_PATH/$VALUES_FILE" ]]; then
    print_error "Values file not found: $CHART_PATH/$VALUES_FILE"
    exit 1
fi

print_status "Starting Helm deployment..."
print_status "Environment: $ENVIRONMENT"
print_status "Namespace: $NAMESPACE"
print_status "Release Name: $RELEASE_NAME"
print_status "Image Tag: $IMAGE_TAG"
print_status "Values File: $VALUES_FILE"

# Create namespace if it doesn't exist
print_status "Creating namespace if it doesn't exist..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Validate Helm chart
print_status "Validating Helm chart..."
helm lint "$CHART_PATH"

# Dry run first
print_status "Performing dry run..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --values "$CHART_PATH/$VALUES_FILE" \
    --set image.tag="$IMAGE_TAG" \
    --dry-run

# Ask for confirmation
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled by user."
    exit 0
fi

# Deploy with Helm
print_status "Deploying with Helm..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --values "$CHART_PATH/$VALUES_FILE" \
    --set image.tag="$IMAGE_TAG" \
    --wait \
    --timeout=300s

print_success "Deployment completed successfully!"

# Show deployment status
print_status "Deployment status:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=awstoazure

print_status "Service status:"
kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/name=awstoazure

if [[ "$ENVIRONMENT" != "dev" ]]; then
    print_status "Ingress status:"
    kubectl get ingress -n "$NAMESPACE"
fi

print_success "Deployment completed! Check the output above for service details."
