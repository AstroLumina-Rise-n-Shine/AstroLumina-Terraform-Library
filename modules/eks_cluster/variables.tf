variable "name" {
  description = "Cluster name (also prefixes the IAM roles and node group)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version managed by EKS"
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "Explicit subnet IDs for cluster and nodes (no data-source lookup, caller passes them)"
  type        = list(string)
}

variable "cluster_encryption_key_arn" {
  description = "KMS key ARN for EKS secrets envelope encryption (no default on purpose: every caller must consciously pick a key)"
  type        = string
}

variable "instance_types" {
  description = "EC2 instance types for the managed worker nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "desired_size" {
  description = "Desired worker node count"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum worker node count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum worker node count"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to every created object"
  type        = map(string)
  default     = {}
}
