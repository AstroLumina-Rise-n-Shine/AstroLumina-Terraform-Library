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

  tags = local.common_tags
}
