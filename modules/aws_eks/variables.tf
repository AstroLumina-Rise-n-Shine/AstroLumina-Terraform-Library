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

variable "enable_cluster_autoscaler" {
  description = "Provision the AWS side of Cluster Autoscaler IRSA: an OIDC provider, an IAM role trusted by the autoscaler service account, a least-privilege scaling policy, and the discovery tags on the node group. The Helm chart itself is installed outside this module."
  type        = bool
  default     = false
}

variable "cluster_autoscaler_service_account_namespace" {
  description = "Namespace of the Cluster Autoscaler service account the IRSA role trusts (only used when enable_cluster_autoscaler = true)"
  type        = string
  default     = "kube-system"
}

variable "cluster_autoscaler_service_account_name" {
  description = "Name of the Cluster Autoscaler service account the IRSA role trusts (only used when enable_cluster_autoscaler = true)"
  type        = string
  default     = "cluster-autoscaler"
}

variable "tags" {
  description = "Tags applied to every created object"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment this cluster belongs to (development, staging or production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env."
  type        = string
}
