# ---------------------------------------------------------------------------
# EFS — общее хранилище для пользовательских загрузок WordPress.
#
# Зачем вообще: WordPress пишет загруженные картинки на диск, а задач ECS
# несколько и они эфемерны. Без общего хранилища картинка, загруженная
# через задачу №1, не откроется у пользователя, попавшего на задачу №2,
# и исчезнет совсем при следующем деплое.
#
# Монтируется ТОЛЬКО в wp-content/uploads. Код приложения приходит
# из образа и перезаписываться не должен — иначе неизменяемость образа
# теряет смысл.
# ---------------------------------------------------------------------------

resource "aws_efs_file_system" "this" {
  creation_token = var.name_prefix

  encrypted = true

  # Низкая задержка важнее максимальной пропускной способности: WordPress
  # обращается к файлам мелкими операциями на каждый запрос.
  performance_mode = "generalPurpose"

  # Elastic, а не bursting. У bursting пропускная способность привязана
  # к объёму данных, и почти пустая файловая система получила бы очень
  # низкий порог — сайт начал бы упираться в него на ровном месте.
  # Elastic тарифицируется по факту обращений и такого порога не имеет.
  throughput_mode = "elastic"

  # Редко читаемые файлы уезжают в дешёвый класс хранения, при обращении
  # возвращаются обратно. Для медиатеки, где смотрят в основном свежее,
  # это заметная экономия.
  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = { Name = var.name_prefix }
}

# Ежедневные копии. Для загрузок это единственная защита от потери:
# у EFS, в отличие от Aurora, нет восстановления на момент времени
# по умолчанию.
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

# Точка монтирования — сетевой интерфейс в подсети. В каждой зоне
# доступности допускается ровно одна.
resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}

# Access point подменяет задаче корень файловой системы и принудительно
# назначает пользователя. Задача физически не может обратиться за пределы
# своего каталога и не может писать от чужого имени, даже если бы захотела.
resource "aws_efs_access_point" "uploads" {
  file_system_id = aws_efs_file_system.this.id

  # Любая операция выполняется от этого пользователя, что бы ни говорил
  # процесс внутри контейнера.
  posix_user {
    uid = var.posix_uid
    gid = var.posix_gid
  }

  root_directory {
    path = var.root_directory

    # Если каталога ещё нет, EFS создаст его с этими правами. Без блока
    # каталог появился бы с владельцем root, и WordPress не смог бы
    # в него писать — ровно та же проблема, что уже проявилась локально
    # с томом Docker.
    creation_info {
      owner_uid   = var.posix_uid
      owner_gid   = var.posix_gid
      permissions = "0755"
    }
  }

  tags = { Name = "${var.name_prefix}-uploads" }
}

# --- Политика доступа -------------------------------------------------------
# ВНИМАНИЕ: у EFS без политики доступ разрешён всем, кто дотянулся по сети.
# Как только политика появляется, поведение переворачивается: запрещено всё,
# кроме явно разрешённого. Поэтому политика из одного Deny заблокировала бы
# монтирование полностью — нужна пара «разрешить монтирование + запретить
# без TLS».
data "aws_iam_policy_document" "this" {
  count = var.enforce_tls ? 1 : 0

  statement {
    sid    = "AllowMountThroughMountTargets"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    # Указывается явно, хотя политика и так относится к одной файловой
    # системе: AWS дописывает это поле сам при сохранении, и без него
    # каждый plan показывал бы несуществующую разницу.
    resources = [aws_efs_file_system.this.arn]

    # Обращение возможно только через точку монтирования внутри VPC,
    # то есть снаружи — никак.
    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }

  statement {
    sid    = "DenyUnencryptedTransport"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["*"]
    resources = [aws_efs_file_system.this.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  count = var.enforce_tls ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.this[0].json

  # Не даёт применить политику, которая отрезала бы доступ самому Terraform.
  bypass_policy_lockout_safety_check = false
}
