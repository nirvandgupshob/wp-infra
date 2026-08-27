variable "project" {
  description = "Project prefix"
  type        = string
  default     = "wp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.project))
    error_message = "Lowercase letters, digits and hyphens, 2 to 16 characters."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "noncurrent_version_retention_days" {
  description = "Noncurrent state version retention, days"
  type        = number
  default     = 30
}

variable "infra_repository" {
  description = "Infrastructure repository as owner/repo"
  type        = string
  default     = "nirvandgupshob/wp-infra"
}

variable "app_repository" {
  description = "Application repository as owner/repo"
  type        = string
  default     = "nirvandgupshob/wp-app"
}
