# 🚀 ECS Deployment Standard Operating Procedure

This document outlines the step-by-step process for deploying and managing containerized microservices on AWS ECS using Fargate. It provides detailed procedures, best practices, and troubleshooting guidelines.

## 📋 Prerequisites

### Required Tools
- AWS CLI configured with appropriate credentials
- Docker installed and configured
- Access to AWS ECR repositories
- Proper IAM roles and permissions

### Required Files
- Dockerfile for each service
- Task definition templates
- Service configuration files
- Deployment scripts

## 🔄 Deployment Workflow

### 1. Build and Push Docker Image

```bash
# Navigate to service directory
cd service-directory

# Build Docker image
docker build -t auth-service .

# Tag image for ECR
docker tag auth-service:latest ${ECR_REPOSITORY_URI}:${VERSION}

# Push to ECR
docker push ${ECR_REPOSITORY_URI}:${VERSION}
```

Refer to <mcfile name="push-to-ecr.sh" path="deploy-scripts/push-to-ecr.sh"></mcfile> for the automated script.

### 2. Update Task Definition

```bash
# Get current task definition
aws ecs describe-task-definition \
  --task-definition auth-service \
  --query 'taskDefinition' > task-def.json

# Update image version
# Edit task-def.json to update the image URI

# Register new task definition
aws ecs register-task-definition \
  --cli-input-json file://task-def.json
```

Refer to <mcfile name="update-task-definition.sh" path="deploy-scripts/update-task-definition.sh"></mcfile> for the automated script.

### 3. Deploy Service

```bash
# Update service with new task definition
aws ecs update-service \
  --cluster microservices-cluster \
  --service auth-service \
  --task-definition auth-service:${REVISION} \
  --force-new-deployment

# Monitor deployment
aws ecs describe-services \
  --cluster microservices-cluster \
  --services auth-service
```

Refer to <mcfile name="update-service.sh" path="deploy-scripts/update-service.sh"></mcfile> for the automated script.

## 🌐 Environment Management

### Production Deployment

1. **Pre-deployment Checklist**
   - [ ] All tests passed in staging
   - [ ] Required approvals obtained
   - [ ] Backup current task definition
   - [ ] Database migrations ready
   - [ ] Monitoring alerts configured

2. **Deployment Steps**
   ```bash
   # Deploy to production
   ./deploy-scripts/push-to-ecr.sh -e prod -s auth-service -v 1.0.0
   ./deploy-scripts/update-task-definition.sh -e prod -s auth-service
   ./deploy-scripts/update-service.sh -e prod -s auth-service
   ```

3. **Post-deployment Verification**
   - [ ] Health checks passing
   - [ ] Metrics normal
   - [ ] No error logs
   - [ ] Feature verification

### Staging Deployment

1. **Pre-deployment Steps**
   - [ ] Development tests passed
   - [ ] Configuration validated
   - [ ] Dependencies updated

2. **Deployment Commands**
   ```bash
   # Deploy to staging
   ./deploy-scripts/push-to-ecr.sh -e stage -s auth-service -v 1.0.0-rc1
   ./deploy-scripts/update-task-definition.sh -e stage -s auth-service
   ./deploy-scripts/update-service.sh -e stage -s auth-service
   ```

### Test Environment

1. **Deployment Process**
   ```bash
   # Deploy to test
   ./deploy-scripts/push-to-ecr.sh -e test -s auth-service -v dev
   ./deploy-scripts/update-task-definition.sh -e test -s auth-service
   ./deploy-scripts/update-service.sh -e test -s auth-service
   ```

## 🔄 Rollback Procedure

### Immediate Rollback

```bash
# Get previous task definition revision
PREV_REVISION=$(aws ecs describe-task-definition \
  --task-definition auth-service:${CURRENT_REVISION-1} \
  --query 'taskDefinition.revision')

# Update service to previous version
aws ecs update-service \
  --cluster microservices-cluster \
  --service auth-service \
  --task-definition auth-service:${PREV_REVISION} \
  --force-new-deployment
```

### Gradual Rollback

1. **Preparation**
   - Identify stable version
   - Verify configuration compatibility
   - Prepare rollback task definition

2. **Execution**
   - Deploy previous version alongside current
   - Gradually shift traffic
   - Monitor for issues

3. **Verification**
   - Confirm service stability
   - Verify feature functionality
   - Check integration points

## 📊 Monitoring

### Deployment Metrics

```bash
# Monitor service events
aws ecs describe-services \
  --cluster microservices-cluster \
  --services auth-service \
  --query 'services[].events[]'

# Check task status
aws ecs list-tasks \
  --cluster microservices-cluster \
  --service-name auth-service \
  --desired-status RUNNING
```

### Health Checks

1. **Application Health**
   - Endpoint response
   - Error rates
   - Response times

2. **Infrastructure Health**
   - CPU utilization
   - Memory usage
   - Network metrics

## 🔍 Troubleshooting

### Common Issues

1. **Task Launch Failures**
   - Check task definition validity
   - Verify IAM roles
   - Review resource constraints

2. **Service Instability**
   - Monitor CloudWatch logs
   - Check scaling metrics
   - Verify network configuration

3. **Performance Issues**
   - Review resource allocation
   - Check connection limits
   - Analyze scaling patterns

### Debug Commands

```bash
# Get task logs
aws logs get-log-events \
  --log-group-name /ecs/auth-service \
  --log-stream-name ${TASK_ID}

# Check service discovery
aws servicediscovery get-namespace \
  --id ${NAMESPACE_ID}

# Verify load balancer health
aws elbv2 describe-target-health \
  --target-group-arn ${TARGET_GROUP_ARN}
```

## 📝 Best Practices

### Deployment Strategy

1. **Release Planning**
   - Use semantic versioning
   - Maintain changelog
   - Plan deployment windows

2. **Testing**
   - Automated testing
   - Integration testing
   - Load testing

3. **Monitoring**
   - Set up alerts
   - Monitor metrics
   - Log analysis

### Security Considerations

1. **Access Control**
   - Use IAM roles
   - Implement least privilege
   - Regular audit

2. **Network Security**
   - VPC configuration
   - Security groups
   - NACLs

3. **Data Protection**
   - Encrypt sensitive data
   - Secure secrets
   - Backup strategy

This SOP ensures consistent and reliable deployments across all environments while maintaining security and performance standards.