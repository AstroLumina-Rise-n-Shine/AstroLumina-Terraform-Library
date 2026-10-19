variable "name" {
  description = "VPC name, also prefixes subnet and route-table names"
  type        = string
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

variable "environment" {
  description = "Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to every created object"
  type        = map(string)
  default     = {}
}
