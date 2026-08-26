data "aws_route53_zone" "main" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.certificate_domain_names[0]
  subject_alternative_names = slice(var.certificate_domain_names, 1, length(var.certificate_domain_names))

  validation_method = "DNS"

  tags = { Name = var.name_prefix }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = var.validation_timeout
  }
}
