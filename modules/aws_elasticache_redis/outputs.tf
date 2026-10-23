output "id" {
  description = "Identifier of the Redis replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "arn" {
  description = "ARN of the Redis replication group"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Hostname clients write to (the primary node endpoint)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Hostname for read-only clients (the reader endpoint)"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Port the cache listens on"
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "ID of the security group created by the module (null when create_security_group = false)"
  value       = local.created_security_group_id
}

output "configuration_endpoint_address" {
  description = "Cluster-mode configuration endpoint address (null when cluster mode is disabled, which is always the case here)"
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}
