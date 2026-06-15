variable "aws_region" {
  description = "AWS region for bootstrap resources."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Short project name used for resource names."
  type        = string
  default     = "driveops"
}

variable "github_owner" {
  description = "GitHub owner that contains the orchestration repository."
  type        = string
  default     = "pchurchil1"
}

variable "github_repo" {
  description = "GitHub orchestration repository name."
  type        = string
  default     = "DriveOps"
}

variable "state_bucket_name" {
  description = "Optional exact S3 bucket name for Terraform state. Defaults to a deterministic account/region name."
  type        = string
  default     = null
}

variable "state_lock_table_name" {
  description = "Optional exact DynamoDB table name for Terraform state locking."
  type        = string
  default     = null
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for token.actions.githubusercontent.com."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "tags" {
  description = "Additional tags for bootstrap resources."
  type        = map(string)
  default     = {}
}
