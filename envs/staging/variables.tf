variable "project" {
  description = "Project prefix"
  type        = string
  default     = "wp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "zone_name" {
  description = "Route53 hosted zone"
  type        = string
  default     = "wp-demo-bogdan.click"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "A single NAT per environment instead of one per zone"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Flow logs retention, days"
  type        = number
  default     = 7
}

variable "container_image" {
  description = "WordPress image from ECR"
  type        = string
  default     = "756250138234.dkr.ecr.eu-central-1.amazonaws.com/wp/wordpress:sha-67e4481"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "sha-67e4481"
}

variable "service_desired_count" {
  description = "Initial task count"
  type        = number
  default     = 2
}

variable "service_min_capacity" {
  description = "Minimum task count"
  type        = number
  default     = 2
}

variable "service_max_capacity" {
  description = "Maximum task count"
  type        = number
  default     = 4
}

variable "log_retention_days" {
  description = "Log retention, days"
  type        = number
  default     = 7
}

variable "container_insights" {
  description = "ECS Container Insights"
  type        = string
  default     = "enabled"
}

variable "db_instance_count" {
  description = "Database instance count"
  type        = number
  default     = 1
}

variable "db_min_capacity" {
  description = "Minimum ACU; 0 enables auto-pause"
  type        = number
  default     = 0
}

variable "db_max_capacity" {
  description = "Maximum ACU"
  type        = number
  default     = 2
}

variable "db_seconds_until_auto_pause" {
  description = "Idle time before pausing, seconds"
  type        = number
  default     = 3600
}

variable "db_backup_retention_days" {
  description = "Backup retention, days"
  type        = number
  default     = 1
}

variable "alarm_emails" {
  description = "Alert recipients; each subscription must be confirmed by email"
  type        = list(string)
  default     = []
}
