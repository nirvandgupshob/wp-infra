locals {
  region = data.aws_region.current.region

  alb    = ["LoadBalancer", var.alb_arn_suffix]
  target = ["TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix]
  ecs    = ["ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
  db     = ["DBClusterIdentifier", var.db_cluster_identifier]

  dashboard_widgets = [
    {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        title  = "Запросы и ошибки"
        region = local.region
        view   = "timeSeries"
        stat   = "Sum"
        period = 60
        metrics = [
          concat(["AWS/ApplicationELB", "RequestCount"], local.alb, [{ label = "запросов" }]),
          concat(["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count"], local.target, [{ label = "2xx" }]),
          concat(["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count"], local.target, [{ label = "4xx" }]),
          concat(["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"], local.target, [{ label = "5xx приложения" }]),
          concat(["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count"], local.alb, [{ label = "5xx балансировщика" }]),
        ]
        yAxis = { left = { min = 0 } }
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        title  = "Время ответа"
        region = local.region
        view   = "timeSeries"
        period = 60
        metrics = [
          concat(["AWS/ApplicationELB", "TargetResponseTime"], local.target, [{ stat = "p50", label = "p50" }]),
          concat(["AWS/ApplicationELB", "TargetResponseTime"], local.target, [{ stat = "p95", label = "p95" }]),
          concat(["AWS/ApplicationELB", "TargetResponseTime"], local.target, [{ stat = "p99", label = "p99" }]),
        ]
        yAxis = { left = { min = 0 } }
      }
    },
    {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        title  = "Задачи"
        region = local.region
        view   = "timeSeries"
        period = 60
        metrics = [
          concat(["ECS/ContainerInsights", "RunningTaskCount"], local.ecs, [{ stat = "Average", label = "работает" }]),
          concat(["ECS/ContainerInsights", "DesiredTaskCount"], local.ecs, [{ stat = "Average", label = "требуется" }]),
          concat(["AWS/ApplicationELB", "HealthyHostCount"], local.target, [{ stat = "Minimum", label = "здоровых" }]),
          concat(["AWS/ApplicationELB", "UnHealthyHostCount"], local.target, [{ stat = "Maximum", label = "нездоровых" }]),
        ]
        yAxis = { left = { min = 0 } }
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = {
        title  = "Ресурсы задач"
        region = local.region
        view   = "timeSeries"
        period = 60
        metrics = [
          concat(["AWS/ECS", "CPUUtilization"], local.ecs, [{ stat = "Average", label = "CPU %" }]),
          concat(["AWS/ECS", "MemoryUtilization"], local.ecs, [{ stat = "Average", label = "память %" }]),
        ]
        yAxis = { left = { min = 0, max = 100 } }
      }
    },
    {
      type   = "metric"
      x      = 0
      y      = 12
      width  = 12
      height = 6
      properties = {
        title  = "Aurora"
        region = local.region
        view   = "timeSeries"
        period = 60
        metrics = [
          concat(["AWS/RDS", "ServerlessDatabaseCapacity"], local.db, [{ stat = "Average", label = "ACU" }]),
          concat(["AWS/RDS", "CPUUtilization"], local.db, [{ stat = "Average", label = "CPU %" }]),
          concat(["AWS/RDS", "DatabaseConnections"], local.db, [{ stat = "Maximum", label = "соединений" }]),
        ]
        yAxis = { left = { min = 0 } }
      }
    },
    {
      type   = "log"
      x      = 12
      y      = 12
      width  = 12
      height = 6
      properties = {
        title  = "Ошибки в логах"
        region = local.region
        query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | filter @message like /(?i)(fatal|error|exception)/ | sort @timestamp desc | limit 50"
        view   = "table"
      }
    },
  ]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name_prefix

  dashboard_body = jsonencode({
    widgets = local.dashboard_widgets
  })
}
