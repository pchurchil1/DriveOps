variable "aws_region" {
  description = "AWS region for the prod-lite stack."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Short project name used for AWS resource names."
  type        = string
  default     = "driveops"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod-lite"
}

variable "vpc_cidr" {
  description = "CIDR block for the Lite VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs. ECS tasks use public IPs in these subnets to avoid NAT gateway cost."
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]
}

variable "db_name" {
  description = "Telemetry database name."
  type        = string
  default     = "telemetry"
}

variable "db_username" {
  description = "Telemetry database user."
  type        = string
  default     = "app"
}

variable "db_instance_class" {
  description = "Low-cost RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GiB."
  type        = number
  default     = 20
}

variable "postgres_engine_version" {
  description = "Optional PostgreSQL engine version. Null lets AWS choose the default for the major engine."
  type        = string
  default     = null
}

variable "dashboard_image" {
  description = "Full dashboard image URI to deploy. The deploy workflow sets this to an ECR SHA tag."
  type        = string
  default     = null
  nullable    = true
}

variable "gateway_image" {
  description = "Full gateway image URI to deploy. The deploy workflow sets this to an ECR SHA tag."
  type        = string
  default     = null
  nullable    = true
}

variable "telemetry_api_image" {
  description = "Full telemetry API image URI to deploy. The deploy workflow sets this to an ECR SHA tag."
  type        = string
  default     = null
  nullable    = true
}

variable "dashboard_desired_count" {
  description = "Dashboard ECS desired task count."
  type        = number
  default     = 1
}

variable "gateway_desired_count" {
  description = "Gateway ECS desired task count. Keep this at 1 while Redis is a sidecar."
  type        = number
  default     = 1
}

variable "telemetry_api_desired_count" {
  description = "Telemetry API ECS desired task count."
  type        = number
  default     = 1
}

variable "telemetry_worker_desired_count" {
  description = "Telemetry worker ECS desired task count."
  type        = number
  default     = 1
}

variable "rate_limit_capacity" {
  description = "Gateway token bucket capacity."
  type        = number
  default     = 60
}

variable "rate_limit_window_seconds" {
  description = "Gateway token bucket window in seconds."
  type        = number
  default     = 60
}

variable "upstream_timeout_seconds" {
  description = "Gateway upstream request timeout in seconds."
  type        = number
  default     = 5
}

variable "demo_username" {
  description = "Demo admin username stored in Secrets Manager. Must match the API seed behavior."
  type        = string
  default     = "admin"
}

variable "demo_password" {
  description = "Demo admin password stored in Secrets Manager. Must match the API seed behavior."
  type        = string
  default     = "password123"
  sensitive   = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec on services for debugging."
  type        = bool
  default     = false
}

variable "secrets_recovery_window_in_days" {
  description = "Secrets Manager recovery window. Zero forces immediate deletion on destroy."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Additional tags for all prod-lite resources."
  type        = map(string)
  default     = {}
}
