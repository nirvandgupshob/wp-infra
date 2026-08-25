output "vpc_id" {
  description = "Идентификатор VPC окружения."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Подсети для задач ECS."
  value       = module.network.private_subnet_ids
}

output "isolated_subnet_ids" {
  description = "Подсети для Aurora и EFS."
  value       = module.network.isolated_subnet_ids
}

output "nat_public_ips" {
  description = "Адреса, с которых окружение выходит наружу."
  value       = module.network.nat_public_ips
}

output "site_domain" {
  description = "Имя, по которому окружение будет доступно."
  value       = local.site_domain
}

output "certificate_arn" {
  description = "Подтверждённый сертификат для listener'а балансировщика."
  value       = module.dns.certificate_arn
}

output "db_writer_endpoint" {
  description = "Адрес базы для WordPress."
  value       = module.database.writer_endpoint
}

output "db_secret_arn" {
  description = "Секрет с паролем базы. Значение достаётся задачей ECS, в state его нет."
  value       = module.database.master_user_secret_arn
}
