#!/bin/bash

# Script to update ECS services with new task definition revisions
# Usage: ./update-service.sh <service-name> <environment>

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
CLUSTER_NAME="microservices-cluster"  # Change this to your cluster name
REGION="us-west-2"  # Change this to your AWS region

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(test|stage|production)$ ]]; then
    echo "Error: Environment must be 'test', 'stage', or 'production'"
    exit 1
}

# Set service and task family names based on environment
if [ "$ENVIRONMENT" == "production" ]; then
    ECS_SERVICE_NAME="$SERVICE_NAME"
    TASK_FAMILY="$SERVICE_NAME"
else
    ECS_SERVICE_NAME="${ENVIRONMENT}-${SERVICE_NAME}"
    TASK_FAMILY="${ENVIRONMENT}-${SERVICE_NAME}"
fi

echo "📋 Getting latest task definition revision..."
TASK_REVISION=$(aws ecs describe-task-definition \
    --task-definition $TASK_FAMILY \
    --query 'taskDefinition.revision' \
    --output text)

TASK_DEFINITION="${TASK_FAMILY}:${TASK_REVISION}"

echo "🔄 Updating ECS service..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $ECS_SERVICE_NAME \
    --task-definition $TASK_DEFINITION \
    --force-new-deployment

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $ECS_SERVICE_NAME

echo "✅ Service update completed successfully!"
echo "🔍 New task definition: $TASK_DEFINITION"