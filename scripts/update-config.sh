#!/bin/bash

# Automated Configuration Update Script
# This script can be called from CI/CD to update configurations programmatically

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
CONFIG_FILE="helm/awstoazure/values-${ENVIRONMENT}.yaml"

echo "🔧 Updating configuration for ${ENVIRONMENT} environment..."

# Update image tag
yq eval ".image.tag = \"${IMAGE_TAG}\"" -i "${CONFIG_FILE}"

# Auto-scale replicas based on environment
if [ "${ENVIRONMENT}" = "prod" ]; then
    echo "📈 Setting production scaling..."
    yq eval '.replicaCount = 3' -i "${CONFIG_FILE}"
    yq eval '.autoscaling.enabled = true' -i "${CONFIG_FILE}"
    yq eval '.autoscaling.minReplicas = 3' -i "${CONFIG_FILE}"
    yq eval '.autoscaling.maxReplicas = 10' -i "${CONFIG_FILE}"
    yq eval '.resources.requests.cpu = "500m"' -i "${CONFIG_FILE}"
    yq eval '.resources.requests.memory = "1Gi"' -i "${CONFIG_FILE}"
    yq eval '.resources.limits.cpu = "1000m"' -i "${CONFIG_FILE}"
    yq eval '.resources.limits.memory = "2Gi"' -i "${CONFIG_FILE}"
else
    echo "🧪 Setting development scaling..."
    yq eval '.replicaCount = 1' -i "${CONFIG_FILE}"
    yq eval '.autoscaling.enabled = false' -i "${CONFIG_FILE}"
    yq eval '.resources.requests.cpu = "250m"' -i "${CONFIG_FILE}"
    yq eval '.resources.requests.memory = "512Mi"' -i "${CONFIG_FILE}"
    yq eval '.resources.limits.cpu = "500m"' -i "${CONFIG_FILE}"
    yq eval '.resources.limits.memory = "1Gi"' -i "${CONFIG_FILE}"
fi

# Update based on branch/environment
BRANCH=${GITHUB_REF#refs/heads/}
case "${BRANCH}" in
    "main"|"master")
        echo "🚀 Production configuration applied"
        yq eval '.ingress.hosts[0].host = "awstoazure.yourdomain.com"' -i "${CONFIG_FILE}"
        ;;
    "develop")
        echo "🧪 Development configuration applied"
        yq eval '.ingress.hosts[0].host = "awstoazure-dev.yourdomain.com"' -i "${CONFIG_FILE}"
        ;;
    *)
        echo "🔧 Feature branch configuration applied"
        yq eval '.ingress.hosts[0].host = "awstoazure-'"${BRANCH}"'.yourdomain.com"' -i "${CONFIG_FILE}"
        ;;
esac

# Auto-configure monitoring based on environment
if [ "${ENVIRONMENT}" = "prod" ]; then
    yq eval '.serviceMonitor.enabled = true' -i "${CONFIG_FILE}"
    yq eval '.serviceMonitor.interval = "30s"' -i "${CONFIG_FILE}"
else
    yq eval '.serviceMonitor.enabled = false' -i "${CONFIG_FILE}"
fi

echo "✅ Configuration updated for ${ENVIRONMENT}"
echo "📄 Updated file: ${CONFIG_FILE}"

# Show the changes
echo "🔍 Changes made:"
git diff "${CONFIG_FILE}" || echo "No git repository detected"
