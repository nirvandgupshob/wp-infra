resource "random_password" "wp_admin" {
  length = 32

  override_special = "!#%*-_=+?"
}

resource "aws_secretsmanager_secret" "wp_admin" {
  name        = "${var.name_prefix}/wp-admin"
  description = "WordPress administrator credentials for ${var.name_prefix}"

  recovery_window_in_days = var.secret_recovery_days

  tags = { Name = "${var.name_prefix}-wp-admin" }
}

resource "aws_secretsmanager_secret_version" "wp_admin" {
  secret_id = aws_secretsmanager_secret.wp_admin.id

  secret_string = jsonencode({
    username = var.admin_username
    email    = var.admin_email
    password = random_password.wp_admin.result
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
