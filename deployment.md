# 🚀 Deployment Guide: ECS Microservice Infrastructure

This guide provides step-by-step instructions for deploying and managing containerized microservices on AWS ECS using Fargate. It covers the semi-automated deployment process that maintains control and visibility without requiring complex CI/CD pipelines.

## 📋 Prerequisites

### Required Tools
- AWS CLI v2 (configured with admin privileges)
- Docker Desktop
- Git
- jq (for JSON processing)

### AWS Resources
- ECS Cluster
- ECR Repositories
- Application Load Balancer
- VPC with public/private subnets
- Security Groups

## 🔄 Deployment Workflow

### 1. Image Build and Push

Use the provided script to build and push Docker images to ECR:

```bash
# Build and push image for a specific service and environment
./deploy-scripts/push-to-ecr.sh auth-service production
```

The script handles:
- ECR authentication
- Image building
- Tagging based on environment
- Pushing to ECR

### 2. Task Definition Management

Update the ECS task definition using the provided script:

```bash
# Update task definition for a service
./deploy-scripts/update-task-definition.sh auth-service production
```

This process:
- Retrieves current task definition
- Updates container image
- Registers new revision
- Maintains other configurations

### 3. Service Deployment

Deploy the updated task definition:

```bash
# Update the ECS service
./deploy-scripts/update-service.sh auth-service production
```

The script:
- Updates service with new task definition
- Monitors deployment progress
- Verifies health checks

## 🌐 Environment Management

### Environment Structure

| Component | Test | Staging | Production |
|-----------|------|---------|------------|
| Branch | `test` | `stage` | `main` |
| Image Tag | `test` | `stage` | `latest` |
| Service Prefix | `test-` | `stage-` | none |
| ALB Path | `/test/*` | `/stage/*` | `/*` |

### Environment-Specific Deployment

1. **Test Environment**
   ```bash
   ./deploy-scripts/push-to-ecr.sh auth-service test
   ./deploy-scripts/update-task-definition.sh auth-service test
   ./deploy-scripts/update-service.sh auth-service test
   ```

2. **Staging Environment**
   ```bash
   ./deploy-scripts/push-to-ecr.sh auth-service stage
   ./deploy-scripts/update-task-definition.sh auth-service stage
   ./deploy-scripts/update-service.sh auth-service stage
   ```

3. **Production Environment**
   ```bash
   ./deploy-scripts/push-to-ecr.sh auth-service production
   ./deploy-scripts/update-task-definition.sh auth-service production
   ./deploy-scripts/update-service.sh auth-service production
   ```

## 🔄 Rollback Procedure

### Quick Rollback

1. **Identify Previous Version**
   ```bash
   aws ecs describe-task-definition \
     --task-definition auth-service \
     --query 'taskDefinition.revision'
   ```

2. **Revert to Previous Revision**
   ```bash
   aws ecs update-service \
     --cluster microservices-cluster \
     --service auth-service \
     --task-definition auth-service:${PREVIOUS_REVISION} \
     --force-new-deployment
   ```

### Image Rollback

1. **Re-tag Previous Image**
   ```bash
   aws ecr batch-get-image \
     --repository-name auth-service \
     --image-ids imageTag=previous \
     --query 'images[].imageManifest' \
     --output text | \
   aws ecr put-image \
     --repository-name auth-service \
     --image-tag latest \
     --image-manifest -
   ```

2. **Update Service**
   ```bash
   ./deploy-scripts/update-service.sh auth-service production
   ```

## 📊 Monitoring Deployment

### Health Checks

1. **Service Status**
   ```bash
   aws ecs describe-services \
     --cluster microservices-cluster \
     --services auth-service \
     --query 'services[].events'
   ```

2. **Task Health**
   ```bash
   aws ecs list-tasks \
     --cluster microservices-cluster \
     --service-name auth-service \
     --desired-status RUNNING
   ```

### CloudWatch Logs

```bash
# View recent logs
aws logs get-log-events \
  --log-group-name /ecs/auth-service/production \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name /ecs/auth-service/production \
    --order-by LastEventTime \
    --descending \
    --limit 1 \
    --query 'logStreams[0].logStreamName' \
    --output text)
```

## 🔍 Troubleshooting

### Common Issues

1. **Task Not Starting**
   - Check security groups
   - Verify subnet configuration
   - Review task execution role

2. **Health Check Failures**
   - Validate container health check endpoint
   - Check application logs
   - Verify ALB target group settings

3. **Resource Constraints**
   - Monitor CPU/Memory utilization
   - Review service limits
   - Check scaling policies

## 📝 Best Practices

1. **Version Control**
   - Tag images meaningfully
   - Maintain task definition versions
   - Document deployment changes

2. **Security**
   - Rotate secrets regularly
   - Update task execution roles
   - Review security group rules

3. **Monitoring**
   - Set up CloudWatch alarms
   - Monitor service metrics
   - Configure log retention
