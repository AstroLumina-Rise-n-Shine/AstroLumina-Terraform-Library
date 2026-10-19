# ---- CloudTrail logging: CloudWatch Logs + access-log destination ---------
# Everything here is gated by enable_cloudtrail (the trail must exist) and
# individually switchable for cost reasons.

# Realtime trail analysis (Trivy AWS-0162). The trail keeps writing its
# immutable archive to S3; CloudWatch is the queryable, alarmable mirror.
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = local.cloudtrail_cloudwatch_logs_enabled ? 1 : 0

  name              = "/aws/cloudtrail/${var.name}"
  retention_in_days = var.cloudtrail_log_retention_days
  kms_key_id        = aws_kms_key.this.arn

  tags = local.common_tags
}

# Role CloudTrail assumes to write into the log group. The trust policy is
# pinned to this account and to trail ARNs (confused-deputy guard), and the
# inline policy only permits writing to this one log group.
resource "aws_iam_role" "cloudtrail" {
  count = local.cloudtrail_cloudwatch_logs_enabled ? 1 : 0

  name = "${var.name}-cloudtrail-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:aws:cloudtrail:*:${local.account_id}:trail/*" }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = local.cloudtrail_cloudwatch_logs_enabled ? 1 : 0

  name = "${var.name}-cloudtrail-logs"
  role = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
    }]
  })
}

# ---- Server access logging for the trail bucket (Trivy AWS-0089) ----------
# Dedicated destination bucket. AWS explicitly says the destination bucket
# should not itself have access logging enabled, so this one bucket is the
# documented exception in .trivyignore.yaml. It stays private (four PAB
# flags), encrypted (SSE-S3, which log delivery can write; SSE-KMS cannot be
# read by the log delivery account), and force-destroyable for lab teardown.
resource "aws_s3_bucket" "trail_access_logs" {
  count = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? 1 : 0

  bucket        = local.cloudtrail_access_logs_bucket_name
  force_destroy = true

  tags = merge(local.common_tags, { Name = local.cloudtrail_access_logs_bucket_name, Purpose = "server-access-logs" })

  lifecycle {
    precondition {
      condition     = length(local.cloudtrail_access_logs_bucket_name) <= 63
      error_message = "The derived access-log bucket name \"${local.cloudtrail_access_logs_bucket_name}\" exceeds the 63-character S3 limit. Shorten var.name / var.cloudtrail_bucket_name, or pass a shorter cloudtrail_access_logs_bucket_name."
    }
  }
}

# Versioning preserves every log-object generation, so a compromised
# principal cannot silently overwrite the access-log trail (Trivy AWS-0090).
resource "aws_s3_bucket_versioning" "trail_access_logs" {
  count = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? 1 : 0

  bucket = aws_s3_bucket.trail_access_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "trail_access_logs" {
  count = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? 1 : 0

  bucket = aws_s3_bucket.trail_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail_access_logs" {
  count = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? 1 : 0

  bucket = aws_s3_bucket.trail_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy granting the S3 logging principal write access. New buckets
# use BucketOwnerEnforced (ACLs disabled), so a policy is required. Both the
# source bucket ARN and the source account are pinned.
resource "aws_s3_bucket_policy" "trail_access_logs" {
  count = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? 1 : 0

  bucket = aws_s3_bucket.trail_access_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "S3ServerAccessLogsPolicy"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.trail_access_logs[0].arn}/*"
      Condition = {
        ArnLike      = { "aws:SourceArn" = aws_s3_bucket.trail[0].arn }
        StringEquals = { "aws:SourceAccount" = local.account_id }
      }
    }]
  })
}

resource "aws_s3_bucket_logging" "trail" {
  count = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.trail[0].id
  target_bucket = aws_s3_bucket.trail_access_logs[0].id
  target_prefix = "trail-access/"

  depends_on = [aws_s3_bucket_policy.trail_access_logs]
}
