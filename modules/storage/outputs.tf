output "file_system_id" {
  description = "Идентификатор файловой системы"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "ARN файловой системы"
  value       = aws_efs_file_system.this.arn
}

output "access_point_id" {
  description = "Идентификатор access point"
  value       = aws_efs_access_point.uploads.id
}

output "access_point_arn" {
  description = "ARN access point"
  value       = aws_efs_access_point.uploads.arn
}

output "mount_target_ids" {
  description = "Точки монтирования"
  value       = aws_efs_mount_target.this[*].id
}
