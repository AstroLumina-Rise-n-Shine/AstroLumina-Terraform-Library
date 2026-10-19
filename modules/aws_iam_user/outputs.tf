output "user_name" {
  description = "Name of the created IAM user"
  value       = aws_iam_user.this.name
}

output "user_arn" {
  description = "ARN of the created IAM user"
  value       = aws_iam_user.this.arn
}

output "access_key_id" {
  description = "AWS access key id (null when create_access_key is false)"
  value       = var.create_access_key ? aws_iam_access_key.this[0].id : null
}

output "secret_access_key" {
  description = "AWS secret access key -- SENSITIVE, store it in a secret manager or pass it onward within the apply (null when create_access_key is false)"
  value       = var.create_access_key ? aws_iam_access_key.this[0].secret : null
  sensitive   = true
}
