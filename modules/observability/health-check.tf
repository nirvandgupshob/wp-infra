resource "aws_route53_health_check" "site" {
  count = var.enable_health_check ? 1 : 0

  type              = "HTTPS"
  fqdn              = var.site_domain
  port              = 443
  resource_path     = "/healthz.php"
  request_interval  = 30
  failure_threshold = 3
  measure_latency   = true

  tags = { Name = "${var.name_prefix}-external" }
}

resource "aws_sns_topic" "alerts_us_east_1" {
  count = var.enable_health_check ? 1 : 0

  provider = aws.us_east_1
  name     = "${var.name_prefix}-alerts"

  tags = { Name = "${var.name_prefix}-alerts" }
}

data "aws_iam_policy_document" "alerts_us_east_1" {
  count = var.enable_health_check ? 1 : 0

  statement {
    sid    = "AllowCloudWatchAlarms"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts_us_east_1[0].arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts_us_east_1" {
  count = var.enable_health_check ? 1 : 0

  provider = aws.us_east_1
  arn      = aws_sns_topic.alerts_us_east_1[0].arn
  policy   = data.aws_iam_policy_document.alerts_us_east_1[0].json
}

resource "aws_sns_topic_subscription" "email_us_east_1" {
  for_each = var.enable_health_check ? toset(var.alarm_emails) : toset([])

  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alerts_us_east_1[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "site_unreachable" {
  count = var.enable_health_check ? 1 : 0

  provider = aws.us_east_1

  alarm_name        = "${var.name_prefix}-site-unreachable"
  alarm_description = "External checks from multiple regions cannot reach the site"

  namespace   = "AWS/Route53"
  metric_name = "HealthCheckStatus"

  dimensions = {
    HealthCheckId = aws_route53_health_check.site[0].id
  }

  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1

  treat_missing_data = "breaching"

  alarm_actions = [aws_sns_topic.alerts_us_east_1[0].arn]
  ok_actions    = [aws_sns_topic.alerts_us_east_1[0].arn]

  tags = { Name = "${var.name_prefix}-site-unreachable" }
}
