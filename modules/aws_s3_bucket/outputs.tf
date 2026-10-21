output "bucket_id" {
  description = "Name of the bucket (S3 emits the name as the resource ID)"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the bucket -- useful for IAM policy references"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Regional endpoint hostname of the bucket (bucket + s3 + region)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "logging_target_bucket" {
  description = "Bucket receiving server access logs (null when access logging is disabled)"
  value       = var.enable_access_logging ? local.logging_target : null
}

output "logging_bucket_created" {
  description = "Whether the module created its own \"<name>-logs\" destination bucket (false when a target was supplied or logging is disabled)"
  value       = local.create_log_bucket
}
