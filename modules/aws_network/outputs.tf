output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (internet-facing tier)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (internal tier)"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway attached to the VPC"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways (list with one entry when enabled, empty when disabled)"
  value       = aws_nat_gateway.this[*].id
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log (null when enable_flow_logs is false)"
  value       = var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

output "flow_logs_log_group_name" {
  description = "Name of the CloudWatch Logs group receiving VPC Flow Logs (null when disabled)"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_logs_role_arn" {
  description = "ARN of the IAM role VPC Flow Logs assumes to write to CloudWatch Logs (null when disabled)"
  value       = var.enable_flow_logs ? aws_iam_role.flow_logs[0].arn : null
}

output "flow_logs_kms_key_arn" {
  description = "ARN of the CMK encrypting the flow-log group (null when flow logs are disabled, or key creation was opted out)"
  value       = var.enable_flow_logs ? local.flow_logs_kms_key_arn : null
}
