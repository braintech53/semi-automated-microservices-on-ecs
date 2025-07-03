#!/bin/bash

# Script to build and push Docker images to Amazon ECR
# Usage: ./push-to-ecr.sh <service-name> <environment>

set -e

# Validate input parameters
if [ "$#" -ne 2 ]; then
    echo "Error: Missing required parameters"
    echo "Usage: $0 <service-name> <environment>"
    echo "Example: $0 auth-service production"
    exit 1
}

SERVICE_NAME=$1
ENVIRONMENT=$2
REGION="us-west-2"  # Change this to your AWS region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(test|stage|production)$ ]]; then
    echo "Error: Environment must be 'test', 'stage', or 'production'"
    exit 1
}

# Set image tag based on environment
if [ "$ENVIRONMENT" == "production" ]; then
    TAG="latest"
else
    TAG="$ENVIRONMENT"
fi

# ECR repository URL
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$SERVICE_NAME"

echo "🔑 Authenticating with Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO

echo "🏗️ Building Docker image..."
docker build -t $SERVICE_NAME:$TAG .

echo "🏷️ Tagging image for ECR..."
docker tag $SERVICE_NAME:$TAG $ECR_REPO:$TAG

echo "⬆️ Pushing to ECR..."
docker push $ECR_REPO:$TAG

echo "✅ Successfully pushed $SERVICE_NAME:$TAG to ECR"