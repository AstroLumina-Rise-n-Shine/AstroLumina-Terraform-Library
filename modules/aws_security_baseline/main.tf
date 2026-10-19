# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so baselines from different envs can never look identical.
locals {
  common_tags = merge(
    {
      Project   = "AstroLumina"
      ManagedBy = "terraform"
    },
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Bucket name for the CloudTrail trail: caller-provided, or derived from the
# module name. Coalescing it here keeps both CloudTrail and the bucket
# policy consistent without repeating the fallback twice. (Floci does not
# enforce global bucket-name uniqueness; real AWS does.)
locals {
  cloudtrail_bucket_name = var.cloudtrail_bucket_name != null ? var.cloudtrail_bucket_name : "${var.name}-cloudtrail"

  # Destination bucket for server access logs on the trail bucket. Kept
  # separate on purpose: AWS documents that the log destination itself must
  # not have access logging (that would log log deliveries forever).
  cloudtrail_access_logs_bucket_name = var.cloudtrail_access_logs_bucket_name != null ? var.cloudtrail_access_logs_bucket_name : "${local.cloudtrail_bucket_name}-access-logs"

  # CloudTrail can only stream to CloudWatch when the trail itself exists.
  cloudtrail_cloudwatch_logs_enabled = var.enable_cloudtrail && var.enable_cloudtrail_cloudwatch_logs
}

# Customer-managed KMS key for the account. It can envelope-encrypt the
# CloudTrail bucket contents and anything else we point at it. Rotation is
# on (nothing here should ever depend on a never-rotating key) and the
# deletion window is intentionally short (7 days) so lab cleanup does not
# leave a key lingering for a month; real accounts often pick 30.
resource "aws_kms_key" "this" {
  description             = "AstroLumina baseline key for ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

# Friendly name for that key, so policies and consoles can say
# alias/${var.name} instead of an opaque UUID.
resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

# The account id is derived from the key's own ARN (fifth field) so no data
# source is needed to build the root principal of the key policy.
locals {
  account_id = split(":", aws_kms_key.this.arn)[4]
}

# Explicit key policy: the account root keeps full control, and CloudTrail
# (only) may use the key to encrypt trail files -- pinned by SourceArn so a
# foreign-account trail cannot ride our key (confused-deputy guard).
resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountRootAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = ["kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
        Condition = {
          StringLike = { "aws:SourceArn" = "arn:aws:cloudtrail:*:*:trail/*" }
        }
      },
      {
        # CloudWatch Logs encrypts the trail's log group with this key. The
        # encryption-context condition pins access to the baseline's own log
        # group, so the statement cannot be reused for any other group.
        Sid       = "AllowCloudWatchLogsEncrypt"
        Effect    = "Allow"
        Principal = { Service = "logs.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*",
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:*:${local.account_id}:log-group:/aws/cloudtrail/${var.name}"
          }
        }
      }
    ]
  })
}

# GuardDuty: continuous threat-detection scanning CloudTrail and flow logs.
# One detector per account/region. Count-gated so lab runs can switch it
# off (it is billed per analysis) without restructuring the module.
resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  tags = local.common_tags
}

# Security Hub: the account aggregator for security findings (CIS standard,
# GuardDuty results, etc.). Enabling the account is idempotent; other
# features gather around it later.
resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

# ---- CloudTrail: account-level audit log --------------------------------
# Every block below is count-gated together, so the whole trail (bucket,
# versioning, public-access block, bucket policy, trail) appears and
# disappears as one unit -- exactly what enable_cloudtrail toggles.

# Dedicated S3 bucket the trail writes to. Trail logs are only trustworthy
# while nobody can overwrite them, hence the versioning + public-access
# block + tight bucket policy ordering below.
resource "aws_s3_bucket" "trail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket        = local.cloudtrail_bucket_name
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "trail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Belt and braces: even with a restrictive bucket policy, disallow public
# access at all four layers (this is a hard account-level guarantee).
resource "aws_s3_bucket_public_access_block" "trail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt trail files with the customer-managed key instead of the
# AWS-managed default (Trivy AWS-0132) -- same key the trail itself uses.
resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bucket policy that lets ONLY the CloudTrail service write into the
# ./AWSLogs/* prefix, and only on behalf of trails whose ARN matches the
# aws:SourceArn condition -- the confused-deputy guard that stops other
# accounts' trails from pushing into our bucket (or others from using our
# trail identity against someone else's bucket).
resource "aws_s3_bucket_policy" "trail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AWSCloudTrailPutObject"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.trail[0].arn}/AWSLogs/*"
      Condition = {
        StringEquals = {
          "aws:SourceArn" = "arn:aws:cloudtrail:*:*:trail/*"
        }
      }
    }]
  })
}

# The trail itself: multi-region so it captures the whole account's global
# and regional events, logging enabled from day one.
resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = var.name
  s3_bucket_name                = aws_s3_bucket.trail[0].id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true

  # Signed digest files make any tampering with the log archive detectable
  # (Trivy AWS-0016).
  enable_log_file_validation = true

  # Encrypt the trail with the baseline customer-managed key instead of an
  # AWS-managed one (Trivy AWS-0015).
  kms_key_id = aws_kms_key.this.arn

  # Stream events to CloudWatch Logs for real-time analysis (Trivy AWS-0162).
  # The destination group and the role CloudTrail assumes to write into it
  # live in cloudtrail_logging.tf; both are gated by the same toggle.
  cloud_watch_logs_group_arn = local.cloudtrail_cloudwatch_logs_enabled ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = local.cloudtrail_cloudwatch_logs_enabled ? aws_iam_role.cloudtrail[0].arn : null

  tags = local.common_tags

  # The role policy must exist before CloudTrail validates the destination.
  depends_on = [aws_iam_role_policy.cloudtrail]
}
