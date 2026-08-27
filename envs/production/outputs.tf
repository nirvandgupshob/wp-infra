output "site_url" {
  description = "Environment URL"
  value       = module.service.site_url
}

output "vpc_id" {
  description = "VPC id"
  value       = module.network.vpc_id
}

output "nat_public_ips" {
  description = "NAT public addresses"
  value       = module.network.nat_public_ips
}

output "ecs_cluster" {
  description = "ECS cluster"
  value       = module.service.cluster_name
}

output "ecs_service" {
  description = "ECS service"
  value       = module.service.service_name
}

output "log_group" {
  description = "Log group"
  value       = module.service.log_group_name
}

output "db_writer_endpoint" {
  description = "Writer endpoint"
  value       = module.database.writer_endpoint
}

output "db_reader_endpoint" {
  description = "Reader endpoint"
  value       = module.database.reader_endpoint
}

output "admin_secret_arn" {
  description = "WordPress administrator secret"
  value       = module.service.admin_secret_arn
}

output "maintenance_task_args" {
  description = "Arguments for running a one-off task"
  value = {
    cluster         = module.service.cluster_name
    task_definition = module.service.task_definition_family
    container       = module.service.container_name
    subnets         = join(",", module.network.private_subnet_ids)
    security_group  = module.network.ecs_security_group_id
  }
}
