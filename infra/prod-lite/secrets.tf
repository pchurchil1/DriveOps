resource "random_password" "postgres" {
  length  = 32
  special = false
}

resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "postgres_password" {
  name                    = "${local.name_prefix}/postgres-password"
  recovery_window_in_days = var.secrets_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id     = aws_secretsmanager_secret.postgres_password.id
  secret_string = random_password.postgres.result
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${local.name_prefix}/database-url"
  recovery_window_in_days = var.secrets_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql+psycopg2://${var.db_username}:${random_password.postgres.result}@${aws_db_instance.postgres.address}:5432/${var.db_name}"
}

resource "aws_secretsmanager_secret" "jwt_secret_key" {
  name                    = "${local.name_prefix}/jwt-secret-key"
  recovery_window_in_days = var.secrets_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "jwt_secret_key" {
  secret_id     = aws_secretsmanager_secret.jwt_secret_key.id
  secret_string = random_password.jwt.result
}

resource "aws_secretsmanager_secret" "demo_username" {
  name                    = "${local.name_prefix}/demo-username"
  recovery_window_in_days = var.secrets_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "demo_username" {
  secret_id     = aws_secretsmanager_secret.demo_username.id
  secret_string = var.demo_username
}

resource "aws_secretsmanager_secret" "demo_password" {
  name                    = "${local.name_prefix}/demo-password"
  recovery_window_in_days = var.secrets_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "demo_password" {
  secret_id     = aws_secretsmanager_secret.demo_password.id
  secret_string = var.demo_password
}
