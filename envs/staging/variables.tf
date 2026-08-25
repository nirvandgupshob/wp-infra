variable "project" {
  description = "Префикс проекта. Совпадает с bootstrap."
  type        = string
  default     = "wp"
}

variable "environment" {
  description = "Имя окружения. Участвует в именах ресурсов и тегах."
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "Регион. Должен совпадать с регионом бакета со state."
  type        = string
  default     = "eu-central-1"
}

variable "zone_name" {
  description = "Hosted zone в Route53. Создана вручную и делегирована у регистратора, Terraform её не трогает."
  type        = string
  default     = "wp-demo-bogdan.click"
}

variable "vpc_cidr" {
  description = "Диапазон адресов VPC. У окружений он разный, чтобы сети можно было связать между собой, не переделывая адресацию."
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "Число зон доступности."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "В staging один NAT: экономия важнее устойчивости к отказу зоны."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Срок хранения flow logs VPC."
  type        = number
  default     = 7
}

# --- База данных ------------------------------------------------------------

variable "db_instance_count" {
  description = "Один инстанс: в staging отказоустойчивость кластера не демонстрируется, важнее стоимость."
  type        = number
  default     = 1
}

variable "db_min_capacity" {
  description = "Ноль — база засыпает при простое. Проверено, что версия 8.4 это поддерживает."
  type        = number
  default     = 0
}

variable "db_max_capacity" {
  description = "Потолок мощности. Ограничивает и производительность, и счёт."
  type        = number
  default     = 2
}

variable "db_seconds_until_auto_pause" {
  description = "Час простоя до засыпания. Минимум, который принимает AWS, — 300 секунд."
  type        = number
  default     = 3600
}

variable "db_backup_retention_days" {
  description = "Глубина восстановления на момент времени. В staging минимальная."
  type        = number
  default     = 1
}
