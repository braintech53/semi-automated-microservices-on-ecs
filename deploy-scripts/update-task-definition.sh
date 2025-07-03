#!/bin/bash

# Script to update ECS task definitions with new image versions
# Usage: ./update-task-definition.sh <service-name> <environment>

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

# Set task definition name based on environment
if [ "$ENVIRONMENT" == "production" ]; then
    TASK_FAMILY="$SERVICE_NAME"
    IMAGE_TAG="latest"
else
    TASK_FAMILY="${ENVIRONMENT}-${SERVICE_NAME}"
    IMAGE_TAG="$ENVIRONMENT"
fi

ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$SERVICE_NAME"

echo "📋 Retrieving current task definition..."
TASK_DEFINITION=$(aws ecs describe-task-definition \
    --task-definition $TASK_FAMILY \
    --query 'taskDefinition' \
    --output json)

echo "🔄 Updating container image..."
NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | \
    jq --arg IMAGE "$ECR_REPO:$IMAGE_TAG" \
    '.containerDefinitions[0].image = $IMAGE')

echo "📝 Registering new task definition..."
NEW_TASK_REVISION=$(aws ecs register-task-definition \
    --family $TASK_FAMILY \
    --cli-input-json "$NEW_TASK_DEFINITION" \
    --query 'taskDefinition.revision' \
    --output text)

echo "✅ Successfully registered new task definition: ${TASK_FAMILY}:${NEW_TASK_REVISION}"