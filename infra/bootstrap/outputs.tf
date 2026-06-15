output "state_bucket_name" {
  description = "S3 bucket for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_lock_table_name" {
  description = "DynamoDB table for Terraform remote state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC role ARN. Store this as GitHub variable AWS_ROLE_TO_ASSUME."
  value       = aws_iam_role.github_actions.arn
}

output "backend_config" {
  description = "Backend values for prod-lite terraform init."
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    key            = "driveops/prod-lite.tfstate"
    region         = var.aws_region
  }
}
