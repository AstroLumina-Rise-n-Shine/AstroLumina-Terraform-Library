variable "name" {
  description = "IAM user name (globally unique within the account)"
  type        = string
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
}

variable "tags" {
  description = "Extra tags applied to every created object"
  type        = map(string)
  default     = {}
}
