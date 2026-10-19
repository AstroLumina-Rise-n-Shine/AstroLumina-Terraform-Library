output "function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function -- useful for IAM policies and event sources"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "ARN to invoke the function with (for aws_lambda_invocation or API Gateway integration)"
  value       = aws_lambda_function.this.invoke_arn
}
