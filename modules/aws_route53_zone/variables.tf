variable "name" {
  description = "Domain name of the hosted zone, e.g. lab.astrolumina.ro (record names build on top of it)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "comment" {
  description = "Free-form comment stored on the hosted zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "private_zone" {
  description = "When true, create a private hosted zone that only answers inside the attached VPC instead of on the public internet"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC the zone is associated with -- required when private_zone = true"
  type        = string
  default     = null
}

variable "vpc_region" {
  description = "Region of the VPC association -- optional when private_zone = true"
  type        = string
  default     = null
}

variable "records" {
  description = "Map of extra DNS records: relative name (use '@' for the zone apex) => { type, ttl, values }"
  type = map(object({
    type   = string
    ttl    = number
    values = list(string)
  }))
  default = {}
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
