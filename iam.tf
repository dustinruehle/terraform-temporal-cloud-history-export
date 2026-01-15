# IAM Role that Temporal Cloud will assume
resource "aws_iam_role" "temporal_export" {
  name = "temporal-export-${var.namespace_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.temporal_role_arns
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "sts:ExternalId" = var.temporal_external_id
        }
      }
    }]
  })

  tags = {
    Purpose = "Temporal workflow history exports"
  }
}

# Policy granting S3 write access
resource "aws_iam_role_policy" "temporal_export" {
  name = "temporal-export-s3-write"
  role = aws_iam_role.temporal_export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketLocation"
      ]
      Resource = [
        aws_s3_bucket.temporal_export.arn,
        "${aws_s3_bucket.temporal_export.arn}/*"
      ]
    }]
  })
}