output "vpc_id" {
  description = "VPC id"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Task subnets"
  value       = module.network.private_subnet_ids
}

output "isolated_subnet_ids" {
  description = "Database and EFS subnets"
  value       = module.network.isolated_subnet_ids
}

output "nat_public_ips" {
  description = "NAT public addresses"
  value       = module.network.nat_public_ips
}

output "site_url" {
  description = "Environment URL"
  value       = module.service.site_url
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

output "certificate_arn" {
  description = "Certificate for the listener"
  value       = module.dns.certificate_arn
}

output "db_writer_endpoint" {
  description = "Database endpoint"
  value       = module.database.writer_endpoint
}

output "efs_file_system_id" {
  description = "Uploads file system"
  value       = module.storage.file_system_id
}

output "efs_access_point_id" {
  description = "Uploads access point"
  value       = module.storage.access_point_id
}

output "db_secret_arn" {
  description = "Database password secret"
  value       = module.database.master_user_secret_arn
}
