locals {
  container_name = "wordpress"
  uploads_volume = "uploads"

  environment = {
    WORDPRESS_DB_HOST = var.db_host
    WORDPRESS_DB_NAME = var.db_name

    WORDPRESS_DB_SSL = "true"

    WORDPRESS_HOME = "https://${var.dns_names[0]}"

    WORDPRESS_FORCE_SSL_ADMIN = "true"

    WORDPRESS_DISALLOW_FILE_MODS = "true"

    APP_ENVIRONMENT = var.environment
    APP_VERSION     = var.app_version
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = { Name = var.name_prefix }
}

resource "aws_ecs_cluster" "this" {
  name = var.name_prefix

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  tags = { Name = var.name_prefix }
}

resource "aws_ecs_task_definition" "this" {
  family = var.name_prefix

  requires_compatibilities = ["FARGATE"]

  network_mode = "awsvpc"

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"

    cpu_architecture = var.cpu_architecture
  }

  volume {
    name = local.uploads_volume

    efs_volume_configuration {
      file_system_id = var.efs_file_system_id

      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.efs_access_point_id

        iam = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        },
      ]

      environment = [
        for key, value in local.environment : {
          name  = key
          value = tostring(value)
        }
      ]

      secrets = concat([
        {
          name      = "WORDPRESS_DB_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        },
        {
          name      = "WORDPRESS_ADMIN_USER"
          valueFrom = "${aws_secretsmanager_secret.wp_admin.arn}:username::"
        },
        {
          name      = "WORDPRESS_ADMIN_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.wp_admin.arn}:password::"
        },
        {
          name      = "WORDPRESS_ADMIN_EMAIL"
          valueFrom = "${aws_secretsmanager_secret.wp_admin.arn}:email::"
        },
        ],
        [
          for key in local.wp_salt_keys : {
            name      = "WORDPRESS_${key}"
            valueFrom = "${aws_secretsmanager_secret.wp_salts.arn}:${key}::"
          }
      ])

      mountPoints = [
        {
          sourceVolume = local.uploads_volume

          containerPath = "/var/www/html/wp-content/uploads"
          readOnly      = false
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = local.container_name
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -fsS -o /dev/null http://127.0.0.1:${var.container_port}/healthz.php || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    },
  ])

  tags = { Name = var.name_prefix }
}

resource "aws_ecs_service" "this" {
  name            = var.name_prefix
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  launch_type      = "FARGATE"
  platform_version = "LATEST"

  enable_execute_command = true

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  health_check_grace_period_seconds = 120

  availability_zone_rebalancing = "ENABLED"

  wait_for_steady_state = var.wait_for_steady_state

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  depends_on = [aws_lb_listener.https]

  tags = { Name = var.name_prefix }
}
