variable "name" {
  description = "VPC name, also prefixes subnet and route-table names"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty string (max 128 chars)."
  }
}


variable "cidr_block" {
  description = "CIDR block for the whole VPC -- pick an IP range nothing else in your estate already uses"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Optional AZ names, assigned positionally (first CIDR into first AZ, and so on). Empty means the emulator/region picks for you. On real AWS pass enough AZs to spread subnets across multiple zones for HA."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the public subnets (internet-facing tier)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for the private subnets (internal tier)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "One NAT gateway for all private subnets (cost-conscious default: off)"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances launched in the public subnets. Secure default: false -- opt in only for deliberately internet-facing lab stacks (Trivy AWS-0164)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Capture VPC Flow Logs to CloudWatch Logs (Trivy AWS-0178). CloudWatch Logs ingestion is billed on real AWS; disable only if that cost outweighs the network visibility."
  type        = bool
  default     = true
}

variable "create_flow_logs_kms_key" {
  description = "Create a dedicated customer-managed KMS key (rotation on) for the flow-log group when flow_logs_kms_key_arn is null. On real AWS a CMK costs about $1/month; set false to keep the CloudWatch-managed key (reintroduces Trivy AWS-0017)."
  type        = bool
  default     = true
}

variable "flow_logs_kms_key_arn" {
  description = "Existing customer-managed KMS key ARN for the flow-log group. When null and create_flow_logs_kms_key is true, the module creates one."
  type        = string
  default     = null
}

variable "flow_logs_retention_days" {
  description = "Days VPC Flow Log records are kept in CloudWatch Logs"
  type        = number
  default     = 7
}

variable "flow_logs_traffic_type" {
  description = "Which flows to capture: ALL, ACCEPT or REJECT"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be one of ALL, ACCEPT, REJECT."
  }
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
