variable "name" {
  description = "Name for the load balancer and target group"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "vpc_id" {
  description = "VPC the target group lives in"
  type        = string
}

variable "subnet_ids" {
  description = "At least two subnets (different AZs) the ALB attaches to, explicit IDs with no data-source lookup"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the ALB (control who can reach the listener)"
  type        = list(string)
}

variable "internal" {
  description = "Internal load balancer. Secure default: true (VPC-only ingress); set false only for deliberately internet-facing entry points (Trivy AWS-0053)."
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "Existing S3 bucket in the ALB's region configured to accept ELB access logs"
  type        = string
}

variable "access_logs_prefix" {
  description = "Optional prefix for ALB access logs in the destination bucket"
  type        = string
  default     = null
}

variable "listener_port" {
  description = "Port the ALB listener accepts traffic on (443 for HTTPS, 80 for plain HTTP)"
  type        = number
  default     = 443
}

variable "listener_protocol" {
  description = "Listener protocol. Secure default: HTTPS (Trivy AWS-0054); labs/emulators without certificates pass HTTP explicitly."
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTPS", "HTTP"], var.listener_protocol)
    error_message = "listener_protocol must be HTTPS or HTTP."
  }
}

variable "certificate_arn" {
  description = "ACM (or imported) certificate ARN used by the HTTPS listener; required when listener_protocol = HTTPS"
  type        = string
  default     = null
}

variable "target_port" {
  description = "Port targets receive traffic on"
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "Protocol used to talk to targets (e.g. HTTP, TCP)"
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Kind of target behind the ALB: instance (EC2), ip (Fargate/awsvpc tasks) or lambda"
  type        = string
  default     = "ip"

  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type must be one of: instance, ip, lambda."
  }
}

variable "health_check_path" {
  description = "HTTP path the ALB requests to decide whether a target is healthy"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Extra tags applied to every created object"
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

