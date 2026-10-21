# aws_security_baseline

Creates the account-level security baseline: a rotating KMS key with a
friendly alias, a GuardDuty detector, Security Hub enablement, and a full
CloudTrail write path (dedicated S3 bucket with versioning, a public-access
block, a tight CloudTrail-only bucket policy, and a multi-region trail).
The trail also streams events to a CloudWatch Logs group through a scoped
IAM role (Trivy AWS-0162), and the trail bucket gets server access logging
into a separate, hardened destination bucket (Trivy AWS-0089). Every
component can be toggled off individually, so lab runs can strip the
baseline down to just the pieces they need.

The access-log destination is deliberately not logged itself: AWS documents
that a log destination with server access logging enabled recurses forever.
That one exception is recorded with a path-scoped entry in
`.trivyignore.yaml` at the repo root.

S3 caps bucket names at 63 characters, and the destination is derived as
`<cloudtrail bucket>-access-logs` (12 characters). Keep the trail bucket name
to 51 characters or fewer so the derived name fits; with the default
`<name>-cloudtrail` bucket that means `name` must be 40 characters or fewer.
The module fails at plan time with a clear message otherwise.

## Usage

```hcl
module "security_baseline" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_security_baseline?ref=main"

  name        = "lab-baseline"
  environment = "lab"
  # ...the most important inputs...
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | — | Baseline name (prefixes the KMS alias and defaults the CloudTrail bucket name) |
| enable_guardduty | bool | true | Whether to create the GuardDuty threat-detection detector (off when billed analysis has no value in a sandbox) |
| enable_security_hub | bool | true | Whether to enable the Security Hub account |
| enable_cloudtrail | bool | true | Whether to create the full CloudTrail stack (S3 bucket + policy + trail) |
| enable_cloudtrail_cloudwatch_logs | bool | true | Stream trail events to CloudWatch Logs through a scoped IAM role (Trivy AWS-0162). Ingestion is billed on real AWS |
| cloudtrail_log_retention_days | number | 30 | Days trail events are kept in CloudWatch Logs (the S3 archive is unaffected) |
| enable_cloudtrail_access_logging | bool | true | Enable S3 server access logging on the trail bucket (Trivy AWS-0089) |
| cloudtrail_access_logs_bucket_name | string | null | Destination bucket for trail-bucket access logs, 63 characters max. When null, defaults to "<cloudtrail bucket>-access-logs" |
| cloudtrail_bucket_name | string | null | S3 bucket name for trail logs, 63 characters max; 51 max when access logging derives "<cloudtrail bucket>-access-logs". When null, defaults to "<name>-cloudtrail" (Floci does not enforce global uniqueness; real AWS does) |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_arn | ARN of the customer-managed KMS key (point other resources' encryption at it) |
| kms_alias_name | Friendly alias name referring to the baseline KMS key (alias/${var.name}) |
| guardduty_detector_id | ID of the GuardDuty detector (null when enable_guardduty is false) |
| cloudtrail_arn | ARN of the CloudTrail trail (null when enable_cloudtrail is false) |
| cloudtrail_log_group_arn | ARN of the CloudWatch Logs group receiving trail events (null when disabled) |
| cloudtrail_log_group_name | Name of the CloudWatch Logs group receiving trail events (null when disabled) |
| cloudtrail_logging_role_arn | ARN of the IAM role CloudTrail assumes to write to CloudWatch Logs (null when disabled) |
| cloudtrail_access_logs_bucket | Bucket receiving trail-bucket access logs (null when access logging is disabled) |

## Floci note

The CloudTrail→CloudWatch path needs `logs` and `iam` endpoints in addition
to the existing `cloudtrail`, `kms` and `s3` overrides. The baseline also
creates the IAM role used by the trail, so an `iam = "http://localhost:4566"`
entry is required even if the rest of the stack does not use IAM directly.
