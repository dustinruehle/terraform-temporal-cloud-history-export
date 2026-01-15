# S3 Bucket for workflow history exports
resource "aws_s3_bucket" "temporal_export" {
  bucket = var.bucket_name

  tags = {
    Purpose = "Temporal workflow history exports"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "temporal_export" {
  bucket = aws_s3_bucket.temporal_export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (recommended)
resource "aws_s3_bucket_versioning" "temporal_export" {
  bucket = aws_s3_bucket.temporal_export.id

  versioning_configuration {
    status = "Enabled"
  }
}