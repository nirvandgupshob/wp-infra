output "writer_endpoint" {
  description = "Адрес записи"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Адрес чтения"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Порт"
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Имя базы"
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "Главный пользователь"
  value       = aws_rds_cluster.this.master_username
}

output "master_user_secret_arn" {
  description = "Секрет с учётными данными"
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}

output "master_user_secret_kms_key_arn" {
  description = "Ключ шифрования секрета"
  value       = aws_rds_cluster.this.master_user_secret[0].kms_key_id
}

output "cluster_identifier" {
  description = "Идентификатор кластера"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_resource_id" {
  description = "Внутренний идентификатор кластера"
  value       = aws_rds_cluster.this.cluster_resource_id
}
