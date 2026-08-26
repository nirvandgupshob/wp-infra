variable "name_prefix" {
  description = "Префикс имён ресурсов"
  type        = string
}

variable "zone_name" {
  description = "Существующая hosted zone; модуль её не создаёт"
  type        = string
}

variable "certificate_domain_names" {
  description = "Имена в сертификате, первое основное"
  type        = list(string)

  validation {
    condition     = length(var.certificate_domain_names) > 0
    error_message = "Нужно хотя бы одно имя."
  }
}

variable "validation_timeout" {
  description = "Таймаут подтверждения сертификата"
  type        = string
  default     = "10m"
}
