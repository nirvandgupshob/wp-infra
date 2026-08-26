variable "name_prefix" {
  description = "Префикс имён ресурсов, до 32 символов"
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "Имя балансировщика и target group не может быть длиннее 32 символов."
  }
}

variable "environment" {
  description = "Имя окружения"
  type        = string
}

variable "vpc_id" {
  description = "VPC окружения"
  type        = string
}

variable "public_subnet_ids" {
  description = "Подсети балансировщика"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Подсети задач"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Группа балансировщика"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Группа задач"
  type        = string
}

variable "route53_zone_id" {
  description = "Зона для A-записей"
  type        = string
}

variable "dns_names" {
  description = "Имена, указывающие на балансировщик"
  type        = list(string)
}

variable "certificate_arn" {
  description = "Подтверждённый сертификат ACM"
  type        = string
}

variable "ssl_policy" {
  description = "Набор шифров listener'а"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "container_image" {
  description = "Образ из ECR; в CI с дайджестом"
  type        = string
}

variable "app_version" {
  description = "Версия приложения"
  type        = string
  default     = "dev"
}

variable "container_port" {
  description = "Порт контейнера"
  type        = number
  default     = 8080
}

variable "cpu_architecture" {
  description = "Архитектура задачи; должна совпадать с образом"
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.cpu_architecture)
    error_message = "Допустимо ARM64 или X86_64."
  }
}

variable "task_cpu" {
  description = "CPU задачи; 512 это 0.5 vCPU"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Память задачи, МиБ"
  type        = number
  default     = 1024
}

variable "db_host" {
  description = "Адрес базы"
  type        = string
}

variable "db_name" {
  description = "Имя базы"
  type        = string
}

variable "db_secret_arn" {
  description = "Секрет с учётными данными базы"
  type        = string
}

variable "db_secret_kms_key_arn" {
  description = "Ключ шифрования секрета базы"
  type        = string
}

variable "efs_file_system_id" {
  description = "Файловая система для загрузок"
  type        = string
}

variable "efs_file_system_arn" {
  description = "ARN файловой системы"
  type        = string
}

variable "efs_access_point_id" {
  description = "Access point каталога загрузок"
  type        = string
}

variable "efs_access_point_arn" {
  description = "ARN access point"
  type        = string
}

variable "desired_count" {
  description = "Начальное число задач"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Нижняя граница числа задач"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Верхняя граница числа задач"
  type        = number
  default     = 6
}

variable "cpu_target_percent" {
  description = "Целевая загрузка CPU"
  type        = number
  default     = 60
}

variable "requests_per_target" {
  description = "Целевое число запросов на задачу"
  type        = number
  default     = 600
}

variable "admin_username" {
  description = "Логин администратора WordPress"
  type        = string
  default     = "wpadmin"
}

variable "admin_email" {
  description = "Почта администратора"
  type        = string
  default     = "admin@example.test"
}

variable "secret_recovery_days" {
  description = "Окно восстановления секрета, дней"
  type        = number
  default     = 0
}

variable "log_retention_days" {
  description = "Хранение логов контейнеров, дней"
  type        = number
  default     = 30
}

variable "container_insights" {
  description = "Подробные метрики ECS"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enhanced", "disabled"], var.container_insights)
    error_message = "Допустимо enabled, enhanced или disabled."
  }
}

variable "deletion_protection" {
  description = "Запрет удаления балансировщика"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Ждать устойчивого состояния сервиса"
  type        = bool
  default     = false
}
