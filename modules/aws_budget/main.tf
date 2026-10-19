# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so budgets from different envs can never look identical.
locals {
  common_tags = merge(
    {
      Project   = "AstroLumina"
      ManagedBy = "terraform"
    },
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Customer-managed key for the alert topic. Trivy (AWS-0136) does not
# accept the AWS-managed alias/aws/sns here: a CMK keeps rotation and
# access control in our hands instead of AWS's.
resource "aws_kms_key" "this" {
  description             = "Encrypts the ${var.name} SNS alert topic"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = local.common_tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}-sns"
  target_key_id = aws_kms_key.this.key_id
}

# The account id is derived from the key's own ARN (fifth field) so no
# data source is needed to build the root principal of the key policy.
locals {
  account_id = split(":", aws_kms_key.this.arn)[4]
}

# Key policy: the account root keeps full control, and the SNS service may
# encrypt/decrypt for this topic only (SourceArn-pinned confused-deputy
# guard). Budgets publishes through SNS, so it needs no direct grant.
resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountRootAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowSNSEncryptDecrypt"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceArn" = aws_sns_topic.this.arn }
        }
      }
    ]
  })
}

# The SNS topic that receives budget notifications. AWS Budgets cannot send
# email directly; it publishes to SNS and every email endpoint subscribed
# here gets a confirmation message that must be clicked once before alerts
# flow. Without at least one confirmed subscriber the topic silently
# collects alerts nobody reads.
resource "aws_sns_topic" "this" {
  name = var.name

  # Encrypt the alert topic with the module's own customer-managed key
  # instead of the AWS-managed default (Trivy AWS-0095/AWS-0136).
  kms_master_key_id = aws_kms_key.this.arn

  tags = local.common_tags
}

# One email subscription per address. for_each over a set keeps each address
# a separate stable resource: removing one email leaves the others untouched
# (count-based indices would force everyone to shift).
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.notification_emails)

  protocol  = "email"
  endpoint  = each.value
  topic_arn = aws_sns_topic.this.arn
}

# The budget itself: a COST/USAGE/etc. limit per time unit, with one
# notification per threshold (percentage of the limit). Each notification
# compares ACTUAL spend with GREATER_THAN and publishes to the SNS topic
# above, so hitting 50/80/100% (the defaults) rings the alarm before the
# bill does.
# Floci (and any provider configured with skip_requesting_account_id) never
# resolves the caller account, and the Budgets API rejects an empty
# AccountId: read the account explicitly so the module works everywhere.
data "aws_caller_identity" "current" {}

resource "aws_budgets_budget" "this" {
  account_id   = data.aws_caller_identity.current.account_id
  name         = var.name
  budget_type  = var.budget_type
  limit_amount = var.limit_amount
  limit_unit   = "USD"
  time_unit    = var.time_unit

  dynamic "notification" {
    for_each = var.notification_thresholds

    content {
      comparison_operator = "GREATER_THAN"
      # Inside a dynamic block the iterator is named after the block label
      # ("notification"); "each" is only for resource-level for_each.
      threshold                 = notification.value
      threshold_type            = "PERCENTAGE"
      notification_type         = "ACTUAL"
      subscriber_sns_topic_arns = [aws_sns_topic.this.arn]
    }
  }
}
