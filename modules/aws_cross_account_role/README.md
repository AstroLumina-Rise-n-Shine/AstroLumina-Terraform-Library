# aws_cross_account_role

Creates a role in this account whose trust policy points at another AWS
account: the classic cross-account AssumeRole pattern. Principals authorized
in the `trusted_account_id` account can assume this role and inherit exactly
the managed/inline policies attached here. An optional `external_id` adds
confused-deputy protection, and `max_session_duration` caps how long a
single assumed session may live.

## Usage

```hcl
module "cross_account_role" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_cross_account_role?ref=main"

  name        = "lab-cross-account-deploy"
  environment = "lab"
  # ...the most important inputs...
  trusted_account_id = "111122223333"
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | — | IAM role name (globally unique within this account; the trusted account assumes this ARN) |
| trusted_account_id | string | — | 12-digit AWS account ID allowed to assume this role (its root principal trusts only its own explicitly-delegated users) |
| external_id | string | null | Optional sts:ExternalId condition -- confused-deputy protection; share it with the trusted account as a secret alongside the role ARN |
| managed_policy_arns | list(string) | `[]` | ARNs of AWS-managed or customer-managed policies the trusted account inherits when assuming this role |
| inline_policies | map(string) | `{}` | Map of inline policy name => JSON policy document, embedded directly in the role |
| max_session_duration | number | 3600 | Maximum sts:AssumeRole session length in seconds (3600 default; console allows up to 12h) |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the cross-account role -- hand this to the trusted account's caller together with the external id |
| role_name | Name of the cross-account role |
