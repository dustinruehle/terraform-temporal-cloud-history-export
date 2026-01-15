output "s3_bucket_name" {
  description = "S3 bucket receiving workflow exports"
  value       = aws_s3_bucket.temporal_export.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.temporal_export.arn
}

output "iam_role_arn" {
  description = "IAM role ARN for Temporal export"
  value       = aws_iam_role.temporal_export.arn
}

output "export_sink_name" {
  description = "Temporal export sink name"
  value       = temporalcloud_namespace_export_sink.sandbox_export.sink_name
}