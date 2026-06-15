resource "aws_db_subnet_group" "postgres" {
  name       = "${local.name_prefix}-postgres"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.name_prefix}-postgres"
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  engine_version         = var.postgres_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.postgres.result
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 1
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  storage_encrypted       = true
  apply_immediately       = true

  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}
