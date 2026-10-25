variable "name" {
  description = "Function name (also the Name tag)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "filename" {
  description = "Path to the deployment zip file"
  type        = string
}

variable "source_code_hash" {
  description = "Hash of the zip contents -- change it so Terraform re-uploads the code (e.g. filebase64sha256(file(var.filename)))"
  type        = string
  default     = null
}

variable "handler" {
  description = "Entry-point of the function code (file.function)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier"
  type        = string
  default     = "python3.12"
}

variable "role_arn" {
  description = "ARN of the IAM execution role the function assumes (caller-provided: permissions are the caller's design decision)"
  type        = string
}

variable "memory_size" {
  description = "Memory allocated to the function, in MB (also scales its CPU share)"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Max seconds a single invocation may run before being killed"
  type        = number
  default     = 3
}

variable "environment_variables" {
  description = "Key/value map exposed to the function code as environment variables"
  type        = map(string)
  default     = {}
}

variable "environment_kms_key_arn" {
  description = "Optional customer-managed KMS key for Lambda environment variables. Null uses Lambda's AWS-managed encryption key."
  type        = string
  default     = null
}

variable "publish" {
  description = "Whether to create an immutable numbered version on every deploy"
  type        = bool
  default     = false
}

variable "tracing_mode" {
  description = "X-Ray tracing mode: Active (default -- every invocation traced) or PassThrough (no tracing)"
  type        = string
  default     = "Active"
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
