variable "name_prefix" {
  description = "Префикс имён ресурсов, например wp-staging."
  type        = string
}

variable "subnet_ids" {
  description = <<-EOT
    Подсети для точек монтирования — те же изолированные, где стоит база.
    В каждой зоне доступности EFS допускает ровно одну точку монтирования,
    поэтому подсети должны быть из разных зон.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Нужны подсети минимум в двух зонах, иначе отказ одной зоны отрежет файловую систему."
  }
}

variable "security_group_ids" {
  description = "Группы безопасности точек монтирования. Ожидается та, что пускает 2049 только из группы задач ECS."
  type        = list(string)
}

variable "posix_uid" {
  description = <<-EOT
    Идентификатор пользователя, от имени которого задача работает с файлами.
    33 — это www-data, от которого работает контейнер WordPress.
    При несовпадении WordPress не сможет сохранить ни одной картинки,
    причём молча: ошибка уйдёт в лог, а пользователь увидит просто сбой загрузки.
  EOT
  type        = number
  default     = 33
}

variable "posix_gid" {
  description = "Идентификатор группы. 33 — www-data."
  type        = number
  default     = 33
}

variable "root_directory" {
  description = <<-EOT
    Каталог внутри файловой системы, который access point показывает задаче
    как корень. Не «/» намеренно: для корня EFS не применяет creation_info,
    и каталог остался бы с владельцем root.
  EOT
  type        = string
  default     = "/uploads"

  validation {
    condition     = var.root_directory != "/" && startswith(var.root_directory, "/")
    error_message = "Должен начинаться со слэша и не быть корнем."
  }
}

variable "transition_to_ia" {
  description = "Через сколько неиспользования файл переезжает в дешёвый класс хранения. Старые медиафайлы читаются редко."
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "enable_backup" {
  description = "Ежедневные резервные копии через AWS Backup. Для загрузок пользователей это единственная защита: в отличие от базы, у EFS нет восстановления на момент времени по умолчанию."
  type        = bool
  default     = true
}

variable "enforce_tls" {
  description = "Запретить обращения к файловой системе без шифрования канала."
  type        = bool
  default     = true
}
