output "alb_dns_name" {
  description = "Адрес балансировщика"
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "Суффикс ARN балансировщика для метрик"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Суффикс ARN target group для метрик"
  value       = aws_lb_target_group.this.arn_suffix
}

output "cluster_name" {
  description = "Кластер ECS"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Сервис ECS"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN описания задачи"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Семейство описаний задачи"
  value       = aws_ecs_task_definition.this.family
}

output "log_group_name" {
  description = "Группа логов"
  value       = aws_cloudwatch_log_group.this.name
}

output "admin_secret_arn" {
  description = "Секрет администратора WordPress"
  value       = aws_secretsmanager_secret.wp_admin.arn
}

output "container_name" {
  description = "Имя контейнера"
  value       = local.container_name
}

output "task_subnet_ids" {
  description = "Подсети задач"
  value       = var.private_subnet_ids
}

output "task_security_group_id" {
  description = "Группа задач"
  value       = var.ecs_security_group_id
}

output "site_url" {
  description = "Адрес окружения"
  value       = "https://${var.dns_names[0]}"
}
