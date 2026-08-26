variable "name_prefix" {
  description = "Префикс имён ресурсов"
  type        = string
}

variable "subnet_ids" {
  description = "Подсети точек монтирования, по одной на зону"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Нужны подсети минимум в двух зонах, иначе отказ одной зоны отрежет файловую систему."
  }
}

variable "security_group_ids" {
  description = "Группы безопасности EFS"
  type        = list(string)
}

variable "posix_uid" {
  description = "uid владельца файлов; 33 это www-data"
  type        = number
  default     = 33
}

variable "posix_gid" {
  description = "gid владельца файлов"
  type        = number
  default     = 33
}

variable "root_directory" {
  description = "Корень access point, не /"
  type        = string
  default     = "/uploads"

  validation {
    condition     = var.root_directory != "/" && startswith(var.root_directory, "/")
    error_message = "Должен начинаться со слэша и не быть корнем."
  }
}

variable "transition_to_ia" {
  description = "Переезд в дешёвый класс хранения"
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "enable_backup" {
  description = "Ежедневные резервные копии"
  type        = bool
  default     = true
}

variable "enforce_tls" {
  description = "Требовать шифрование канала"
  type        = bool
  default     = true
}
