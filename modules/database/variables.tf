variable "name_prefix" {
  description = "Префикс имён ресурсов"
  type        = string
}

variable "subnet_ids" {
  description = "Изолированные подсети, минимум две зоны"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Aurora требует подсети минимум в двух зонах доступности."
  }
}

variable "availability_zones" {
  description = "Зоны в порядке подсетей"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Группы безопасности базы"
  type        = list(string)
}

variable "engine_version" {
  description = "Версия Aurora MySQL"
  type        = string
  default     = "8.4.mysql_aurora.8.4.7"
}

variable "database_name" {
  description = "Имя базы"
  type        = string
  default     = "wordpress"
}

variable "master_username" {
  description = "Главный пользователь"
  type        = string
  default     = "wpadmin"

  validation {
    condition     = !contains(["admin", "rdsadmin", "root", "mysql"], lower(var.master_username))
    error_message = "Это имя зарезервировано MySQL или RDS."
  }
}

variable "min_capacity" {
  description = "Минимум ACU; 0 включает авто-паузу"
  type        = number
  default     = 0

  validation {
    condition     = var.min_capacity == 0 || var.min_capacity >= 0.5
    error_message = "Допустим либо 0 (авто-пауза), либо значение от 0.5."
  }
}

variable "max_capacity" {
  description = "Максимум ACU"
  type        = number
  default     = 4
}

variable "seconds_until_auto_pause" {
  description = "Простой до паузы, секунд; только при min_capacity 0"
  type        = number
  default     = 3600

  validation {
    condition     = var.seconds_until_auto_pause >= 300 && var.seconds_until_auto_pause <= 86400
    error_message = "Допустимо от 300 секунд до 86400."
  }
}

variable "instance_count" {
  description = "Число инстансов; для failover нужно два"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 3
    error_message = "Допустимо от 1 до 3 инстансов."
  }
}

variable "backup_retention_days" {
  description = "Хранение бэкапов и глубина PITR, дней"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Допустимо от 1 до 35 дней."
  }
}

variable "deletion_protection" {
  description = "Запрет удаления кластера"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Не делать снимок при удалении"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Применять изменения сразу, а не в окно обслуживания"
  type        = bool
  default     = false
}

variable "slow_query_seconds" {
  description = "Порог медленного запроса, секунд"
  type        = number
  default     = 2
}
