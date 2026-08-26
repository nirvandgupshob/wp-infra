variable "name_prefix" {
  description = "Префикс имён ресурсов"
  type        = string
}

variable "alarm_emails" {
  description = "Адреса для уведомлений; подписку нужно подтвердить письмом"
  type        = list(string)
  default     = []
}

variable "alb_arn_suffix" {
  description = "Суффикс ARN балансировщика"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Суффикс ARN target group"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Кластер ECS"
  type        = string
}

variable "ecs_service_name" {
  description = "Сервис ECS"
  type        = string
}

variable "db_cluster_identifier" {
  description = "Идентификатор кластера Aurora"
  type        = string
}

variable "log_group_name" {
  description = "Группа логов контейнеров"
  type        = string
}

variable "site_domain" {
  description = "Имя для внешней проверки доступности"
  type        = string
}

variable "desired_count" {
  description = "Ожидаемое число задач"
  type        = number
}

variable "db_max_capacity" {
  description = "Максимум ACU базы"
  type        = number
}

variable "healthy_hosts_threshold" {
  description = "Минимум здоровых задач за балансировщиком"
  type        = number
  default     = 1
}

variable "error_5xx_threshold" {
  description = "Ошибок 5xx за пять минут"
  type        = number
  default     = 10
}

variable "latency_p95_seconds" {
  description = "Порог задержки p95, секунд"
  type        = number
  default     = 2
}

variable "db_cpu_threshold" {
  description = "Порог загрузки CPU базы, процентов"
  type        = number
  default     = 80
}

variable "enable_health_check" {
  description = "Внешняя проверка доступности через Route53"
  type        = bool
  default     = true
}
