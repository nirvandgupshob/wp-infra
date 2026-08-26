resource "aws_lb" "this" {
  name               = var.name_prefix
  load_balancer_type = "application"
  internal           = false

  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids

  drop_invalid_header_fields = true

  enable_http2               = true
  idle_timeout               = 60
  enable_deletion_protection = var.deletion_protection

  tags = { Name = var.name_prefix }
}

resource "aws_lb_target_group" "this" {
  name     = var.name_prefix
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  deregistration_delay = 30

  health_check {
    enabled  = true
    path     = "/healthz.php"
    protocol = "HTTP"
    matcher  = "200"

    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = var.name_prefix }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = { Name = "${var.name_prefix}-http" }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy = var.ssl_policy

  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = { Name = "${var.name_prefix}-https" }
}

resource "aws_route53_record" "site" {
  for_each = toset(var.dns_names)

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "A"

  alias {
    name    = aws_lb.this.dns_name
    zone_id = aws_lb.this.zone_id

    evaluate_target_health = true
  }
}
