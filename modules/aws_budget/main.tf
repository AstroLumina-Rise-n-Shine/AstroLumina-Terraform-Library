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

# The SNS topic that receives budget notifications. AWS Budgets cannot send
# email directly; it publishes to SNS and every email endpoint subscribed
# here gets a confirmation message that must be clicked once before alerts
# flow. Without at least one confirmed subscriber the topic silently
# collects alerts nobody reads.
resource "aws_sns_topic" "this" {
  name = var.name

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
resource "aws_budgets_budget" "this" {
  name         = var.name
  budget_type  = var.budget_type
  limit_amount = var.limit_amount
  limit_unit   = "USD"
  time_unit    = var.time_unit

  dynamic "notification" {
    for_each = var.notification_thresholds

    content {
      comparison_operator       = "GREATER_THAN"
      threshold                 = each.value
      threshold_type            = "PERCENTAGE"
      notification_type         = "ACTUAL"
      subscriber_sns_topic_arns = [aws_sns_topic.this.arn]
    }
  }
}
