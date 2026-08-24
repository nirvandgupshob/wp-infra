variable "project" {
  description = "Короткий префикс проекта"
  type        = string
  default     = "wp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.project))
    error_message = "Строчные латинские буквы, цифры и дефис, длина 2-16 символов"
  }
}

variable "aws_region" {
  description = "Регион, в котором создаётся бакет со state, Должен совпадать с регионом инфраструктуры"
  type        = string
  default     = "eu-central-1"
}

variable "noncurrent_version_retention_days" {
  description = "Сколько дней хранить предыдущие версии state-файла перед удалением."
  type        = number
  default     = 30
}
