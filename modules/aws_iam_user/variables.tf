variable "name" {
  description = "IAM user name (globally unique within the account)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "managed_policy_arns" {
  description = "ARNs of AWS-managed or customer-managed policies to attach to the user"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy name => JSON policy document, embedded directly in the user"
  type        = map(string)
  default     = {}
}

variable "create_access_key" {
  description = "Whether to create a programmatic access key (learning/demo only -- the secret is sensitive and must never be committed or logged)"
  type        = bool
  default     = false
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
