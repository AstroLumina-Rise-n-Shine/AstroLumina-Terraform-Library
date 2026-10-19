output "db_instance_id" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_address" {
  description = "Connection hostname (endpoint) of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "Port the database listens on"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database created inside the instance"
  value       = aws_db_instance.this.db_name
}
