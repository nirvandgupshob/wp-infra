output "site_url" {
  description = "Адрес окружения"
  value       = module.service.site_url
}

output "vpc_id" {
  description = "Идентификатор VPC"
  value       = module.network.vpc_id
}

output "nat_public_ips" {
  description = "Внешние адреса NAT"
  value       = module.network.nat_public_ips
}

output "ecs_cluster" {
  description = "Кластер ECS"
  value       = module.service.cluster_name
}

output "ecs_service" {
  description = "Сервис ECS"
  value       = module.service.service_name
}

output "log_group" {
  description = "Группа логов"
  value       = module.service.log_group_name
}

output "db_writer_endpoint" {
  description = "Адрес записи"
  value       = module.database.writer_endpoint
}

output "db_reader_endpoint" {
  description = "Адрес чтения"
  value       = module.database.reader_endpoint
}

output "admin_secret_arn" {
  description = "Секрет администратора WordPress"
  value       = module.service.admin_secret_arn
}

output "maintenance_task_args" {
  description = "Параметры запуска разовой задачи"
  value = {
    cluster         = module.service.cluster_name
    task_definition = module.service.task_definition_family
    container       = module.service.container_name
    subnets         = join(",", module.network.private_subnet_ids)
    security_group  = module.network.ecs_security_group_id
  }
}
