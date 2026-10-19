# aws_iam_user

Creates a single IAM user with optional managed/inline policy attachments
and an optional programmatic access key. Intended for learning and demo
setups where a named identity with its own credentials is the simplest way
to experiment with callers and permissions. Real-world best practice is
federation, SSO or roles instead of static user keys -- the access key
defaults to off for exactly that reason.

## Usage

```hcl
module "iam_user" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_iam_user?ref=main"

  name        = "lab-deploy-bot"
  environment = "lab"
  # ...the most important inputs...
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | — | IAM user name (globally unique within the account) |
| managed_policy_arns | list(string) | `[]` | ARNs of AWS-managed or customer-managed policies to attach to the user |
| inline_policies | map(string) | `{}` | Map of inline policy name => JSON policy document, embedded directly in the user |
| create_access_key | bool | false | Whether to create a programmatic access key (learning/demo only -- the secret is sensitive and must never be committed or logged) |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| user_name | Name of the created IAM user |
| user_arn | ARN of the created IAM user |
| access_key_id | AWS access key id (null when create_access_key is false) |
| secret_access_key | AWS secret access key -- SENSITIVE, store it in a secret manager or pass it onward within the apply (null when create_access_key is false) |
