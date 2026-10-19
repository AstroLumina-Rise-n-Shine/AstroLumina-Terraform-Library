output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key (point other resources' encryption at it)"
  value       = aws_kms_key.this.arn
}

output "kms_alias_name" {
  description = "Friendly alias name referring to the baseline KMS key (alias/<name>)"
  value       = aws_kms_alias.this.name
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector (null when enable_guardduty is false)"
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail (null when enable_cloudtrail is false)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.this[0].arn : null
}

output "cloudtrail_log_group_arn" {
  description = "ARN of the CloudWatch Logs group receiving trail events (null when CloudTrail or CloudWatch logging is disabled)"
  value       = local.cloudtrail_cloudwatch_logs_enabled ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudWatch Logs group receiving trail events (null when CloudTrail or CloudWatch logging is disabled)"
  value       = local.cloudtrail_cloudwatch_logs_enabled ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "cloudtrail_logging_role_arn" {
  description = "ARN of the IAM role CloudTrail assumes to write to CloudWatch Logs (null when disabled)"
  value       = local.cloudtrail_cloudwatch_logs_enabled ? aws_iam_role.cloudtrail[0].arn : null
}

output "cloudtrail_access_logs_bucket" {
  description = "Bucket receiving server access logs for the trail bucket (null when access logging is disabled)"
  value       = var.enable_cloudtrail && var.enable_cloudtrail_access_logging ? aws_s3_bucket.trail_access_logs[0].id : null
}
