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

output "bucket_name" {
  description = "Name of the bucket created in the emulator"
  value       = aws_s3_bucket.example.bucket
}
