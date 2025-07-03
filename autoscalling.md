# 📈 Auto Scaling Configuration Guide

This document details the auto-scaling setup for microservices deployed on AWS ECS using Fargate. It covers configuration, monitoring, and best practices for maintaining optimal performance and cost efficiency.

## 🎯 Overview

ECS Service Auto Scaling automatically adjusts the number of tasks based on application demand. This implementation uses:

- Target Tracking Scaling
- Step Scaling (for specific use cases)
- CloudWatch metrics and alarms
- Service-specific thresholds

## 🔧 Configuration Components

### Base Configuration

```json
{
  "TargetValue": 60.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleInCooldown": 60,
  "ScaleOutCooldown": 60
}
```

### Scaling Dimensions

| Parameter | Value | Description |
|-----------|-------|-------------|
| Minimum Tasks | 1 | Baseline service availability |
| Maximum Tasks | 5 | Resource/cost control limit |
| Target CPU | 60% | Optimal resource utilization |
| Scale-In Cooldown | 60s | Prevent rapid scale-in |
| Scale-Out Cooldown | 60s | Prevent rapid scale-out |

## 🛠️ Implementation

### 1. Register Scalable Target

```bash
# Register service for auto scaling
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/microservices-cluster/auth-service \
  --min-capacity 1 \
  --max-capacity 5
```

### 2. Create Scaling Policy

```bash
# Apply target tracking scaling policy
aws application-autoscaling put-scaling-policy \
  --policy-name cpu-target-tracking-scaling \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/microservices-cluster/auth-service \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://cloudwatch-alarms/fargate-scaling-policy.json
```

## 📊 Metrics and Thresholds

### Available Metrics

| Metric | Description | Default Threshold |
|--------|-------------|------------------|
| `ECSServiceAverageCPUUtilization` | Average CPU usage | 60% |
| `ECSServiceAverageMemoryUtilization` | Average memory usage | 80% |
| `ALBRequestCountPerTarget` | Request count per target | 1000 |

### Custom Metrics

```json
{
  "CustomizedMetricSpecification": {
    "MetricName": "ActiveConnections",
    "Namespace": "AWS/ApplicationELB",
    "Dimensions": [
      {
        "Name": "TargetGroup",
        "Value": "${TARGET_GROUP_ARN}"
      }
    ],
    "Statistic": "Average",
    "Unit": "Count"
  },
  "TargetValue": 100
}
```

## 🔍 Monitoring

### CloudWatch Alarms

```bash
# Create CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name auth-service-high-cpu \
  --alarm-description "High CPU utilization for auth-service" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --dimensions Name=ServiceName,Value=auth-service Name=ClusterName,Value=microservices-cluster \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 75 \
  --comparison-operator GreaterThanThreshold \
  --statistic Average
```

### Scaling Activity Logs

```bash
# View recent scaling activities
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id service/microservices-cluster/auth-service
```

## 🎯 Environment-Specific Settings

### Production

```json
{
  "TargetValue": 60.0,
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 60
}
```

### Staging

```json
{
  "TargetValue": 70.0,
  "ScaleInCooldown": 60,
  "ScaleOutCooldown": 60
}
```

### Test

```json
{
  "TargetValue": 80.0,
  "ScaleInCooldown": 60,
  "ScaleOutCooldown": 60
}
```

## 💡 Best Practices

### Scaling Policies

1. **Gradual Scaling**
   - Use appropriate cooldown periods
   - Implement step scaling for sensitive services
   - Monitor scaling history

2. **Resource Optimization**
   - Set appropriate min/max task limits
   - Use target tracking for stable services
   - Implement custom metrics when needed

3. **Cost Management**
   - Monitor scaling costs
   - Implement scheduled scaling for predictable loads
   - Set maximum limits based on budget

### Monitoring

1. **Metrics**
   - Monitor scaling events
   - Track resource utilization
   - Set up alerts for abnormal patterns

2. **Logging**
   - Enable detailed monitoring
   - Maintain scaling activity logs
   - Set up notification for scaling events

## 🔄 Maintenance

### Regular Tasks

1. **Review and Adjust**
   - Analyze scaling patterns
   - Adjust thresholds if needed
   - Update policies based on usage

2. **Optimization**
   - Fine-tune cooldown periods
   - Adjust target values
   - Review cost implications

3. **Documentation**
   - Update scaling configurations
   - Document policy changes
   - Maintain troubleshooting guides
