output "state_bucket" {
  description = "State bucket"
  value       = aws_s3_bucket.tfstate.id
}

output "state_kms_key_arn" {
  description = "State encryption key"
  value       = aws_kms_key.tfstate.arn
}

output "ecr_repository_url" {
  description = "Image registry URL"
  value       = aws_ecr_repository.wordpress.repository_url
}

output "ecr_repository_arn" {
  description = "Registry ARN"
  value       = aws_ecr_repository.wordpress.arn
}

output "backend_config" {
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.tfstate.id}"
        key          = "<environment>/terraform.tfstate"
        region       = "${var.aws_region}"
        encrypt      = true
        kms_key_id   = "${aws_kms_key.tfstate.arn}"
        use_lockfile = true
      }
    }
  EOT
}

output "github_role_arns" {
  description = "Roles for GitHub Actions"
  value       = { for k, r in aws_iam_role.github : k => r.arn }
}
