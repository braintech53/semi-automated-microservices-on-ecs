# 🔐 Environment Setup with AWS Secrets Manager

This guide explains how environment variables and sensitive credentials are managed securely using AWS Secrets Manager in our ECS Fargate microservice infrastructure.

## 🎯 Objective

- Implement secure secret management without hardcoding credentials
- Establish a robust environment variable handling system
- Enable automated secret rotation and comprehensive auditing
- Maintain environment-specific configurations

## 🧱 Core Components

| Component | Purpose | Key Features |
|-----------|---------|-------------|
| AWS Secrets Manager | Secret Storage | Encryption, Rotation, Access Control |
| ECS Task Definitions | Secret Integration | Container-level Environment Variables |
| IAM Roles | Access Control | Fine-grained Permissions |
| CloudWatch | Monitoring & Auditing | Logs, Metrics, Alerts |

## 🔑 Secret Management

### Creating Secrets

#### Using AWS CLI

```bash
# Create a new secret with JSON structure
aws secretsmanager create-secret \
  --name auth-service-prod-config \
  --description "Production configuration for auth-service" \
  --secret-string '{
    "MONGODB_URI": "mongodb+srv://user:pass@cluster.mongodb.net/db",
    "JWT_SECRET": "your-secret-key",
    "API_KEY": "your-api-key"
  }'
```

#### Using AWS Console

1. Navigate to AWS Secrets Manager
2. Select "Store a new secret"
3. Choose "Other type of secret"
4. Add key-value pairs for your configuration
5. Follow the naming convention
6. Configure rotation settings if needed

### Naming Convention

```plaintext
<service-name>-<environment>-<secret-type>

Examples:
- auth-service-prod-config
- payment-service-stage-api-keys
- notification-service-test-credentials
```

## 📜 IAM Configuration

### Task Execution Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${region}:${account-id}:secret:${service-name}-${environment}-*"
      ]
    }
  ]
}
```

### Development Access Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:UpdateSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${region}:${account-id}:secret:*-test-*",
        "arn:aws:secretsmanager:${region}:${account-id}:secret:*-stage-*"
      ]
    }
  ]
}
```

## 🧪 ECS Integration

### Task Definition Configuration

```json
{
  "containerDefinitions": [
    {
      "name": "auth-service",
      "image": "${ECR_REPOSITORY_URI}:latest",
      "secrets": [
        {
          "name": "MONGODB_URI",
          "valueFrom": "arn:aws:secretsmanager:${region}:${account-id}:secret:auth-service-prod-config:MONGODB_URI::"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:${region}:${account-id}:secret:auth-service-prod-config:JWT_SECRET::"
        },
        {
          "name": "API_KEY",
          "valueFrom": "arn:aws:secretsmanager:${region}:${account-id}:secret:auth-service-prod-config:API_KEY::"
        }
      ]
    }
  ]
}
```

## 🔄 Secret Rotation

### Automatic Rotation

```bash
# Enable automatic rotation
aws secretsmanager rotate-secret \
  --secret-id auth-service-prod-config \
  --rotation-lambda-arn arn:aws:lambda:${region}:${account-id}:function:secret-rotation \
  --rotation-rules AutomaticallyAfterDays=30
```

### Manual Rotation Process

1. Create new credentials
2. Update secret value
3. Deploy updated service
4. Verify functionality
5. Remove old credentials

## 📊 Monitoring and Auditing

### CloudWatch Integration

```bash
# Create alert for excessive secret access
aws cloudwatch put-metric-alarm \
  --alarm-name prod-secret-access-alert \
  --metric-name GetSecretValue \
  --namespace AWS/SecretsManager \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### Access Logging

```bash
# View secret access history
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetSecretValue
```

## ⚠️ Security Guidelines

### Best Practices

✅ **Do**:
- Use environment-specific secrets
- Implement automatic rotation
- Monitor secret access
- Maintain audit logs
- Use least-privilege permissions

❌ **Don't**:
- Hardcode secrets in task definitions
- Store credentials in Dockerfiles
- Use plaintext environment files
- Share secrets across environments
- Grant excessive permissions

## 🔍 Troubleshooting

### Common Issues

1. **Secret Access Denied**
   - Verify IAM role permissions
   - Check resource ARN format
   - Validate KMS key access

2. **Secret Not Found**
   - Confirm secret name/ARN
   - Check environment suffix
   - Verify region settings

3. **Rotation Failures**
   - Review Lambda function logs
   - Check rotation permissions
   - Validate rotation configuration

This comprehensive setup ensures secure and efficient management of environment variables and secrets across your microservices architecture.
