output "vpc_id" {
  description = "Идентификатор VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Диапазон адресов VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Задействованные зоны доступности, в том же порядке, что и подсети."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Подсети с маршрутом в интернет. Сюда ставится ALB."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Подсети с исходящим доступом через NAT. Сюда ставятся задачи ECS."
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "Подсети без маршрута наружу. Сюда ставятся Aurora и точки монтирования EFS."
  value       = aws_subnet.isolated[*].id
}

output "alb_security_group_id" {
  description = "Группа балансировщика."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Группа задач ECS."
  value       = aws_security_group.ecs.id
}

output "db_security_group_id" {
  description = "Группа Aurora."
  value       = aws_security_group.db.id
}

output "efs_security_group_id" {
  description = "Группа точек монтирования EFS."
  value       = aws_security_group.efs.id
}

output "nat_public_ips" {
  description = "Публичные адреса NAT. Это те адреса, с которых окружение выходит наружу — пригодятся, если понадобится внести их в чей-то белый список."
  value       = aws_eip.nat[*].public_ip
}

output "flow_logs_log_group" {
  description = "Группа логов с журналом соединений VPC, если он включён."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
