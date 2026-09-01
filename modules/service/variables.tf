variable "name_prefix" {
  description = "Resource name prefix, up to 32 characters"
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "Load balancer and target group names cannot exceed 32 characters."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "Environment VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Load balancer subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Task subnets"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Load balancer security group"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Task security group"
  type        = string
}

variable "route53_zone_id" {
  description = "Hosted zone for A records"
  type        = string
}

variable "dns_names" {
  description = "Names pointing at the load balancer"
  type        = list(string)
}

variable "certificate_arn" {
  description = "Validated ACM certificate"
  type        = string
}

variable "ssl_policy" {
  description = "Listener TLS policy"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "container_image" {
  description = "Image from ECR; CI passes a digest"
  type        = string
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "dev"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "cpu_architecture" {
  description = "Task architecture; must match the image"
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.cpu_architecture)
    error_message = "Allowed: ARM64 or X86_64."
  }
}

variable "task_cpu" {
  description = "Task CPU units; 512 is 0.5 vCPU"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task memory, MiB"
  type        = number
  default     = 1024
}

variable "db_host" {
  description = "Database endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_secret_arn" {
  description = "Database credentials secret"
  type        = string
}

variable "db_secret_kms_key_arn" {
  description = "Database secret encryption key"
  type        = string
}

variable "efs_file_system_id" {
  description = "File system for uploads"
  type        = string
}

variable "efs_file_system_arn" {
  description = "File system ARN"
  type        = string
}

variable "efs_access_point_id" {
  description = "Uploads access point"
  type        = string
}

variable "efs_access_point_arn" {
  description = "Access point ARN"
  type        = string
}

variable "desired_count" {
  description = "Initial task count"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum task count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum task count"
  type        = number
  default     = 6
}

variable "cpu_target_percent" {
  description = "Target CPU utilization"
  type        = number
  default     = 60
}

variable "requests_per_target" {
  description = "Target requests per task"
  type        = number
  default     = 600
}

variable "admin_username" {
  description = "WordPress administrator login"
  type        = string
  default     = "wpadmin"
}

variable "admin_email" {
  description = "Administrator email"
  type        = string
  default     = "admin@example.test"
}

variable "secret_recovery_days" {
  description = "Secret recovery window, days"
  type        = number
  default     = 0
}

variable "log_retention_days" {
  description = "Container log retention, days"
  type        = number
  default     = 30
}

variable "container_insights" {
  description = "ECS Container Insights"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enhanced", "disabled"], var.container_insights)
    error_message = "Allowed: enabled, enhanced or disabled."
  }
}

variable "deletion_protection" {
  description = "Load balancer deletion protection"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Wait for the service to become stable"
  type        = bool
  default     = false
}

variable "admin_password_version" {
  description = "Bump to regenerate the administrator password"
  type        = number
  default     = 1
}

variable "salts_version" {
  description = "Bump to regenerate the authentication salts"
  type        = number
  default     = 1
}
