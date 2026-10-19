output "role_name" {
  description = "Name of the created IAM role (pass to services that reference roles by name)"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the created IAM role (pass as role_arn to Lambda, ECS, instance profiles, etc.)"
  value       = aws_iam_role.this.arn
}
