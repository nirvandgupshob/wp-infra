output "zone_id" {
  description = "Hosted zone id"
  value       = data.aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "Hosted zone name"
  value       = data.aws_route53_zone.main.name
}

output "certificate_arn" {
  description = "Validated certificate ARN"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_domain_names" {
  description = "Certificate domain names"
  value       = concat([aws_acm_certificate.this.domain_name], tolist(aws_acm_certificate.this.subject_alternative_names))
}
