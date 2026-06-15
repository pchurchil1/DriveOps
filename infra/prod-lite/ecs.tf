resource "aws_ecs_cluster" "main" {
  name = local.name_prefix
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = local.service_discovery_domain
  description = "Private service discovery for ${local.name_prefix}"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "telemetry_api" {
  name = "telemetry-api"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.main.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_cloudwatch_log_group" "app" {
  for_each = toset([
    "dashboard",
    "gateway",
    "redis",
    "telemetry-api",
    "telemetry-worker",
    "telemetry-migrate",
  ])

  name              = "/ecs/${local.name_prefix}/${each.key}"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "dashboard" {
  family                   = "${local.name_prefix}-dashboard"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "dashboard"
      image     = local.dashboard_image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app["dashboard"].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])
}

resource "aws_ecs_task_definition" "gateway" {
  family                   = "${local.name_prefix}-gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "redis:7-alpine"
      essential = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        },
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "redis-cli ping | grep PONG"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app["redis"].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "gateway"
      image     = local.gateway_image
      essential = true
      dependsOn = [
        {
          containerName = "redis"
          condition     = "HEALTHY"
        },
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        },
      ]
      environment = [
        { name = "APP_NAME", value = "api-gateway-rate-limiter" },
        { name = "ENVIRONMENT", value = "prod" },
        { name = "REDIS_URL", value = "redis://localhost:6379/0" },
        { name = "UPSTREAM_BASE_URL", value = local.telemetry_api_internal_url },
        { name = "RATE_LIMIT_CAPACITY", value = tostring(var.rate_limit_capacity) },
        { name = "RATE_LIMIT_WINDOW_SECONDS", value = tostring(var.rate_limit_window_seconds) },
        { name = "UPSTREAM_TIMEOUT_SECONDS", value = tostring(var.upstream_timeout_seconds) },
        { name = "CORS_ORIGINS", value = jsonencode([local.app_url]) },
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8080/ready', timeout=2)\""]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 20
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app["gateway"].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])
}

resource "aws_ecs_task_definition" "telemetry_api" {
  family                   = "${local.name_prefix}-telemetry-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name        = "telemetry-api"
      image       = local.telemetry_api_image
      essential   = true
      environment = local.telemetry_environment
      secrets     = local.telemetry_secrets
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        },
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health', timeout=2)\""]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app["telemetry-api"].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url,
    aws_secretsmanager_secret_version.demo_password,
    aws_secretsmanager_secret_version.demo_username,
    aws_secretsmanager_secret_version.jwt_secret_key,
  ]
}

resource "aws_ecs_task_definition" "telemetry_worker" {
  family                   = "${local.name_prefix}-telemetry-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name        = "telemetry-worker"
      image       = local.telemetry_api_image
      essential   = true
      command     = ["python", "-m", "app.worker"]
      environment = local.telemetry_environment
      secrets     = local.telemetry_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app["telemetry-worker"].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url,
    aws_secretsmanager_secret_version.demo_password,
    aws_secretsmanager_secret_version.demo_username,
    aws_secretsmanager_secret_version.jwt_secret_key,
  ]
}

resource "aws_ecs_task_definition" "telemetry_migrate" {
  family                   = "${local.name_prefix}-telemetry-migrate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name        = "telemetry-migrate"
      image       = local.telemetry_api_image
      essential   = true
      command     = ["sh", "-c", "alembic upgrade head && python -m app.seed"]
      environment = local.telemetry_environment
      secrets     = local.telemetry_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app["telemetry-migrate"].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url,
    aws_secretsmanager_secret_version.demo_password,
    aws_secretsmanager_secret_version.demo_username,
    aws_secretsmanager_secret_version.jwt_secret_key,
  ]
}

resource "aws_ecs_service" "dashboard" {
  name            = "${local.name_prefix}-dashboard"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.dashboard.arn
  desired_count   = var.dashboard_desired_count
  launch_type     = "FARGATE"

  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.public[*].id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dashboard.arn
    container_name   = "dashboard"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "gateway" {
  name            = "${local.name_prefix}-gateway"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = var.gateway_desired_count
  launch_type     = "FARGATE"

  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.public[*].id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway.arn
    container_name   = "gateway"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.gateway]
}

resource "aws_ecs_service" "telemetry_api" {
  name            = "${local.name_prefix}-telemetry-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.telemetry_api.arn
  desired_count   = var.telemetry_api_desired_count
  launch_type     = "FARGATE"

  enable_execute_command             = var.enable_execute_command
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.public[*].id
  }

  service_registries {
    registry_arn = aws_service_discovery_service.telemetry_api.arn
  }
}

resource "aws_ecs_service" "telemetry_worker" {
  name            = "${local.name_prefix}-telemetry-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.telemetry_worker.arn
  desired_count   = var.telemetry_worker_desired_count
  launch_type     = "FARGATE"

  enable_execute_command             = var.enable_execute_command
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.public[*].id
  }
}
