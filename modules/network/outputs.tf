output "vpc_id" {
  description = "Идентификатор VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Диапазон адресов VPC"
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Зоны в порядке подсетей"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Подсети балансировщика"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Подсети задач"
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "Подсети базы и EFS"
  value       = aws_subnet.isolated[*].id
}

output "alb_security_group_id" {
  description = "Группа балансировщика"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Группа задач"
  value       = aws_security_group.ecs.id
}

output "db_security_group_id" {
  description = "Группа базы"
  value       = aws_security_group.db.id
}

output "efs_security_group_id" {
  description = "Группа EFS"
  value       = aws_security_group.efs.id
}

output "nat_public_ips" {
  description = "Внешние адреса NAT"
  value       = aws_eip.nat[*].public_ip
}

output "flow_logs_log_group" {
  description = "Группа логов VPC"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
