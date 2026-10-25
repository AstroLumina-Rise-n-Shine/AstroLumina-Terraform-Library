variable "name" {
  description = "IAM role name (globally unique within the account)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "assume_role_service" {
  description = "AWS service that may assume the role when assume_role_policy_json is null (e.g. ec2.amazonaws.com)"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "assume_role_policy_json" {
  description = "Full custom trust policy JSON. Overrides assume_role_service when set -- use it for friends, accounts or wildcard principals the simple default cannot express"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "ARNs of AWS-managed or customer-managed policies to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy name => JSON policy document, embedded directly in the role"
  type        = map(string)
  default     = {}
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
