# Minimal S3 bucket on the Floci AWS emulator.
#
# Proves the Terraform <-> Floci wiring from docs/03-terraform-floci.md:
# run `floci start`, export the connection variables, then init/apply.
# The bucket lives inside the emulator only (see `floci snapshot` to
# persist emulator state across restarts).

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Every endpoint points at the local emulator instead of real AWS.
# Credentials are dummy values: Floci accepts anything, but the AWS
# provider still requires the validation skips below, otherwise init
# fails trying to reach the real STS/metadata endpoints.
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "astrolumina-terraform-test"
}

# Block every form of public access: without this resource the bucket keeps
# the AWS defaults (public ACLs/policies allowed), which Trivy flags as
# HIGH (AWS-0086/0087/0091/0093). Learning buckets should never be public.
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "bucket" {
  description = "Envelope-encryption key for the learning bucket"

  # Same rotation rationale as the EKS example key (Trivy AWS-0065).
  enable_key_rotation = true
}

# Customer-managed encryption at rest instead of the AWS-managed default
# (Trivy AWS-0132 wants a CMK, not SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bucket.arn
    }
  }
}

# Keep every version of every object so overwrites and deletes are
# recoverable (Trivy AWS-0090).
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-access logging for the example bucket (Trivy AWS-0089). The log
# delivery bucket below is hardened the same way (rotation-shared key,
# versioning, public block); its own access logging is intentionally off --
# logging the log bucket into itself would loop, so the ignore annotation
# below terminates the chain by design, not by laziness.
#trivy:ignore:AVD-AWS-0089
resource "aws_s3_bucket" "logs" {
  bucket = "astrolumina-terraform-test-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bucket.arn
    }
  }
}

resource "aws_s3_bucket_logging" "example" {
  bucket        = aws_s3_bucket.example.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}

output "bucket_name" {
  description = "Name of the bucket created in the emulator"
  value       = aws_s3_bucket.example.bucket
}
