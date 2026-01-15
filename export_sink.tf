# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Temporal Cloud Export Sink
resource "temporalcloud_namespace_export_sink" "sandbox_export" {
  namespace = "${var.namespace_name}.${var.temporal_account_id}"
  sink_name = "s3-workflow-export"

  s3 = {
    aws_account_id = data.aws_caller_identity.current.account_id
    bucket_name    = aws_s3_bucket.temporal_export.id
    region         = var.aws_region
    role_name      = aws_iam_role.temporal_export.name
    kms_arn        = ""
  }

  depends_on = [
    aws_iam_role_policy.temporal_export
  ]
}