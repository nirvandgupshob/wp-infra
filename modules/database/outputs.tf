output "writer_endpoint" {
  description = "Адрес для записи. Сюда подключается WordPress — переменная WORDPRESS_DB_HOST."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = <<-EOT
    Адрес для чтения. При одном инстансе указывает на него же, при двух
    и более балансирует между репликами. WordPress из коробки разделять
    чтение и запись не умеет, так что сейчас не используется — но выход
    оставлен, чтобы не переделывать модуль, если появится плагин.
  EOT
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Порт кластера."
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Имя базы."
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "Имя главного пользователя."
  value       = aws_rds_cluster.this.master_username
}

output "master_user_secret_arn" {
  description = <<-EOT
    ARN секрета в Secrets Manager, куда RDS положил пароль.

    Секрет содержит JSON вида {"username": "...", "password": "..."}.
    В описании задачи ECS отдельное поле достаётся указанием ключа:
    "<arn>:password::" — тогда в контейнер попадёт только пароль,
    а не весь документ.
  EOT
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}

output "cluster_identifier" {
  description = "Идентификатор кластера — нужен для алармов CloudWatch и восстановления из бэкапа."
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_resource_id" {
  description = "Внутренний идентификатор кластера. Используется в политиках IAM для доступа к базе по токену."
  value       = aws_rds_cluster.this.cluster_resource_id
}
