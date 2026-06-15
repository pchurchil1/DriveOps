locals {
  name_prefix = "${var.project_name}-${var.environment}"

  dashboard_image     = coalesce(var.dashboard_image, "${aws_ecr_repository.app["dashboard"].repository_url}:bootstrap")
  gateway_image       = coalesce(var.gateway_image, "${aws_ecr_repository.app["gateway"].repository_url}:bootstrap")
  telemetry_api_image = coalesce(var.telemetry_api_image, "${aws_ecr_repository.app["telemetry-api"].repository_url}:bootstrap")

  app_url                    = "http://${aws_lb.app.dns_name}"
  service_discovery_domain   = "${local.name_prefix}.local"
  telemetry_api_internal_url = "http://telemetry-api.${local.service_discovery_domain}:8000"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  ecr_repositories = toset([
    "dashboard",
    "gateway",
    "telemetry-api",
  ])

  telemetry_environment = [
    { name = "APP_NAME", value = "vehicle-telemetry-api" },
    { name = "ENVIRONMENT", value = "prod" },
    { name = "LOG_LEVEL", value = "INFO" },
    { name = "API_V1_PREFIX", value = "/api/v1" },
    { name = "AUTH_ENABLED", value = "true" },
    { name = "JWT_EXPIRES_MINUTES", value = "60" },
    { name = "CORS_ORIGINS", value = jsonencode([local.app_url]) },
  ]

  telemetry_secrets = [
    { name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.database_url.arn },
    { name = "JWT_SECRET_KEY", valueFrom = aws_secretsmanager_secret.jwt_secret_key.arn },
    { name = "DEMO_USERNAME", valueFrom = aws_secretsmanager_secret.demo_username.arn },
    { name = "DEMO_PASSWORD", valueFrom = aws_secretsmanager_secret.demo_password.arn },
  ]
}
