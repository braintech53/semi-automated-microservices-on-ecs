# 🏗️ Architecture Overview: AWS ECS Microservice Deployment

This document provides a comprehensive overview of the infrastructure and architectural design principles behind our production-grade microservice deployment using Amazon ECS with Fargate launch type.

## 💡 Design Philosophy

This architecture demonstrates how to implement DevOps best practices using AWS-native tools and automation logic, without depending on external CI/CD frameworks. It's particularly suitable for scenarios where:

- DevOps resources are limited
- Infrastructure control is paramount
- Deployment flexibility is required
- Cost optimization is essential

## 🧱 Core Components

### Compute Layer
- **Amazon ECS (Fargate)**
  - Runs containerized microservices
  - Eliminates container instance management
  - Provides precise resource control

### Network Layer
- **Application Load Balancer (ALB)**
  - Handles path-based routing
  - Terminates SSL/TLS
  - Provides health checking

### Service Discovery
- **Amazon Route 53**
  - Manages DNS routing
  - Enables blue-green deployments
  - Facilitates service discovery

### Container Registry
- **Amazon ECR**
  - Stores Docker images
  - Provides version control
  - Enables vulnerability scanning

### Configuration Management
- **AWS Secrets Manager**
  - Manages sensitive data
  - Handles environment variables
  - Enables secret rotation

## 🔄 Service Architecture

### Microservice Structure
Each microservice is:
- Deployed as a separate ECS service
- Exposed via ALB path-based routing
- Independently scalable
- Isolated with its own task definition

### Service Mapping

| Microservice | ALB Path | Container | Environment Variables |
|--------------|----------|-----------|---------------------|
| Auth Service | `/auth/*` | `auth:latest` | DB credentials, JWT keys |
| Gmail Service | `/gmail/*` | `gmail:latest` | OAuth tokens |
| Calendar Service | `/calendar/*` | `calendar:latest` | API credentials |
| AI Router | `/ai/*` | `ai-router:latest` | Model endpoints |

## 🚀 Deployment Strategy

### Environment Separation

| Environment | Service Naming | Task Definition | ALB Path Prefix |
|-------------|----------------|-----------------|----------------|
| Test | `test-{service}` | `test-{service}` | `/test/*` |
| Staging | `stage-{service}` | `stage-{service}` | `/stage/*` |
| Production | `{service}` | `{service}` | `/*` |

### Deployment Flow
1. Code push to environment branch
2. Image build and ECR push
3. Task definition update
4. Service deployment
5. Health check verification
6. Auto-scaling adjustment

## 🛡️ Security Architecture

### Network Security
- VPC with public and private subnets
- Services in private subnets only
- ALB in public subnets
- Security group restrictions

### Access Control
- IAM roles per service
- Least privilege principle
- Resource-based policies
- Task execution roles

### Secret Management
- Centralized in AWS Secrets Manager
- Environment-specific secrets
- Automatic rotation enabled
- Secure injection at runtime

## 📊 Scaling Strategy

### Service Scaling
- CPU utilization-based
- Request count-based
- Custom metric support
- Independent per service

### Configuration
- Minimum tasks: 1
- Maximum tasks: 5 (configurable)
- Scale-out threshold: 60% CPU
- Cooldown period: 60 seconds

## 🔍 Monitoring and Logging

### CloudWatch Integration
- Container logs
- Performance metrics
- Custom dashboards
- Alarm configuration

### Health Checks
- ALB target group checks
- Container health checks
- Custom endpoint monitoring
- Automated recovery

## 📈 Cost Optimization

### Resource Efficiency
- Right-sized task definitions
- Automatic scaling
- Shared ECS cluster
- Spot capacity utilization

### Environment Sharing
- Common cluster for all environments
- Shared ALB with path-based routing
- Resource tagging for cost allocation
- Development/Production isolation

## 🔄 Disaster Recovery

### Backup Strategy
- ECR image versioning
- Task definition revisions
- Configuration backups
- Secret versioning

### Recovery Process
- Quick rollback capability
- Cross-AZ redundancy
- Service auto-recovery
- Health-based routing