# aws_security_baseline

Creates the account-level security baseline: a rotating KMS key with a
friendly alias, a GuardDuty detector, Security Hub enablement, and a full
CloudTrail write path (dedicated S3 bucket with versioning, a public-access
block, a tight CloudTrail-only bucket policy, and a multi-region trail).
Every component can be toggled off individually, so lab runs can strip the
baseline down to just the pieces they need.

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
| cloudtrail_bucket_name | string | null | S3 bucket name for trail logs. When null, defaults to "<name>-cloudtrail" (Floci does not enforce global uniqueness; real AWS does) |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_arn | ARN of the customer-managed KMS key (point other resources' encryption at it) |
| kms_alias_name | Friendly alias name referring to the baseline KMS key (alias/${var.name}) |
| guardduty_detector_id | ID of the GuardDuty detector (null when enable_guardduty is false) |
| cloudtrail_arn | ARN of the CloudTrail trail (null when enable_cloudtrail is false) |
