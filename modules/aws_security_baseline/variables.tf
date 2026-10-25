variable "name" {
  description = "Baseline name (prefixes the KMS alias and defaults the CloudTrail bucket name)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
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

variable "enable_cloudtrail_cloudwatch_logs" {
  description = "Stream CloudTrail events to a CloudWatch Logs group for real-time analysis (Trivy AWS-0162). CloudWatch Logs ingestion is billed on real AWS; disable only if that cost outweighs the alerting value."
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "Days CloudTrail events are kept in CloudWatch Logs (the S3 archive is unaffected and keeps its own lifecycle)"
  type        = number
  default     = 30
}

variable "enable_cloudtrail_access_logging" {
  description = "Enable S3 server access logging on the trail bucket (Trivy AWS-0089), delivered to a dedicated destination bucket"
  type        = bool
  default     = true
}

variable "cloudtrail_access_logs_bucket_name" {
  description = "Destination bucket for trail-bucket access logs. When null, defaults to \"<cloudtrail bucket>-access-logs\". The module creates and hardens this bucket, so the name must not already be in use, and it must be 63 characters or fewer."
  type        = string
  default     = null

  validation {
    condition     = var.cloudtrail_access_logs_bucket_name == null || length(var.cloudtrail_access_logs_bucket_name) <= 63
    error_message = "cloudtrail_access_logs_bucket_name must be 63 characters or fewer (S3 bucket-name limit)."
  }
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for trail logs. When null, defaults to \"<name>-cloudtrail\" (Floci does not enforce global uniqueness; real AWS does). With access logging enabled the derived destination appends \"-access-logs\", so keep this to 51 characters or fewer."
  type        = string
  default     = null

  validation {
    condition     = var.cloudtrail_bucket_name == null || length(var.cloudtrail_bucket_name) <= 63
    error_message = "cloudtrail_bucket_name must be 63 characters or fewer (S3 bucket-name limit)."
  }
}

variable "environment" {
  description = "Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env."
  type        = string
  validation {
    condition     = length(var.environment) > 0
    error_message = "environment must be a non-empty string."
  }
}


variable "tags" {
  description = "Extra tags applied to every created object"
  type        = map(string)
  default     = {}
}
