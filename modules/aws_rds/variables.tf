variable "name" {
  description = "DB instance identifier (also prefixes the subnet group name; also the Name tag)"
  type        = string
}

variable "engine" {
  description = "Database engine (e.g. postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version; null lets AWS/Floci pick the default for the engine"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "DB instance class (the smallest burstable one is fine for learning)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size in gibibytes"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name created inside the instance"
  type        = string
  default     = "astrolumina"
}

variable "username" {
  description = "Master username for the instance"
  type        = string
  default     = "astrolumina"
}

variable "password" {
  description = "Master password. Learning-only: pass it via tfvars/CLI, never commit it to git -- a committed DB password is a breach waiting to happen."
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Port the database listens on (5432 for postgres, 3306 for mysql)"
  type        = number
  default     = 5432
}

variable "subnet_ids" {
  description = "At least two subnets (different AZs is ideal) for the DB subnet group, explicit IDs with no data-source lookup"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups controlling who can reach the database port"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Give the instance a public IP. Keep this false; reach it from inside the VPC (or via VPN/bastion)."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Encrypt storage at rest with an AWS-managed key (default true; production would bring its own KMS key)"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Database engine logs exported to CloudWatch. PostgreSQL defaults to postgresql; set engine-compatible log types for other engines."
  type        = list(string)
  default     = null

  validation {
    condition     = var.engine == "postgres" || var.enabled_cloudwatch_logs_exports != null
    error_message = "Set enabled_cloudwatch_logs_exports to log types supported by the selected non-PostgreSQL engine."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights (query-level monitoring; the default 7-day retention is in the free tier)"
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Create a dedicated customer-managed KMS key (with rotation) for Performance Insights when kms_key_arn is null and PI is enabled. On real AWS a CMK costs about $1/month; set false to keep the AWS-managed key (which reintroduces Trivy AWS-0078)."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing customer-managed KMS key ARN for Performance Insights encryption. When null and create_kms_key is true, the module creates one. Bring your own key to share a key across instances."
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Days of Performance Insights data kept (7 is the free tier; raise it only if you are ready to pay for the longer history)"
  type        = number
  default     = 7
}

variable "backup_retention_period" {
  description = "Days of automatic backups kept (0 disables; secure-ish default: 7)"
  type        = number
  default     = 7
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication so apps can use short-lived tokens instead of the master password"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Block accidental deletion of the instance. Secure default: true; lab stacks set false so destroy stays one command."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy -- learning-friendly default: fast, cheap teardown instead of a leftover backup cost"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags applied to every created object"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env."
  type        = string
}
