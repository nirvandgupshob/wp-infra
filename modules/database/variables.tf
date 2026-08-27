variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "subnet_ids" {
  description = "Isolated subnets, at least two zones"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Aurora requires subnets in at least two availability zones."
  }
}

variable "availability_zones" {
  description = "Availability zones in subnet order"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Database security groups"
  type        = list(string)
}

variable "engine_version" {
  description = "Aurora MySQL version"
  type        = string
  default     = "8.4.mysql_aurora.8.4.7"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "wordpress"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "wpadmin"

  validation {
    condition     = !contains(["admin", "rdsadmin", "root", "mysql"], lower(var.master_username))
    error_message = "This name is reserved by MySQL or RDS."
  }
}

variable "min_capacity" {
  description = "Minimum ACU; 0 enables auto-pause"
  type        = number
  default     = 0

  validation {
    condition     = var.min_capacity == 0 || var.min_capacity >= 0.5
    error_message = "Either 0 (auto-pause) or a value from 0.5."
  }
}

variable "max_capacity" {
  description = "Maximum ACU"
  type        = number
  default     = 4
}

variable "seconds_until_auto_pause" {
  description = "Idle time before pausing, seconds; only when min_capacity is 0"
  type        = number
  default     = 3600

  validation {
    condition     = var.seconds_until_auto_pause >= 300 && var.seconds_until_auto_pause <= 86400
    error_message = "Allowed: 300 to 86400 seconds."
  }
}

variable "instance_count" {
  description = "Instance count; two are required for failover"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 3
    error_message = "Allowed: 1 to 3 instances."
  }
}

variable "backup_retention_days" {
  description = "Backup retention and PITR window, days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Allowed: 1 to 35 days."
  }
}

variable "deletion_protection" {
  description = "Cluster deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on deletion"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of the maintenance window"
  type        = bool
  default     = false
}

variable "slow_query_seconds" {
  description = "Slow query threshold, seconds"
  type        = number
  default     = 2
}
