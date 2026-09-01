variable "project" {
  description = "Project prefix"
  type        = string
  default     = "wp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "One NAT per availability zone instead of a single one"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Flow logs retention, days"
  type        = number
  default     = 30
}

variable "container_image" {
  description = "WordPress image from ECR"
  type        = string
  default     = "756250138234.dkr.ecr.eu-central-1.amazonaws.com/wp/wordpress@sha256:8c85241d995ba37bd041b5045bd9d630d1d45b7d359d4c300a3dd1f0f3b68d09"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "v0.1.2"
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
  default     = 6
}

variable "log_retention_days" {
  description = "Log retention, days"
  type        = number
  default     = 90
}

variable "container_insights" {
  description = "ECS Container Insights"
  type        = string
  default     = "enabled"
}

variable "deletion_protection" {
  description = "Deletion protection for the load balancer and database"
  type        = bool
  default     = true
}

variable "db_instance_count" {
  description = "Database instance count"
  type        = number
  default     = 2
}

variable "db_min_capacity" {
  description = "Minimum ACU"
  type        = number
  default     = 0.5
}

variable "db_max_capacity" {
  description = "Maximum ACU"
  type        = number
  default     = 8
}

variable "db_backup_retention_days" {
  description = "Backup retention, days"
  type        = number
  default     = 30
}

variable "alarm_emails" {
  description = "Alert recipients; each subscription must be confirmed by email"
  type        = list(string)
  default     = []
}
