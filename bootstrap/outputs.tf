output "state_bucket" {
  description = "Бакет со state"
  value       = aws_s3_bucket.tfstate.id
}

output "state_kms_key_arn" {
  description = "Ключ шифрования state"
  value       = aws_kms_key.tfstate.arn
}

output "ecr_repository_url" {
  description = "Адрес реестра образов"
  value       = aws_ecr_repository.wordpress.repository_url
}

output "ecr_repository_arn" {
  description = "ARN реестра"
  value       = aws_ecr_repository.wordpress.arn
}

output "backend_config" {
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.tfstate.id}"
        key          = "<окружение>/terraform.tfstate"
        region       = "${var.aws_region}"
        encrypt      = true
        kms_key_id   = "${aws_kms_key.tfstate.arn}"
        use_lockfile = true
      }
    }
  EOT
}

output "github_role_arns" {
  description = "Роли для GitHub Actions"
  value       = { for k, r in aws_iam_role.github : k => r.arn }
}
