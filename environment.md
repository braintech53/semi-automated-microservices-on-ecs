# 🌐 Environment Configuration – ECS Microservice Infrastructure (Fargate)

This document outlines the environment strategy used to manage microservices across multiple deployment stages: `test`, `staging`, and `production`. Each environment operates in isolation using dedicated ECS Services and unique ALB route paths to prevent conflicts and enable safe testing.

---

## 🧪 Test Environment

### Purpose:

* Used by developers to validate features before staging
* Runs minimal instance configurations to save cost

### Characteristics:

* Service name suffix: `test-<service-name>`
* Task definition prefix: `test-<service-name>`
* ALB path: `/test/<service-name>`
* Container environment variable: `ENV=test`
* Lower memory & CPU allocation (e.g., 256 CPU, 512MB RAM)
* No scaling policies

### Example:

```json
Service Name: test-gmail-service
Task Definition: test-gmail-service
Path: /test/gmail
```

---

## 🔬 Staging Environment

### Purpose:

* Replica of production environment
* Used for pre-release testing, QA, and stakeholder demos

### Characteristics:

* Service name suffix: `stage-<service-name>`
* Task definition prefix: `stage-<service-name>`
* ALB path: `/stage/<service-name>`
* Container environment variable: `ENV=staging`
* Same configuration as production (CPU, memory, secrets)
* Can support auto-scaling like production

### Example:

```json
Service Name: stage-reminder-service
Task Definition: stage-reminder-service
Path: /stage/reminder
```

---

## 🚀 Production Environment

### Purpose:

* Live application serving real users

### Characteristics:

* Service name: `<service-name>` (no prefix)
* Task definition: `<service-name>`
* ALB path: `/<service-name>`
* Container environment variable: `ENV=production`
* Full scaling policies enabled (based on CPU/memory)
* Health check alarms & monitoring enabled
* Full AWS Secrets Manager integration for credentials

### Example:

```json
Service Name: telegram-service
Task Definition: telegram-service
Path: /telegram
```

---

## ✅ Environment Isolation Summary

| Environment | Suffix/Prefix | ALB Path         | Scaling  | Resources |
| ----------- | ------------- | ---------------- | -------- | --------- |
| Test        | test-         | /test/<service>  | No       | Minimal   |
| Staging     | stage-        | /stage/<service> | Optional | Full      |
| Production  | none          | /<service>       | Yes      | Full      |

---

## 📌 Best Practices

* Use distinct task definitions for each environment to avoid accidental overrides
* Use ENV variable to configure services dynamically
* Apply IAM roles per environment (optional)
* Ensure logging and monitoring is enabled in all environments

---

> This structured environment separation ensures safe, controlled rollouts with high fidelity between staging and production, while keeping costs low in test environments.
