# aws_s3_bucket

Creates a private S3 bucket with the safe baseline baked in: versioning,
server-side encryption at rest, and the four public-access-block flags all
forced on. Nothing here is ever reachable from the internet by accident —
if you need shared access, attach an IAM policy on the calling side and
explain it in a comment.

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
| name               | string      | -          | Bucket name. Must be globally unique on real AWS; on Floci any DNS-safe name works.                                                                                                                  |
| versioning_enabled | bool        | `true`     | Whether object versions are kept (Enabled) or paused (Suspended)                                                                                                                                     |
| sse_algorithm      | string      | `AES256`   | Server-side encryption algorithm (`AES256` or `aws:kms`)                                                                                                                                             |
| kms_key_arn        | string      | `null`     | KMS key ARN for server-side encryption -- only used when sse_algorithm is `aws:kms`                                                                                                                  |
| force_destroy      | bool        | `true`     | Learning-friendly: destroy the bucket even when it still holds objects                                                                                                                               |
| environment        | string      | -          | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags               | map(string) | `{}`       | Extra tags applied to every created object                                                                                                                                                           |

## Outputs

| Name                | Description                                                               |
|---------------------|---------------------------------------------------------------------------|
| bucket_id           | Name of the bucket (S3 emits the name as the resource ID)                  |
| bucket_arn          | ARN of the bucket -- useful for IAM policy references                      |
| bucket_domain_name  | Regional endpoint hostname of the bucket (bucket + s3 + region)            |
