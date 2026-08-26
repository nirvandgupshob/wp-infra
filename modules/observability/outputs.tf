output "sns_topic_arn" {
  description = "Топик уведомлений"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "Ссылка на дашборд"
  value       = "https://${local.region}.console.aws.amazon.com/cloudwatch/home?region=${local.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.this.dashboard_name}"
}

output "composite_alarm_name" {
  description = "Сводный аларм недоступности"
  value       = aws_cloudwatch_composite_alarm.service_down.alarm_name
}

output "health_check_id" {
  description = "Внешняя проверка Route53"
  value       = var.enable_health_check ? aws_route53_health_check.site[0].id : null
}

output "alarm_names" {
  description = "Все алармы окружения"
  value = concat(
    [
      aws_cloudwatch_metric_alarm.no_healthy_hosts.alarm_name,
      aws_cloudwatch_metric_alarm.elb_5xx.alarm_name,
      aws_cloudwatch_metric_alarm.target_5xx.alarm_name,
      aws_cloudwatch_metric_alarm.latency.alarm_name,
      aws_cloudwatch_metric_alarm.running_tasks.alarm_name,
      aws_cloudwatch_metric_alarm.db_cpu.alarm_name,
      aws_cloudwatch_metric_alarm.db_capacity.alarm_name,
      aws_cloudwatch_metric_alarm.php_fatal.alarm_name,
      aws_cloudwatch_composite_alarm.service_down.alarm_name,
    ],
    var.enable_health_check ? [aws_cloudwatch_metric_alarm.site_unreachable[0].alarm_name] : [],
  )
}
