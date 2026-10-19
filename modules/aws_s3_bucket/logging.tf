# Server access logging (Trivy AWS-0089).
#
# Access logs go to a dedicated destination bucket. AWS explicitly says the
# destination bucket "should not have server access logging enabled" --
# logging the log bucket would make S3 log its own log deliveries and create
# an infinite loop. That single finding on the destination bucket is the one
# documented exception in .trivyignore.yaml; the source bucket below is
# always covered by aws_s3_bucket_logging.
#
# The destination must use SSE-S3 (AES256), not SSE-KMS: the S3 log delivery
# account has no access to a customer-managed KMS key, and AWS documents that
# SSE-KMS destinations can produce unreadable log objects.

locals {
  # A caller-supplied destination wins; otherwise create one. Keeping the
  # toggle separate from the destination lets cost-conscious callers point
  # several buckets at one shared log bucket.
  create_log_bucket = var.enable_access_logging && var.logging_target_bucket == null
  logging_target    = var.logging_target_bucket != null ? var.logging_target_bucket : (local.create_log_bucket ? aws_s3_bucket.logs[0].id : null)

  log_bucket_name = "${var.name}-logs"
}

resource "aws_s3_bucket" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket        = local.log_bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, { Name = local.log_bucket_name, Purpose = "server-access-logs" })
}

# Versioning keeps every generation of every log object, so a compromised
# principal cannot silently overwrite the access-log trail (Trivy AWS-0090).
resource "aws_s3_bucket_versioning" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Same private-by-default posture as the source bucket: no public ACLs, no
# public policy, no public objects.
resource "aws_s3_bucket_public_access_block" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSE-S3 on purpose (see the note at the top): log delivery cannot read
# objects encrypted with a CMK. AES256 still encrypts every log object at
# rest and satisfies Trivy's default-encryption check.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Grant the S3 logging service principal write access to this destination.
# New buckets use Object Ownership "BucketOwnerEnforced" (ACLs disabled), so
# a bucket policy is the supported mechanism. The aws:SourceArn condition
# pins delivery to this exact source bucket; bucket names are globally
# unique, so no account-id lookup (and no STS endpoint) is needed.
resource "aws_s3_bucket_policy" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "S3ServerAccessLogsPolicy"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.logs[0].arn}/*"
      Condition = {
        ArnLike = { "aws:SourceArn" = aws_s3_bucket.this.arn }
      }
    }]
  })
}

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = local.logging_target
  target_prefix = var.access_logs_prefix

  # Do not enable PutBucketLogging before the destination policy exists;
  # otherwise the first deliveries between the two API calls are rejected.
  depends_on = [aws_s3_bucket_policy.logs]
}
