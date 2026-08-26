output "zone_id" {
  description = "Идентификатор зоны"
  value       = data.aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "Имя зоны"
  value       = data.aws_route53_zone.main.name
}

output "certificate_arn" {
  description = "ARN подтверждённого сертификата"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_domain_names" {
  description = "Имена в сертификате"
  value       = concat([aws_acm_certificate.this.domain_name], tolist(aws_acm_certificate.this.subject_alternative_names))
}
