# AWS Lite prod-lite

This Terraform stack deploys DriveOps to AWS with the low-cost Lite shape:

- ECS Fargate for dashboard, gateway, telemetry API, and worker
- Redis sidecar inside the gateway task
- ECR image repositories
- Public HTTP ALB
- Single-AZ private RDS Postgres
- Secrets Manager
- CloudWatch logs
- Cloud Map private DNS for gateway-to-API traffic

## Bootstrap

Run the bootstrap stack once from an AWS-authenticated shell:

```bash
terraform -chdir=../bootstrap init
terraform -chdir=../bootstrap apply
```

Then add these GitHub repository variables in `pchurchil1/DriveOps`:

```text
AWS_ROLE_TO_ASSUME=<github_actions_role_arn output>
TF_STATE_BUCKET=<state_bucket_name output>
TF_STATE_LOCK_TABLE=<state_lock_table_name output>
AWS_REGION=us-east-2
```

## Local Validation

```bash
terraform -chdir=infra/prod-lite init -backend=false
terraform -chdir=infra/prod-lite validate
```

## Deploy

The GitHub Actions deploy workflow creates ECR repositories first, pushes SHA-tagged images, applies this stack with those image URIs, runs the migration/seed ECS task, and smoke-tests the ALB URL.
