variable "name" {
  description = "Baseline name (prefixes the KMS alias and defaults the CloudTrail bucket name)"
  type        = string
}

variable "enable_guardduty" {
  description = "Whether to create the GuardDuty threat-detection detector (off when billed analysis has no value in a sandbox)"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Whether to enable the Security Hub account"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Whether to create the full CloudTrail stack (S3 bucket + policy + trail)"
  type        = bool
  default     = true
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for trail logs. When null, defaults to \"<name>-cloudtrail\" (Floci does not enforce global uniqueness; real AWS does)"
  type        = string
  default     = null
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
