locals {
  wp_salt_keys = [
    "AUTH_KEY",
    "SECURE_AUTH_KEY",
    "LOGGED_IN_KEY",
    "NONCE_KEY",
    "AUTH_SALT",
    "SECURE_AUTH_SALT",
    "LOGGED_IN_SALT",
    "NONCE_SALT",
  ]
}

ephemeral "random_password" "wp_salts" {
  for_each = toset(local.wp_salt_keys)

  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "wp_salts" {
  name        = "${var.name_prefix}/wp-salts"
  description = "WordPress authentication salts for ${var.name_prefix}"

  recovery_window_in_days = var.secret_recovery_days

  tags = { Name = "${var.name_prefix}-wp-salts" }
}

resource "aws_secretsmanager_secret_version" "wp_salts" {
  secret_id = aws_secretsmanager_secret.wp_salts.id

  secret_string_wo = jsonencode({
    for key in local.wp_salt_keys : key => ephemeral.random_password.wp_salts[key].result
  })

  secret_string_wo_version = var.salts_version
}
