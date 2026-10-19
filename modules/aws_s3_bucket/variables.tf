variable "name" {
  description = "Bucket name. Must be globally unique on real AWS; on Floci any DNS-safe name works."
  type        = string
}

variable "versioning_enabled" {
  description = "Whether object versions are kept (Enabled) or paused (Suspended)"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (`AES256` or `aws:kms`)"
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption -- only used when sse_algorithm is `aws:kms`"
  type        = string
  default     = null
}

variable "enable_access_logging" {
  description = "Enable S3 server access logging (Trivy AWS-0089). When logging_target_bucket is null, a dedicated \"<name>-logs\" destination bucket is created."
  type        = bool
  default     = true
}

variable "logging_target_bucket" {
  description = "Existing bucket to receive server access logs. When null, the module creates \"<name>-logs\" and grants logging.s3.amazonaws.com write access to it. A caller-supplied bucket must already allow that principal to PutObject."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "Key prefix for access log objects in the destination bucket (include the trailing slash)"
  type        = string
  default     = "access-logs/"

  validation {
    condition     = !startswith(var.access_logs_prefix, "/")
    error_message = "access_logs_prefix must not start with a slash."
  }
}

variable "force_destroy" {
  description = "Learning-friendly: destroy the bucket even when it still holds objects"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to every created object"
  type        = map(string)
  default     = {}
}
