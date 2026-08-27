output "writer_endpoint" {
  description = "Writer endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Port"
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.this.master_username
}

output "master_user_secret_arn" {
  description = "Credentials secret"
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}

output "master_user_secret_kms_key_arn" {
  description = "Secret encryption key"
  value       = aws_rds_cluster.this.master_user_secret[0].kms_key_id
}

output "cluster_identifier" {
  description = "Cluster identifier"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_resource_id" {
  description = "Cluster resource id"
  value       = aws_rds_cluster.this.cluster_resource_id
}
