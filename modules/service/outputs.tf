output "alb_dns_name" {
  description = "Load balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "Load balancer ARN suffix for metrics"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix for metrics"
  value       = aws_lb_target_group.this.arn_suffix
}

output "cluster_name" {
  description = "ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.this.family
}

output "log_group_name" {
  description = "Log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "admin_secret_arn" {
  description = "WordPress administrator secret"
  value       = aws_secretsmanager_secret.wp_admin.arn
}

output "container_name" {
  description = "Container name"
  value       = local.container_name
}

output "task_subnet_ids" {
  description = "Task subnets"
  value       = var.private_subnet_ids
}

output "task_security_group_id" {
  description = "Task security group"
  value       = var.ecs_security_group_id
}

output "site_url" {
  description = "Environment URL"
  value       = "https://${var.dns_names[0]}"
}
