# ---------------------------------------------------------------------------
# Aurora MySQL Serverless v2.
#
# Кластер стоит в изолированных подсетях — тех, у которых нет маршрута
# наружу. Достучаться до него можно только изнутри VPC и только из группы
# безопасности задач ECS.
#
# «Serverless v2» здесь означает не «база по требованию», а плавное
# изменение выделенной мощности (ACU) под нагрузкой, вплоть до нуля
# при простое. Это прямой ответ на требование ТЗ про автомасштабирование:
# масштабируется не только слой приложения, но и база.
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name        = var.name_prefix
  description = "Isolated subnets for the Aurora cluster"
  subnet_ids  = var.subnet_ids

  tags = { Name = var.name_prefix }
}

# Параметры уровня кластера. Заведены отдельной группой, а не взяты
# по умолчанию: группу по умолчанию менять нельзя, а логировать медленные
# запросы нужно — иначе на вопрос «почему сайт тормозит» отвечать нечем.
resource "aws_rds_cluster_parameter_group" "this" {
  name        = var.name_prefix
  family      = "aurora-mysql8.4"
  description = "Cluster parameters for ${var.name_prefix}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = tostring(var.slow_query_seconds)
  }

  # Логи должны писаться в файл, иначе их не получится выгрузить
  # в CloudWatch: вариант TABLE складывает их внутрь самой базы.
  #
  # apply_method указан явно: log_output — статический параметр, AWS
  # принимает его только с pending-reboot. По умолчанию провайдер шлёт
  # immediate, AWS молча заменяет значение на своё, и каждый следующий
  # plan показывает ложную разницу.
  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "pending-reboot"
  }

  # Кандидат на ужесточение: require_secure_transport = ON заставит
  # клиентов подключаться только по TLS. Пока не включено — WordPress
  # для этого нужно передать MYSQLI_CLIENT_SSL и положить в образ
  # корневой сертификат RDS, иначе соединение просто перестанет
  # устанавливаться. Трафик и так не покидает изолированных подсетей.

  tags = { Name = var.name_prefix }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.name_prefix

  engine         = "aurora-mysql"
  engine_version = var.engine_version

  # Aurora Serverless v2 живёт в режиме provisioned: слово serverless
  # здесь относится к классу инстанса (db.serverless), а не к режиму
  # кластера. Режим serverless — это устаревшая v1 с другим поведением.
  engine_mode = "provisioned"

  database_name   = var.database_name
  master_username = var.master_username

  # Пароль генерирует и хранит сам RDS в Secrets Manager, а также сам
  # его ротирует. Ключевое: пароль НИКОГДА не попадает в Terraform state.
  # Альтернатива с random_password положила бы его в state открытым
  # текстом — а state читается как обычный JSON.
  manage_master_user_password = true

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.security_group_ids
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity

    # Имеет смысл только при min_capacity = 0.
    seconds_until_auto_pause = var.seconds_until_auto_pause
  }

  storage_encrypted = true

  # Бэкапы задают глубину восстановления на произвольный момент времени
  # (PITR) — основной механизм отката данных из runbook.
  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:03:30-sun:04:30"
  copy_tags_to_snapshot        = true

  # Ошибки и медленные запросы уезжают в CloudWatch. Без этого они
  # остаются внутри инстанса и пропадают вместе с ним.
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  apply_immediately = var.apply_immediately

  # Отключает платную расширенную поддержку версии после её EOL.
  # Без этого по истечении срока жизни версии AWS начинает брать
  # доплату молча.
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  tags = { Name = var.name_prefix }

  lifecycle {
    ignore_changes = [
      # Имя финального снимка содержит отметку времени и менялось бы
      # при каждом plan, показывая ложную разницу.
      final_snapshot_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id

  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  # Класс, который включает механику Serverless v2.
  instance_class = "db.serverless"

  # Зона задаётся явно, чтобы инстансы гарантированно оказались в разных
  # зонах, а не там, где AWS решит сам. Отказоустойчивость кластера
  # держится именно на этом.
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  # Чем меньше tier, тем раньше инстанс станет writer при failover.
  # Нулевой — основной кандидат.
  promotion_tier = count.index

  db_subnet_group_name = aws_db_subnet_group.this.name

  # Семь дней хранения входят в бесплатный уровень Performance Insights.
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Инстансы Aurora не публикуются наружу; сеть и так изолирована,
  # но лишнее подтверждение в коде не мешает.
  publicly_accessible = false

  apply_immediately = var.apply_immediately

  tags = { Name = "${var.name_prefix}-${count.index}" }
}
