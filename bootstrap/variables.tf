variable "project" {
  description = "Префикс проекта"
  type        = string
  default     = "wp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.project))
    error_message = "Строчные латинские буквы, цифры и дефис, длина 2-16 символов"
  }
}

variable "aws_region" {
  description = "Регион AWS"
  type        = string
  default     = "eu-central-1"
}

variable "noncurrent_version_retention_days" {
  description = "Хранение прошлых версий state, дней"
  type        = number
  default     = 30
}
