variable "name_prefix" {
  description = "Префикс имён ресурсов, например wp-staging."
  type        = string
}

variable "subnet_ids" {
  description = "Изолированные подсети — те, у которых нет маршрута наружу. База не должна стоять нигде больше."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Aurora требует подсети минимум в двух зонах доступности."
  }
}

variable "availability_zones" {
  description = "Зоны в том же порядке, что и подсети. Используются, чтобы явно развести инстансы по зонам."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Группы безопасности базы. Ожидается та, что пускает 3306 только из группы задач ECS."
  type        = list(string)
}

variable "engine_version" {
  description = <<-EOT
    Версия Aurora MySQL. Проверено, что 8.4 поддерживает минимум в 0 ACU:
    в ответе describe-db-engine-versions поле ServerlessV2FeaturesSupport
    показывает MinCapacity = 0.
  EOT
  type        = string
  default     = "8.4.mysql_aurora.8.4.7"
}

variable "database_name" {
  description = "Имя базы, которую создаст Aurora при первом запуске."
  type        = string
  default     = "wordpress"
}

variable "master_username" {
  description = "Главный пользователь. Имена admin, rdsadmin и root в MySQL зарезервированы и будут отвергнуты."
  type        = string
  default     = "wpadmin"

  validation {
    condition     = !contains(["admin", "rdsadmin", "root", "mysql"], lower(var.master_username))
    error_message = "Это имя зарезервировано MySQL или RDS."
  }
}

variable "min_capacity" {
  description = <<-EOT
    Нижняя граница мощности в ACU. Ноль означает авто-паузу при простое:
    база перестаёт тарифицироваться совсем. Плата за это — первый запрос
    после паузы ждёт пробуждения порядка 15 секунд, поэтому в production
    ставится ненулевое значение.
  EOT
  type        = number
  default     = 0

  validation {
    condition     = var.min_capacity == 0 || var.min_capacity >= 0.5
    error_message = "Допустим либо 0 (авто-пауза), либо значение от 0.5."
  }
}

variable "max_capacity" {
  description = "Верхняя граница мощности в ACU. Ограничивает и производительность, и максимальный счёт."
  type        = number
  default     = 4
}

variable "seconds_until_auto_pause" {
  description = "Сколько секунд простоя до паузы. Работает только при min_capacity = 0."
  type        = number
  default     = 3600

  validation {
    condition     = var.seconds_until_auto_pause >= 300 && var.seconds_until_auto_pause <= 86400
    error_message = "Допустимо от 300 секунд до 86400."
  }
}

variable "instance_count" {
  description = <<-EOT
    Число инстансов в кластере. Один — только writer, отказ его зоны означает
    простой на время восстановления. Два — writer и reader в разных зонах,
    с автоматическим failover. Для production нужно минимум два.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 3
    error_message = "Допустимо от 1 до 3 инстансов."
  }
}

variable "backup_retention_days" {
  description = "Срок хранения автоматических бэкапов. Он же — глубина восстановления на момент времени (PITR)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Допустимо от 1 до 35 дней."
  }
}

variable "deletion_protection" {
  description = "Запрет удаления кластера через API. В production обязателен."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Не делать снимок при удалении. Допустимо только для staging, который сносится намеренно."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Применять изменения сразу, а не в окно обслуживания. В staging удобно, в production ведёт к незапланированным перезапускам."
  type        = bool
  default     = false
}

variable "slow_query_seconds" {
  description = "Порог, с которого запрос считается медленным и попадает в лог."
  type        = number
  default     = 2
}
