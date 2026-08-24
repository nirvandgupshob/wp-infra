output "state_bucket" {
  description = "Имя бакета со state"
  value       = aws_s3_bucket.tfstate.id
}

output "state_kms_key_arn" {
  description = "ARN ключа шифрования state"
  value       = aws_kms_key.tfstate.arn
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
