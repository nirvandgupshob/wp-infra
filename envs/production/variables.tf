variable "project" {
  description = "Префикс проекта"
  type        = string
  default     = "wp"
}

variable "environment" {
  description = "Имя окружения"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "Регион AWS"
  type        = string
  default     = "eu-central-1"
}

variable "zone_name" {
  description = "Hosted zone в Route53"
  type        = string
  default     = "wp-demo-bogdan.click"
}

variable "vpc_cidr" {
  description = "Диапазон адресов VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Число зон доступности"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "NAT в каждой зоне вместо одного"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Хранение flow logs, дней"
  type        = number
  default     = 30
}

variable "container_image" {
  description = "Начальный образ задачи; дальше им управляет пайплайн приложения"
  type        = string
  default     = "756250138234.dkr.ecr.eu-central-1.amazonaws.com/wp/wordpress:theme-132243"
}

variable "app_version" {
  description = "Версия приложения"
  type        = string
  default     = "theme-132243"
}

variable "service_desired_count" {
  description = "Начальное число задач"
  type        = number
  default     = 2
}

variable "service_min_capacity" {
  description = "Нижняя граница числа задач"
  type        = number
  default     = 2
}

variable "service_max_capacity" {
  description = "Верхняя граница числа задач"
  type        = number
  default     = 6
}

variable "log_retention_days" {
  description = "Хранение логов, дней"
  type        = number
  default     = 90
}

variable "container_insights" {
  description = "Подробные метрики ECS"
  type        = string
  default     = "enabled"
}

variable "deletion_protection" {
  description = "Запрет удаления; блокирует terraform destroy"
  type        = bool
  default     = true
}

variable "db_instance_count" {
  description = "Число инстансов базы"
  type        = number
  default     = 2
}

variable "db_min_capacity" {
  description = "Минимум ACU; ненулевой, чтобы не было пробуждения"
  type        = number
  default     = 0.5
}

variable "db_max_capacity" {
  description = "Максимум ACU"
  type        = number
  default     = 8
}

variable "db_backup_retention_days" {
  description = "Хранение бэкапов, дней"
  type        = number
  default     = 30
}

variable "alarm_emails" {
  description = "Адреса для уведомлений; подписку нужно подтвердить письмом"
  type        = list(string)
  default     = []
}
