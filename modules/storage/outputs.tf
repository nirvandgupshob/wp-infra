output "file_system_id" {
  description = "File system id"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "File system ARN"
  value       = aws_efs_file_system.this.arn
}

output "access_point_id" {
  description = "Access point id"
  value       = aws_efs_access_point.uploads.id
}

output "access_point_arn" {
  description = "ARN access point"
  value       = aws_efs_access_point.uploads.arn
}

output "mount_target_ids" {
  description = "Mount targets"
  value       = aws_efs_mount_target.this[*].id
}
