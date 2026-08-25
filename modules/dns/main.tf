# ---------------------------------------------------------------------------
# DNS и TLS-сертификат окружения.
#
# Модуль ПОДКЛЮЧАЕТСЯ к существующей hosted zone, а не создаёт её.
# Причина: Route53 выдаёт новый набор nameservers при каждом создании зоны,
# а домен куплен у стороннего регистратора и делегирован на текущий набор.
# Пересоздание зоны сломало бы делегирование, и чинить его пришлось бы
# руками в панели регистратора.
#
# Практическое следствие: зона переживает `terraform destroy` окружения,
# то есть окружение можно сносить и поднимать сколько угодно.
#
# A-записи на балансировщик создаёт модуль service — он владеет ALB и знает
# его dns_name и zone_id. Здесь только зона и сертификат.
# ---------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.certificate_domain_names[0]
  subject_alternative_names = slice(var.certificate_domain_names, 1, length(var.certificate_domain_names))

  # DNS-валидация, а не email: подтверждается автоматически и, что важнее,
  # сертификат так же автоматически продлевается — пока валидационная
  # запись остаётся на месте. С email-валидацией продление требует
  # человека, который вовремя откроет письмо.
  validation_method = "DNS"

  tags = { Name = var.name_prefix }

  # Смена списка имён пересоздаёт сертификат. Без этого Terraform попытался бы
  # сначала удалить старый — а он в этот момент ещё используется listener'ом
  # балансировщика, и удаление отвалится.
  lifecycle {
    create_before_destroy = true
  }
}

# Записи, которыми ACM убеждается, что домен принадлежит нам.
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

  # Страховка на случай, если два имени в сертификате дадут одну и ту же
  # валидационную запись (так бывает у пары «apex + wildcard»). Без флага
  # второй ресурс упал бы с конфликтом на уже существующей записи.
  allow_overwrite = true
}

# Отдельный ресурс, который ждёт, пока ACM увидит записи и подтвердит
# сертификат. Ничего не создаёт — существует только чтобы всё, что зависит
# от готового сертификата (listener балансировщика), не начало создаваться
# раньше времени.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = var.validation_timeout
  }
}
