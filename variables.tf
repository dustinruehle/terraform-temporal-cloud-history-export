variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "temporal_api_key" {
  description = "Temporal Cloud API key"
  type        = string
  sensitive   = true
}

variable "temporal_account_id" {
  description = "Your Temporal Cloud account ID slug (e.g., sdvdw)"
  type        = string
}

variable "temporal_external_id" {
  description = "External ID (UUID) for IAM trust policy from Temporal Cloud"
  type        = string
}

variable "namespace_name" {
  description = "Temporal namespace name"
  type        = string
  default     = "sandbox"
}

variable "bucket_name" {
  description = "S3 bucket name for exports"
  type        = string
}

variable "temporal_role_arns" {
  description = "Temporal Cloud IAM role ARNs allowed to assume the export role"
  type        = list(string)
  default = [
    "arn:aws:iam::902542641901:role/closed-workflow-export",
    "arn:aws:iam::160190466495:role/closed-workflow-export",
    "arn:aws:iam::819232936619:role/closed-workflow-export",
    "arn:aws:iam::829909441867:role/closed-workflow-export",
    "arn:aws:iam::354116250941:role/closed-workflow-export"
  ]
}