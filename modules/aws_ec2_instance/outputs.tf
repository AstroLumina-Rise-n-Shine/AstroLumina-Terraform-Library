output "instance_id" {
  description = "ID of the EC2 instance (i-...)"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the instance inside its subnet"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance (empty string when associate_public_ip_address is false)"
  value       = aws_instance.this.public_ip
}
