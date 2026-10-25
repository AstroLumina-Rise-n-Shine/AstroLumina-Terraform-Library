variable "name" {
  description = "Name prefix for the VPN objects (also the Name tags)"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "vpc_id" {
  description = "VPC the VPN gateway attaches to"
  type        = string
}

variable "customer_gateway_ip" {
  description = "Public IP of the on-prem router/firewall terminating the VPN"
  type        = string
}

variable "bgp_asn" {
  description = "BGP ASN of the customer gateway (kept as string because the API expects it that way; always required, even with static routes)"
  type        = string
  default     = "65000"
}

variable "static_routes_only" {
  description = "Declare on-prem destination CIDRs manually instead of learning them via BGP"
  type        = bool
  default     = true
}

variable "destination_cidrs" {
  description = "On-prem CIDRs routed through the VPN (only used when static_routes_only = true)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "route_table_ids" {
  description = "Optional route tables that should have the VPN routes propagated into them"
  type        = list(string)
  default     = []
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

