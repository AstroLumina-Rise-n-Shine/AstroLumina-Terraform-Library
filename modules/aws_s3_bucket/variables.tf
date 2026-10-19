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
