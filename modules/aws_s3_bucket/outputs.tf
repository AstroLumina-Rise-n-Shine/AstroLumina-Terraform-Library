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
