variable "name" {
  description = "Instance name -- also stamped as the Name tag"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "ami" {
  description = "AMI ID. Floci maps any AMI ID to its local runtime image; real AWS needs a real AMI."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance size/shape"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet the instance is launched into (no lookup, caller passes the ID)"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to the instance's primary network interface"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "SSH key pair name for the instance; null (fine on Floci) means no SSH key"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Optional cloud-init / shell script executed on first boot"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether the instance's primary interface auto-assigns a public IP -- REQUIRES a public subnet when true"
  type        = bool
  default     = true
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
