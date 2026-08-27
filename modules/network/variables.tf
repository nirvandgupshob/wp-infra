variable "name_prefix" {
  description = "Resource name prefix"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name_prefix))
    error_message = "Lowercase letters, digits and hyphens, 2 to 31 characters."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block, no smaller than /16"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "A valid CIDR no smaller than /16 is required."
  }
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Allowed: 2 or 3 zones."
  }
}

variable "single_nat_gateway" {
  description = "A single NAT instead of one per zone"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Log VPC connections"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Flow logs retention, days"
  type        = number
  default     = 7
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}
