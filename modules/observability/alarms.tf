data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  actions = [aws_sns_topic.alerts.arn]

  alb_dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  target_dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  ecs_dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  db_dimensions = {
    DBClusterIdentifier = var.db_cluster_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "no_healthy_hosts" {
  alarm_name        = "${var.name_prefix}-no-healthy-hosts"
  alarm_description = "No healthy targets behind the load balancer: site is down"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  dimensions  = local.target_dimensions

  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "LessThanThreshold"
  threshold           = var.healthy_hosts_threshold

  treat_missing_data = "breaching"

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-no-healthy-hosts" }
}

resource "aws_cloudwatch_metric_alarm" "elb_5xx" {
  alarm_name        = "${var.name_prefix}-elb-5xx"
  alarm_description = "Load balancer returns 5xx: targets are not responding"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"
  dimensions  = local.alb_dimensions

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.error_5xx_threshold

  treat_missing_data = "notBreaching"

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-elb-5xx" }
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name        = "${var.name_prefix}-target-5xx"
  alarm_description = "Application returns 5xx: failure inside WordPress or the database"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  dimensions  = local.target_dimensions

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.error_5xx_threshold

  treat_missing_data = "notBreaching"

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-target-5xx" }
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name        = "${var.name_prefix}-latency"
  alarm_description = "Degradation: p95 response time above threshold"

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  dimensions  = local.target_dimensions

  extended_statistic  = "p95"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.latency_p95_seconds

  treat_missing_data = "notBreaching"

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-latency" }
}

resource "aws_cloudwatch_metric_alarm" "running_tasks" {
  alarm_name        = "${var.name_prefix}-running-tasks"
  alarm_description = "Fewer running tasks than desired: ECS cannot start them"

  namespace   = "ECS/ContainerInsights"
  metric_name = "RunningTaskCount"
  dimensions  = local.ecs_dimensions

  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "LessThanThreshold"
  threshold           = var.desired_count

  treat_missing_data = "missing"

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-running-tasks" }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name        = "${var.name_prefix}-db-cpu"
  alarm_description = "Database CPU saturated"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  dimensions  = local.db_dimensions

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.db_cpu_threshold

  treat_missing_data = "notBreaching"

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-db-cpu" }
}

resource "aws_cloudwatch_metric_alarm" "db_capacity" {
  alarm_name        = "${var.name_prefix}-db-capacity"
  alarm_description = "Database sustained at ACU ceiling: raise max_capacity"

  namespace   = "AWS/RDS"
  metric_name = "ServerlessDatabaseCapacity"
  dimensions  = local.db_dimensions

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.db_max_capacity * 0.9

  treat_missing_data = "notBreaching"

  alarm_actions = local.actions

  tags = { Name = "${var.name_prefix}-db-capacity" }
}

resource "aws_cloudwatch_log_metric_filter" "php_fatal" {
  name           = "${var.name_prefix}-php-fatal"
  log_group_name = var.log_group_name
  pattern        = "?\"PHP Fatal error\" ?\"Uncaught Error\""

  metric_transformation {
    name          = "PhpFatalErrors"
    namespace     = "WordPress/${var.name_prefix}"
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "php_fatal" {
  alarm_name        = "${var.name_prefix}-php-fatal"
  alarm_description = "PHP fatal errors in container logs"

  namespace   = "WordPress/${var.name_prefix}"
  metric_name = aws_cloudwatch_log_metric_filter.php_fatal.metric_transformation[0].name

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  treat_missing_data = "notBreaching"

  alarm_actions = local.actions

  tags = { Name = "${var.name_prefix}-php-fatal" }
}

resource "aws_cloudwatch_composite_alarm" "service_down" {
  alarm_name        = "${var.name_prefix}-service-down"
  alarm_description = "Composite: site is unavailable or degraded"

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.no_healthy_hosts.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.elb_5xx.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.target_5xx.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.running_tasks.alarm_name})",
  ])

  alarm_actions = local.actions
  ok_actions    = local.actions

  tags = { Name = "${var.name_prefix}-service-down" }
}
