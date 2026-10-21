# aws_s3_bucket

Creates a private S3 bucket with the safe baseline baked in: versioning,
server-side encryption at rest, server access logging, and the four
public-access-block flags all forced on. Nothing here is ever reachable from
the internet by accident — if you need shared access, attach an IAM policy
on the calling side and explain it in a comment.

Access logging is on by default and writes to a dedicated `<name>-logs`
bucket (versioned, SSE-S3, private, with a bucket policy that only lets the
S3 logging service principal write on behalf of this exact source bucket and
account). Point several buckets at one shared destination with
`logging_target_bucket`, or turn logging off with
`enable_access_logging = false`. The destination bucket itself is
deliberately not logged: AWS documents that logging a log destination
recurses forever (see `.trivyignore.yaml` at the repo root).

S3 caps bucket names at 63 characters. Because the module derives the
destination as `<name>-logs`, `name` must be 58 characters or fewer when the
module creates that destination; the module fails at plan time with a clear
message otherwise. Supplying `logging_target_bucket` removes the derived-name
limit (the target still has to be a valid S3 bucket name).

## Usage

```hcl
module "artifacts" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_s3_bucket?ref=main"

  name        = "lab-astrolumina-artifacts"
  environment = "lab"

  versioning_enabled = true
  force_destroy      = true
}
```

## Inputs

| Name               | Type        | Default    | Description                                                                                                                                                                                         |
|--------------------|-------------|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name               | string      | -          | Bucket name. Must be globally unique on real AWS; on Floci any DNS-safe name works. 63 characters max; 58 max when the module creates the `<name>-logs` destination.                                 |
| versioning_enabled | bool        | `true`     | Whether object versions are kept (Enabled) or paused (Suspended)                                                                                                                                     |
| sse_algorithm      | string      | `AES256`   | Server-side encryption algorithm (`AES256` or `aws:kms`)                                                                                                                                             |
| kms_key_arn        | string      | `null`     | KMS key ARN for server-side encryption -- only used when sse_algorithm is `aws:kms`                                                                                                                  |
| enable_access_logging | bool      | `true`     | Enable S3 server access logging (Trivy AWS-0089)                                                                                                                                                     |
| logging_target_bucket | string    | `null`     | Existing bucket for access logs. When null, the module creates `<name>-logs` and grants `logging.s3.amazonaws.com` write access to it. A caller-supplied bucket must already allow that principal |
| access_logs_prefix | string      | `access-logs/` | Key prefix for log objects (must not start with a slash)                                                                                                                                          |
| force_destroy      | bool        | `true`     | Learning-friendly: destroy the bucket even when it still holds objects                                                                                                                               |
| environment        | string      | -          | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags               | map(string) | `{}`       | Extra tags applied to every created object                                                                                                                                                           |

## Outputs

| Name                | Description                                                               |
|---------------------|---------------------------------------------------------------------------|
| bucket_id           | Name of the bucket (S3 emits the name as the resource ID)                  |
| bucket_arn          | ARN of the bucket -- useful for IAM policy references                      |
| bucket_domain_name  | Regional endpoint hostname of the bucket (bucket + s3 + region)            |
| logging_target_bucket | Bucket receiving access logs (null when logging is disabled)             |
| logging_bucket_created | Whether the module created its own `<name>-logs` destination bucket     |

## Floci note

The access-logging path needs the S3 endpoint for the buckets themselves
plus `sts` for the caller-identity lookup used in the destination bucket
policy: `s3 = "http://localhost:4566"` and
`sts = "http://localhost:4566"`. With `enable_access_logging = false` (or a
caller-supplied `logging_target_bucket`) no STS call is made.
