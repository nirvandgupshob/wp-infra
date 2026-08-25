output "zone_id" {
  description = "Идентификатор hosted zone. Нужен модулю service для создания A-записей на балансировщик."
  value       = data.aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "Имя зоны."
  value       = data.aws_route53_zone.main.name
}

output "certificate_arn" {
  description = <<-EOT
    ARN подтверждённого сертификата для listener'а балансировщика.

    Берётся из ресурса validation, а не из самого сертификата: так
    зависимость выражена явно и listener не будет создан раньше, чем ACM
    подтвердит сертификат. Иначе apply падал бы с ошибкой о неготовом
    сертификате примерно в половине случаев.
  EOT
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_domain_names" {
  description = "Имена, покрытые сертификатом."
  value       = concat([aws_acm_certificate.this.domain_name], tolist(aws_acm_certificate.this.subject_alternative_names))
}
