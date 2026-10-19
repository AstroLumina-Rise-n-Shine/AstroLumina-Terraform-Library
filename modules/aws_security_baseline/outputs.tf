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
