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

variable "github_owner" {
  description = "GitHub account name and numeric id"
  type = object({
    name = string
    id   = number
  })
  default = {
    name = "nirvandgupshob"
    id   = 158572548
  }
}

variable "infra_repository" {
  description = "Infrastructure repository name and numeric id"
  type = object({
    name = string
    id   = number
  })
  default = {
    name = "wp-infra"
    id   = 1344731792
  }
}

variable "app_repository" {
  description = "Application repository name and numeric id"
  type = object({
    name = string
    id   = number
  })
  default = {
    name = "wp-app"
    id   = 1345383465
  }
}

variable "audit_log_retention_days" {
  description = "CloudTrail log retention, days"
  type        = number
  default     = 90
}
