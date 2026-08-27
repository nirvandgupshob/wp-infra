variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "alarm_emails" {
  description = "Alert recipients; each subscription must be confirmed by email"
  type        = list(string)
  default     = []
}

variable "alb_arn_suffix" {
  description = "Load balancer ARN suffix"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service"
  type        = string
}

variable "db_cluster_identifier" {
  description = "Aurora cluster identifier"
  type        = string
}

variable "log_group_name" {
  description = "Container log group"
  type        = string
}

variable "site_domain" {
  description = "Domain for the external availability check"
  type        = string
}

variable "desired_count" {
  description = "Expected task count"
  type        = number
}

variable "db_max_capacity" {
  description = "Database maximum ACU"
  type        = number
}

variable "healthy_hosts_threshold" {
  description = "Minimum healthy targets behind the load balancer"
  type        = number
  default     = 1
}

variable "error_5xx_threshold" {
  description = "5xx errors per five minutes"
  type        = number
  default     = 10
}

variable "latency_p95_seconds" {
  description = "p95 latency threshold, seconds"
  type        = number
  default     = 2
}

variable "db_cpu_threshold" {
  description = "Database CPU threshold, percent"
  type        = number
  default     = 80
}

variable "enable_health_check" {
  description = "External availability check via Route53"
  type        = bool
  default     = true
}
