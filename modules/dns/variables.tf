variable "name_prefix" {
  description = "Префикс имён ресурсов, например wp-staging."
  type        = string
}

variable "zone_name" {
  description = <<-EOT
    Имя существующей hosted zone в Route53, например wp-demo-bogdan.click.
    Зона НЕ создаётся модулем: она заведена вручную, и на неё делегирован
    домен у регистратора. Пересоздание зоны выдало бы новый набор
    nameservers и сломало делегирование — см. README репозитория.
  EOT
  type        = string
}

variable "certificate_domain_names" {
  description = <<-EOT
    Имена, которые обслуживает это окружение. Первое становится основным
    именем сертификата, остальные — альтернативными (SAN).

    У каждого окружения свой сертификат на свои имена. Общий wildcard
    на оба окружения не берём: модуль вызывается в каждом окружении
    отдельно, и оба создавали бы одну и ту же валидационную запись
    в Route53, конфликтуя друг с другом.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.certificate_domain_names) > 0
    error_message = "Нужно хотя бы одно имя."
  }
}

variable "validation_timeout" {
  description = <<-EOT
    Сколько ждать подтверждения сертификата. По умолчанию ACM ждёт 45 минут,
    и при неверном делегировании DNS apply просто висит всё это время.
    Десяти минут достаточно с запасом, когда делегирование в порядке,
    а проблему видно почти сразу.
  EOT
  type        = string
  default     = "10m"
}
