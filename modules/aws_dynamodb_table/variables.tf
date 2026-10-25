variable "name" {
  description = "Table name (unique per account/region)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "hash_key" {
  description = "Attribute holding the partition (hash) key"
  type        = string
  default     = "id"
}

variable "hash_key_type" {
  description = "Type of the hash-key attribute: S (string), N (number) or B (binary)"
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "hash_key_type must be one of S, N, B."
  }
}

variable "range_key" {
  description = "Optional attribute holding the sort (range) key; leave null for hash-key-only tables"
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Type of the range-key attribute: S (string), N (number) or B (binary)"
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.range_key_type)
    error_message = "range_key_type must be one of S, N, B."
  }
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand, pay per call) or PROVISIONED (fixed capacity)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "billing_mode must be one of PROVISIONED, PAY_PER_REQUEST."
  }
}

variable "read_capacity" {
  description = "Read capacity units -- ignored (on real AWS) unless billing_mode is PROVISIONED"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units -- ignored (on real AWS) unless billing_mode is PROVISIONED"
  type        = number
  default     = 5
}

variable "ttl_attribute" {
  description = "Optional attribute (e.g. \"expires_at\") holding epoch seconds; when set, TTL deletion is enabled on it"
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a dedicated customer-managed KMS key (with rotation) for table encryption when kms_key_arn is null. On real AWS a CMK costs about $1/month; set false to keep the AWS-managed key (which reintroduces Trivy AWS-0025)."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing customer-managed KMS key ARN for table encryption. When null and create_kms_key is true, the module creates one. Bring your own key to share a key across tables."
  type        = string
  default     = null
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
