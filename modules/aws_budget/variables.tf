variable "name" {
  description = "Budget name (also the notification SNS topic name)"
  type        = string
}

variable "limit_amount" {
  description = "Budget limit -- a decimal string because the API treats the amount as text (e.g. \"100\")"
  type        = string
  default     = "100"
}

variable "time_unit" {
  description = "Period the budget covers before it resets"
  type        = string
  default     = "MONTHLY"

  validation {
    condition     = contains(["DAILY", "MONTHLY", "QUARTERLY", "ANNUALLY"], var.time_unit)
    error_message = "time_unit must be one of: DAILY, MONTHLY, QUARTERLY, ANNUALLY."
  }
}

variable "budget_type" {
  description = "What the budget tracks -- also selects the semantic family of the limit"
  type        = string
  default     = "COST"

  validation {
    condition     = contains(["COST", "USAGE", "RI_UTILIZATION", "RI_COVERAGE", "SAVINGS_PLANS_UTILIZATION", "SAVINGS_PLANS_COVERAGE"], var.budget_type)
    error_message = "budget_type must be one of: COST, USAGE, RI_UTILIZATION, RI_COVERAGE, SAVINGS_PLANS_UTILIZATION, SAVINGS_PLANS_COVERAGE."
  }
}

variable "notification_thresholds" {
  description = "Alert trigger points, expressed as percentages of limit_amount (e.g. [50, 80, 100])"
  type        = list(number)
  default     = [50, 80, 100]
}

variable "notification_emails" {
  description = "Email addresses subscribed to the notification topic (each receives an SNS confirmation to click once)"
  type        = list(string)
  default     = []
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
