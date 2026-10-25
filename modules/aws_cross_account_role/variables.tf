variable "name" {
  description = "IAM role name (globally unique within this account; the trusted account assumes this ARN)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "trusted_account_id" {
  description = "12-digit AWS account ID allowed to assume this role (its root principal trusts only its own explicitly-delegated users)"
  type        = string
}

variable "external_id" {
  description = "Optional sts:ExternalId condition -- confused-deputy protection; share it with the trusted account as a secret alongside the role ARN"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "ARNs of AWS-managed or customer-managed policies the trusted account inherits when assuming this role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy name => JSON policy document, embedded directly in the role"
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Maximum sts:AssumeRole session length in seconds (3600 default; console allows up to 12h)"
  type        = number
  default     = 3600
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
