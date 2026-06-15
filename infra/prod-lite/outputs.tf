output "app_url" {
  description = "Public AWS Lite application URL."
  value       = local.app_url
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = aws_lb.app.dns_name
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by service."
  value = {
    for name, repo in aws_ecr_repository.app : name => repo.repository_url
  }
}

output "service_names" {
  description = "ECS service names."
  value = {
    dashboard        = aws_ecs_service.dashboard.name
    gateway          = aws_ecs_service.gateway.name
    telemetry_api    = aws_ecs_service.telemetry_api.name
    telemetry_worker = aws_ecs_service.telemetry_worker.name
  }
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by ECS tasks."
  value       = aws_subnet.public[*].id
}

output "public_subnet_ids_csv" {
  description = "Public subnet IDs as a comma-separated string for AWS CLI run-task calls."
  value       = join(",", aws_subnet.public[*].id)
}

output "ecs_security_group_id" {
  description = "Security group ID used by ECS tasks."
  value       = aws_security_group.ecs.id
}

output "migration_task_definition_arn" {
  description = "Task definition ARN for one-off migration and seed runs."
  value       = aws_ecs_task_definition.telemetry_migrate.arn
}

output "demo_username_secret_arn" {
  description = "Secrets Manager ARN for the demo username."
  value       = aws_secretsmanager_secret.demo_username.arn
}

output "demo_password_secret_arn" {
  description = "Secrets Manager ARN for the demo password."
  value       = aws_secretsmanager_secret.demo_password.arn
}

output "telemetry_migrate_log_group" {
  description = "CloudWatch log group for migration/seed tasks."
  value       = aws_cloudwatch_log_group.app["telemetry-migrate"].name
}
