output "sns_topic_arn" {
  description = "Alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "Dashboard URL"
  value       = "https://${local.region}.console.aws.amazon.com/cloudwatch/home?region=${local.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.this.dashboard_name}"
}

output "composite_alarm_name" {
  description = "Composite outage alarm"
  value       = aws_cloudwatch_composite_alarm.service_down.alarm_name
}

output "health_check_id" {
  description = "Route53 health check"
  value       = var.enable_health_check ? aws_route53_health_check.site[0].id : null
}

output "alarm_names" {
  description = "All alarms of the environment"
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
