data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  state_bucket_name     = coalesce(var.state_bucket_name, "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-tfstate")
  state_lock_table_name = coalesce(var.state_lock_table_name, "${var.project_name}-terraform-locks")

  github_subjects = [
    "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main",
    "repo:${var.github_owner}/${var.github_repo}:pull_request",
    "repo:${var.github_owner}/${var.github_repo}:environment:production",
  ]

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Repository  = "${var.github_owner}/${var.github_repo}"
    },
    var.tags,
  )
}
