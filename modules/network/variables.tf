variable "name_prefix" {
  description = "Префикс имён ресурсов, например wp-staging. Задаётся окружением."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name_prefix))
    error_message = "Строчные латинские буквы, цифры и дефис, длина 2-31 символ."
  }
}

variable "vpc_cidr" {
  description = "Диапазон адресов VPC. Должен быть /16, чтобы хватило на три яруса подсетей."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "Нужен корректный CIDR не уже /16."
  }
}

variable "az_count" {
  description = "Сколько зон доступности задействовать. Минимум две, иначе отказоустойчивости нет."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Допустимо 2 или 3 зоны."
  }
}

variable "single_nat_gateway" {
  description = <<-EOT
    true — один NAT на всё окружение (дешевле примерно на $38/мес за каждую
    сэкономленную зону, но при отказе его зоны задачи в других зонах теряют
    исходящий доступ; входящий трафик и сайт продолжают работать).
    false — по NAT в каждой зоне, как положено в продакшене.
  EOT
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Журналировать разрешённые и отброшенные соединения VPC в CloudWatch."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Срок хранения flow logs. Без ограничения логи копятся вечно и тарифицируются."
  type        = number
  default     = 7
}

variable "container_port" {
  description = "Порт, который слушает контейнер WordPress. Не 80: контейнер работает без прав root."
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Порт Aurora MySQL."
  type        = number
  default     = 3306
}
