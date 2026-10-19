output "budget_name" {
  description = "Name of the created budget"
  value       = aws_budgets_budget.this.name
}

output "budget_id" {
  description = "AWS Budget identifier of the created budget"
  value       = aws_budgets_budget.this.id
}

output "sns_topic_arn" {
  description = "ARN of the notification SNS topic budgets publish alerts to"
  value       = aws_sns_topic.this.arn
}
