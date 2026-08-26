locals {
  name_prefix = "${var.project}-${var.environment}"

  site_domains = [var.zone_name, "www.${var.zone_name}"]
}

module "dns" {
  source = "../../modules/dns"

  name_prefix = local.name_prefix
  zone_name   = var.zone_name

  certificate_domain_names = local.site_domains
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

  posix_uid = 33
  posix_gid = 33

  enable_backup = true
}

module "database" {
  source = "../../modules/database"

  name_prefix        = local.name_prefix
  subnet_ids         = module.network.isolated_subnet_ids
  availability_zones = module.network.availability_zones
  security_group_ids = [module.network.db_security_group_id]

  instance_count = var.db_instance_count

  min_capacity = var.db_min_capacity
  max_capacity = var.db_max_capacity

  backup_retention_days = var.db_backup_retention_days

  deletion_protection = var.deletion_protection

  skip_final_snapshot = false

  apply_immediately = false
}

module "service" {
  source = "../../modules/service"

  name_prefix = local.name_prefix
  environment = var.environment

  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  ecs_security_group_id = module.network.ecs_security_group_id

  route53_zone_id = module.dns.zone_id
  dns_names       = local.site_domains
  certificate_arn = module.dns.certificate_arn

  container_image = var.container_image
  app_version     = var.app_version

  db_host               = module.database.writer_endpoint
  db_name               = module.database.database_name
  db_secret_arn         = module.database.master_user_secret_arn
  db_secret_kms_key_arn = module.database.master_user_secret_kms_key_arn

  efs_file_system_id   = module.storage.file_system_id
  efs_file_system_arn  = module.storage.file_system_arn
  efs_access_point_id  = module.storage.access_point_id
  efs_access_point_arn = module.storage.access_point_arn

  desired_count = var.service_desired_count
  min_capacity  = var.service_min_capacity
  max_capacity  = var.service_max_capacity

  log_retention_days = var.log_retention_days
  container_insights = var.container_insights

  deletion_protection = var.deletion_protection

  secret_recovery_days = 7

  admin_email = "admin@${var.zone_name}"
}

module "observability" {
  source = "../../modules/observability"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix  = local.name_prefix
  alarm_emails = var.alarm_emails

  alb_arn_suffix          = module.service.alb_arn_suffix
  target_group_arn_suffix = module.service.target_group_arn_suffix

  ecs_cluster_name = module.service.cluster_name
  ecs_service_name = module.service.service_name
  log_group_name   = module.service.log_group_name

  db_cluster_identifier = module.database.cluster_identifier
  db_max_capacity       = var.db_max_capacity

  site_domain   = local.site_domains[0]
  desired_count = var.service_min_capacity
}
