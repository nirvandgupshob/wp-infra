# ---------------------------------------------------------------------------
# Окружение staging.
#
# Файл намеренно тонкий: вся логика в модулях, здесь только сборка из них
# и значения переменных. Production собирается из ТЕХ ЖЕ модулей и отличается
# только числами — в этом смысл разделения, иначе проверка в staging
# ничего не гарантировала бы про production.
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Имя, по которому окружение доступно снаружи.
  site_domain = "${var.environment}.${var.zone_name}"
}

module "dns" {
  source = "../../modules/dns"

  name_prefix              = local.name_prefix
  zone_name                = var.zone_name
  certificate_domain_names = [local.site_domain]
}

module "network" {
  source = "../../modules/network"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  az_count                 = var.az_count
  single_nat_gateway       = var.single_nat_gateway
  flow_logs_retention_days = var.flow_logs_retention_days
}

module "storage" {
  source = "../../modules/storage"

  name_prefix        = local.name_prefix
  subnet_ids         = module.network.isolated_subnet_ids
  security_group_ids = [module.network.efs_security_group_id]

  # 33 — это www-data, от которого работает контейнер WordPress.
  # Совпадение обязательно, иначе загрузка файлов молча ломается.
  posix_uid = 33
  posix_gid = 33

  # В staging резервные копии загрузок не нужны: окружение сносится
  # намеренно, а содержимое воспроизводится сидированием.
  enable_backup = false
}

module "database" {
  source = "../../modules/database"

  name_prefix        = local.name_prefix
  subnet_ids         = module.network.isolated_subnet_ids
  availability_zones = module.network.availability_zones
  security_group_ids = [module.network.db_security_group_id]

  # В staging один инстанс: отказоустойчивость кластера демонстрируется
  # на production, а здесь важнее стоимость.
  instance_count = var.db_instance_count

  # Ноль ACU — база засыпает при простое и перестаёт тарифицироваться.
  # Расплата: первый запрос после паузы ждёт пробуждения около 15 секунд.
  # Для staging это приемлемо, для production — нет.
  min_capacity             = var.db_min_capacity
  max_capacity             = var.db_max_capacity
  seconds_until_auto_pause = var.db_seconds_until_auto_pause

  backup_retention_days = var.db_backup_retention_days

  # staging сносится и поднимается намеренно, поэтому защиты нет
  # и финальный снимок не нужен.
  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true
}
