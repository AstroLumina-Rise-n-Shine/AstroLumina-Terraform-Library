# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so buckets from different envs can never look identical.
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

# The bucket itself. force_destroy defaults to true because this is a
# learning library: `terraform destroy` should never get stuck on a bucket
# still holding leftovers. Flip it to false for anything you would feel
# bad about deleting too easily.
resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, { Name = var.name })
}

# Versioning keeps old copies of overwritten/deleted objects. When disabled
# we explicitly set "Suspended" rather than omitting the resource: S3 only
# lets you turn versioning OFF again if some resource owns that state.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Server-side encryption at rest. AES256 (S3-managed keys) is the simple
# default; pick "aws:kms" with a kms_key_arn when you need audit trails on
# key usage. The KMS key is passed only when it is actually relevant --
# sending one alongside AES256 is refused by the API.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_arn : null
    }
  }
}

# Slam every public-access door shut: new ACLs, new policies, and any
# future public policy are all refused. This block exists precisely
# because buckets historically leaked by misconfiguration, not by intent.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
