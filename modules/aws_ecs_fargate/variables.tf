variable "name" {
  description = "Name used for the cluster, task definition family, service and execution role"
  type        = string
}

variable "image" {
  description = "Container image to run, e.g. nginx:alpine"
  type        = string
}

variable "cpu" {
  description = "Task-level CPU units as a string (Fargate valid combos: 256/512, 512/1024, ...)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Task-level memory in MiB as a string (must pair with cpu per Fargate size table)"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of tasks the service keeps running"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnets the task ENIs live in (explicit IDs, no data-source lookup)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the task ENIs"
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Port the container listens on (published inside the task network)"
  type        = number
  default     = 80
}

variable "assign_public_ip" {
  description = "Give each task ENI a public IP (ENABLED needed for image pulls from private subnets with no NAT)"
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Environment variables injected into the container"
  type        = map(string)
  default     = {}
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
