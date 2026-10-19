output "role_arn" {
  description = "ARN of the cross-account role -- hand this to the trusted account's caller together with the external id"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the cross-account role"
  value       = aws_iam_role.this.name
}
