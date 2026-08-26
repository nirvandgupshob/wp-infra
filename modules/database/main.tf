resource "aws_db_subnet_group" "this" {
  name        = var.name_prefix
  description = "Isolated subnets for the Aurora cluster"
  subnet_ids  = var.subnet_ids

  tags = { Name = var.name_prefix }
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = var.name_prefix
  family      = "aurora-mysql8.4"
  description = "Cluster parameters for ${var.name_prefix}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = tostring(var.slow_query_seconds)
  }

  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "pending-reboot"
  }

  tags = { Name = var.name_prefix }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.name_prefix

  engine         = "aurora-mysql"
  engine_version = var.engine_version

  engine_mode = "provisioned"

  database_name   = var.database_name
  master_username = var.master_username

  manage_master_user_password = true

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.security_group_ids
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity

    seconds_until_auto_pause = var.min_capacity == 0 ? var.seconds_until_auto_pause : null
  }

  storage_encrypted = true

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:03:30-sun:04:30"
  copy_tags_to_snapshot        = true

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  apply_immediately = var.apply_immediately

  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  tags = { Name = var.name_prefix }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id

  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  instance_class = "db.serverless"

  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  promotion_tier = count.index

  db_subnet_group_name = aws_db_subnet_group.this.name

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  publicly_accessible = false

  apply_immediately = var.apply_immediately

  tags = { Name = "${var.name_prefix}-${count.index}" }
}
