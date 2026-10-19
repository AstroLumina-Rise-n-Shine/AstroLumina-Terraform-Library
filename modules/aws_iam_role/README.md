# aws_iam_role

Creates a single IAM role with a trust policy (who may assume it) and a set
of permissions (managed policy attachments plus inline policies). The trust
policy defaults to a service-principal one (e.g. EC2), which is the shape
most lab roles need; pass `assume_role_policy_json` for anything custom.
This keeps role plumbing to a few lines instead of hand-writing JSON for
every service that needs an execution or instance role.

## Usage

```hcl
module "iam_role" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_iam_role?ref=main"

  name        = "lab-s3-reader"
  environment = "lab"
  # ...the most important inputs...
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | — | IAM role name (globally unique within the account) |
| assume_role_service | string | "ec2.amazonaws.com" | AWS service that may assume the role when assume_role_policy_json is null (e.g. ec2.amazonaws.com) |
| assume_role_policy_json | string | null | Full custom trust policy JSON. Overrides assume_role_service when set -- use it for friends, accounts or wildcard principals the simple default cannot express |
| managed_policy_arns | list(string) | `[]` | ARNs of AWS-managed or customer-managed policies to attach to the role |
| inline_policies | map(string) | `{}` | Map of inline policy name => JSON policy document, embedded directly in the role |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| role_name | Name of the created IAM role (pass to services that reference roles by name) |
| role_arn | ARN of the created IAM role (pass as role_arn to Lambda, ECS, instance profiles, etc.) |
