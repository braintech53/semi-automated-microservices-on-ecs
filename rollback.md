# 🔁 Rollback Strategy for ECS Microservice Infrastructure (Fargate)

This document outlines the recommended procedures for rolling back to a previous working version of a microservice running on Amazon ECS with the Fargate launch type. The strategy is designed to ensure minimal downtime and reliable rollback during production failures.

---

## 🧠 When to Roll Back

Rollback should be triggered under the following scenarios:

* High error rate or exceptions detected post-deployment
* Health checks failing repeatedly in ALB target group
* ECS tasks unable to start or remain running
* Performance degradation or latency spikes
* Critical business or system functionality failure

---

## ⚙️ Rollback Options

### Option 1: Revert to Previous Task Definition Revision

ECS keeps historical revisions of each task definition. Reverting simply means switching the ECS service back to the previous stable revision.

```bash
aws ecs update-service \
  --cluster my-cluster \
  --service auth-service \
  --task-definition auth-service:<previous_revision_number>
```

This approach is immediate and does not require re-building or re-pushing the Docker image.

### Option 2: Re-deploy Previously Tagged Image

If you maintain explicit version tagging in ECR (e.g., `v1.0.0`, `v1.0.1`), you can:

1. Update the task definition to point to the old image tag
2. Register a new task definition revision with this image
3. Update the ECS service to use that task definition

---

## 🚨 Best Practices

### ✅ Use Immutable Image Tagging

Avoid using `latest` for deployments in production. Use semantic versioning or Git commit hashes as Docker tags:

```bash
docker tag auth-service:latest <account>.dkr.ecr.<region>.amazonaws.com/auth-service:v1.0.2
```

### ✅ Retain Task Definition History

Don’t delete old task definition revisions. ECS supports up to 1000 revisions per family.

### ✅ Keep Previous Working Image in ECR

Never delete the last known good container image unless you have tested the newer build thoroughly.

---

## 🧪 Rollback Testing Checklist

Before deploying a rollback in production:

* [ ] Was the previous revision known to be stable?
* [ ] Does the task definition match the correct environment configs and secrets?
* [ ] Is the old Docker image still present in ECR?
* [ ] Have you verified the previous build locally or in staging?

---

## 📋 Sample Rollback Command

To rollback the Gmail service to revision 12:

```bash
aws ecs update-service \
  --cluster my-cluster \
  --service gmail-service \
  --task-definition gmail-service:12
```

---

## 📦 Optional: Automation Script

You may create a shell script for easier rollback per service:

```bash
#!/bin/bash
SERVICE=$1
REVISION=$2

aws ecs update-service \
  --cluster my-cluster \
  --service $SERVICE \
  --task-definition $SERVICE:$REVISION
```

Usage:

```bash
./rollback.sh auth-service 18
```

---

> Always monitor service health immediately after rollback using CloudWatch metrics, ECS service events, and ALB target group health status.
