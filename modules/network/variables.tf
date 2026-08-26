variable "name_prefix" {
  description = "Префикс имён ресурсов"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name_prefix))
    error_message = "Строчные латинские буквы, цифры и дефис, длина 2-31 символ."
  }
}

variable "vpc_cidr" {
  description = "Диапазон адресов VPC, не уже /16"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "Нужен корректный CIDR не уже /16."
  }
}

variable "az_count" {
  description = "Число зон доступности"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Допустимо 2 или 3 зоны."
  }
}

variable "single_nat_gateway" {
  description = "Один NAT вместо одного на зону"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Журналировать соединения VPC"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Хранение flow logs, дней"
  type        = number
  default     = 7
}

variable "container_port" {
  description = "Порт контейнера"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Порт базы"
  type        = number
  default     = 3306
}
