output "file_system_id" {
  description = "Идентификатор файловой системы. Указывается в описании тома задачи ECS."
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "ARN файловой системы. Нужен в политике IAM роли задачи."
  value       = aws_efs_file_system.this.arn
}

output "access_point_id" {
  description = <<-EOT
    Идентификатор access point. Задача ECS должна монтировать том именно
    через него, а не напрямую: только так работает подмена пользователя
    на uid/gid 33 и ограничение корнем каталога загрузок.
  EOT
  value       = aws_efs_access_point.uploads.id
}

output "access_point_arn" {
  description = "ARN access point для политики IAM."
  value       = aws_efs_access_point.uploads.arn
}

output "mount_target_ids" {
  description = "Точки монтирования — по одной на зону доступности."
  value       = aws_efs_mount_target.this[*].id
}
