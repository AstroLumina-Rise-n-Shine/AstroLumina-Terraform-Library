variable "name" {
  description = "Replication group identifier (also prefixes the subnet group, parameter group and security group; also the Name tag)"
  type        = string
}

variable "subnet_ids" {
  description = "At least two subnets (different AZs is ideal) for the cache subnet group, explicit IDs with no data-source lookup"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC where the module-created security group lives. Required only when create_security_group = true; ignored otherwise."
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Existing security groups that may reach the cache; they are kept alongside the module-created group instead of being replaced"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create a dedicated security group for the cache. It starts with no ingress rules; open the port only via allowed_cidr_blocks/allowed_security_group_ids."
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the Redis port. Keep this inside the VPC -- 0.0.0.0/0 makes the cache internet-reachable (Trivy AWS-0104)."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach the Redis port (the preferred way to grant access: no CIDR arithmetic)"
  type        = list(string)
  default     = []
}

variable "node_type" {
  description = "ElastiCache node type (the smallest burstable one is fine for learning)"
  type        = string
  default     = "cache.t3.micro"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "parameter_group_family" {
  description = "Parameter group family matching engine_version (redis7 for Redis 7.x)"
  type        = string
  default     = "redis7"
}

variable "create_parameter_group" {
  description = "Create a parameter group pinned to parameter_group_family; false lets AWS pick the default group for the engine version"
  type        = bool
  default     = true
}

variable "port" {
  description = "Port the cache listens on"
  type        = number
  default     = 6379
}

variable "at_rest_encryption_enabled" {
  description = "Encrypt the cache storage at rest (default true; Trivy AWS-0100)"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional customer-managed KMS key ARN/ID for at-rest encryption. Null keeps the AWS-managed key; ignored when at_rest_encryption_enabled = false."
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "Encrypt client connections in transit with TLS (default true; Trivy AWS-0105)"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Optional Redis AUTH token (16-128 printable characters). Requires transit_encryption_enabled = true. Pass it via tfvars/CLI, never commit it -- a committed cache secret is a breach waiting to happen."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.auth_token == null ? true : length(var.auth_token) >= 16 && length(var.auth_token) <= 128
    error_message = "auth_token must be between 16 and 128 characters when set (AWS AUTH constraint)."
  }
}

variable "snapshot_retention_limit" {
  description = "Days of daily automatic snapshots kept (0 disables backups; secure-ish default: 1)"
  type        = number
  default     = 1

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "snapshot_retention_limit must be between 0 and 35 days."
  }
}

variable "tags" {
  description = "Extra tags applied to every created object"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment this cache belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env."
  type        = string
}
