# ---------------------------------------------------------------------------
# Реестр образов.
#
# Живёт здесь, а не в окружении, намеренно: образ собирается один раз,
# проверяется в staging и ТЕМ ЖЕ ДАЙДЖЕСТОМ уезжает в production.
# Реестр на окружение заставил бы копировать образы между ними, и обещание
# «в продакшен едет ровно то, что проверено» перестало бы выполняться.
#
# Побочная выгода та же, что у зоны Route53: `terraform destroy` окружения
# не трогает собранные образы.
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "wordpress" {
  name = "${var.project}/wordpress"

  # Тег нельзя переставить на другой образ. Это гарантия цепочки поставки:
  # если в staging проверяли sha-abc123, то под этим именем всегда будет
  # ровно тот образ, а не подменённый позже.
  image_tag_mutability = "IMMUTABLE"

  # Базовое сканирование на известные уязвимости при каждой загрузке.
  # Бесплатно.
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.project}-wordpress" }
}

# Без уборки старые образы копятся вечно и тарифицируются по $0.10/ГБ в месяц.
resource "aws_ecr_lifecycle_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name

  policy = jsonencode({
    rules = [
      # ОСТОРОЖНО: у многоархитектурных образов и у сборок с attestation
      # дочерние манифесты не имеют тегов. Слишком агрессивное правило
      # удалит их и сломает тегированный индекс — образ перестанет
      # скачиваться. Поэтому срок с запасом, а сборка ведётся
      # с --provenance=false, чтобы лишних манифестов не появлялось вовсе.
      {
        rulePriority = 1
        description  = "Remove untagged build leftovers after a week"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the last 20 tagged images for rollback"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = { type = "expire" }
      },
    ]
  })
}
