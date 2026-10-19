output "table_name" {
  description = "Name of the created DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the table -- useful for IAM policy references"
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "ID of the table (table name, as DynamoDB reports it)"
  value       = aws_dynamodb_table.this.id
}
