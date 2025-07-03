# 🔐 Security.md – AWS ECS Fargate Microservices

This document outlines the security measures and best practices applied to the semi-automated microservices architecture deployed on AWS ECS using Fargate. It ensures controlled access, secrets management, and traffic isolation without the use of third-party DevOps automation tools.

---

## 🔐 Authentication & Authorization

* All admin/API access to the environment is gated via AWS IAM permissions.
* Access to AWS CLI and ECS-related actions are restricted via IAM roles and policies.
* Services are launched with execution roles allowing only scoped resource access.

---

## 🔑 Secrets Management

* Application secrets (e.g., database URIs, API keys) are stored in **AWS Secrets Manager**.
* Secrets are injected into ECS containers via `secrets` parameter in task definition.
* Secret rotation is possible via AWS Secrets Manager lifecycle configurations.

Example in task definition:

```json
"secrets": [
  {
    "name": "MONGODB_URI",
    "valueFrom": "arn:aws:secretsmanager:<region>:<account-id>:secret:prod-mongodb-xxxxx"
  }
]
```

---

## 🔐 Network & Access Control

### VPC Structure:

* All ECS tasks run inside a **private subnet**.
* Only **ALB** is exposed to the internet via a **public subnet**.
* NAT Gateway enables tasks to access the internet securely (e.g., for software updates).

### Security Groups:

| Component  | Ingress                            | Egress                         |
| ---------- | ---------------------------------- | ------------------------------ |
| ALB        | 80/443 from internet               | 3000–4000 to ECS tasks         |
| ECS Tasks  | 3000–4000 from ALB only (SG-to-SG) | All (via NAT or VPC endpoints) |
| MongoDB/DB | 27017 from ECS SG only             | None                           |

---

## 🛡️ Load Balancer Protection

* ALB only exposes specific routes (e.g., /test/auth, /auth, /stage/reminder) using **path-based routing**.
* Optional: Enable AWS WAF on ALB for DDoS & OWASP rule protection.

---

## 🔐 Deployment Security

* Container images are built locally and pushed manually to **Amazon ECR**.
* ECR access is scoped to authenticated developers only.
* Task definition versions ensure rollback capability with reproducible infrastructure.
* Optional image signing and scanning can be enabled via **ECR Image Scan** and **KMS Signing**.

---

## 👥 User Roles & Access

* Developers: Push code & images, access test environment
* QA/PMs: Staging access via ALB route
* Admins: Production deployment and credential access via IAM
* No SSH access needed (containers are managed via ECS only)

---

## 🧪 Logging & Monitoring

* All application logs sent to **AWS CloudWatch Logs** via ECS task configuration.
* ALB access logs enabled for incoming requests.
* Optional: GuardDuty for anomaly detection, AWS Config for audit trails.

---

## 📝 Audit & Traceability

* Every deployment and scaling action is tracked via ECS, CloudTrail, and Activity Logs.
* IAM permissions are scoped to least privilege using AWS-managed policies.

---

> This layered security model ensures that microservices stay isolated, observable, and secure — even without advanced DevOps tools — by leveraging AWS-native controls and principles of least privilege.
