# aws_budget

Creates an AWS Budget with percentage thresholds and an SNS notification
path: the budget publishes to a topic, and the caller's email addresses are
subscribed to it. Use it as the cheap safety net under every environment so
runaway spend (or usage) is caught at 50/80/100% of the limit instead of at
the end-of-month bill.

## Usage

```hcl
module "budget" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_budget?ref=main"

  name        = "lab-monthly-cost"
  environment = "lab"
  # ...the most important inputs...
  notification_emails = ["you@example.com"]
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | — | Budget name (also the notification SNS topic name) |
| limit_amount | string | "100" | Budget limit -- a decimal string because the API treats the amount as text (e.g. "100") |
| time_unit | string | "MONTHLY" | Period the budget covers before it resets |
| budget_type | string | "COST" | What the budget tracks -- also selects the semantic family of the limit |
| notification_thresholds | list(number) | [50, 80, 100] | Alert trigger points, expressed as percentages of limit_amount (e.g. [50, 80, 100]) |
| notification_emails | list(string) | `[]` | Email addresses subscribed to the notification topic (each receives an SNS confirmation to click once) |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| budget_name | Name of the created budget |
| budget_id | AWS Budget identifier of the created budget |
| sns_topic_arn | ARN of the notification SNS topic budgets publish alerts to |
