variable "name" {
  description = "Name for the load balancer and target group"
  type        = string
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
  description = "Internal load balancer (would be true for VPC-only ingress, e.g. behind a VPN)"
  type        = bool
  default     = false
}

variable "listener_port" {
  description = "Port the ALB listener accepts traffic on"
  type        = number
  default     = 80
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
}
